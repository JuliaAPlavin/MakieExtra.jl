using TestItems
using TestItemRunner
@run_package_tests

@testitem "scales, ticks" begin
    using PyFormattedStrings

    fig = Figure(size=(1200, 300))
    xs = range(-10, 10, length=1000)

    @test string(SymLog(1)) == "SymLog(1.0)"
    @test string(SymLog(1; vmin=0, vmax=Inf)) == "SymLog(1.0; vmin = 0.0)"
    @test string(SymLog(1; linscale=2)) == "SymLog(1.0; linscale = 2.0)"
    @test string(AsinhScale(1)) == "AsinhScale(1.0)"
    
    series(fig[1,1], [
        (xs, mul .* xs)
        for mul in [1, 3, 10, 100]
    ], axis=(yscale=SymLog(1),))
    
    series(fig[1,2], [
        (xs, mul .* xs)
        for mul in [1, 3, 10, 100]
    ], axis=(yscale=SymLog(1, vmin=0, vmax=10),))
    
    series(fig[1,3], [
        (xs, mul .* xs)
        for mul in [1, 3, 10, 100]
    ], axis=(yscale=SymLog(1, vmin=-10, vmax=0),))
    
    series(fig[1,4], [
        (xs, mul .* xs)
        for mul in [1, 3, 10, 100]
    ], axis=(yscale=AsinhScale(1),))

    vals = [1, 10, 1234, 3e4, 2e10, 1e-10, -1, -1e10]
    @test map(String, Makie.get_ticklabels(EngTicks(), vals)) == ["1", "10", "1×103", "30×103", "20×109", "100×10-12", "-1", "-10×109"]
    @test map(String, Makie.get_ticklabels(EngTicks(:symbol), vals)) == ["1", "10", "1 k", "30 k", "20 G", "100 p", "-1", "-10 G"]
    @test map(String, Makie.get_ticklabels(EngTicks(:symbol, space=false), vals)) == ["1", "10", "1k", "30k", "20G", "100p", "-1", "-10G"]
    @test map(String, Makie.get_ticklabels(EngTicks(suffix="abc"), vals)) == ["1abc", "10abc", "1×103abc", "30×103abc", "20×109abc", "100×10-12abc", "-1abc", "-10×109abc"]
    @test map(String, Makie.get_ticklabels(EngTicks(:symbol, suffix="abc"), vals)) == ["1abc", "10abc", "1 kabc", "30 kabc", "20 Gabc", "100 pabc", "-1abc", "-10 Gabc"]
    
    ax, _ = lines(fig[1,5], xs, xs, axis=(xscale=SymLog(1), yscale=AsinhScale(1), xtickformat=EngTicks(suffix="abc"), ytickformat=EngTicks(:symbol)))
    lines!(ax, [Point(0, 0), Point(1, 1)], color=:black, linestyle=:dash, space=:relative)

    unityval =  1.1111111111111112
    @test SymLog(1)(0) == 0
    @test SymLog(1)(0.5) ≈ unityval/2
    @test SymLog(1)(1) ≈ unityval
    @test SymLog(1)(-1) ≈ -unityval
    @test SymLog(1)(10) ≈ 1 + unityval
    @test SymLog(1)(-10) ≈ -(1 + unityval)
    @test SymLog(1)(100) ≈ 2 + unityval

    @test SymLog(10)(0) == 0
    @test SymLog(10)(0.5) ≈ unityval/2
    @test SymLog(10)(1) ≈ unityval
    @test SymLog(10)(5) ≈ 5*unityval
    @test SymLog(10)(10) ≈ 10*unityval
    @test SymLog(10)(100) ≈ 10 + 10*unityval

    @test SymLog(1, linscale=2)(0) == 0
    @test SymLog(1, linscale=2)(0.5) ≈ unityval
    @test SymLog(1, linscale=2)(1) ≈ 2*unityval
    @test SymLog(1, linscale=2)(10) ≈ 1 + 2*unityval
    @test SymLog(1, linscale=2)(100) ≈ 2 + 2*unityval

    # smoke tests to probee the actual inverse:
    Makie.ReversibleScale(SymLog(1))
    Makie.ReversibleScale(AsinhScale(1))

    bmt = BaseMulTicks([1,2,5])
    @test Makie.get_tickvalues(bmt, identity, 0.25, 100) == [0.5, 1, 2, 5, 10, 20, 50, 100]
    @test Makie.get_tickvalues(bmt, identity, 3, 100) == [5, 10, 20, 50, 100]
    @test Makie.get_tickvalues(bmt, log10, 3, 100) == [5, 10, 20, 50, 100]
    @test Makie.get_tickvalues(bmt, SymLog(1), 0, 100) == [0, 0.5, 1, 2, 5, 10, 20, 50, 100]
    @test Makie.get_tickvalues(bmt, SymLog(1), -10, 100) == [-10, -5, -2, -1, -0.5, 0, 0.5, 1, 2, 5, 10, 20, 50, 100]
    @test Makie.get_tickvalues(bmt, SymLog(1), 3, 100) == [5, 10, 20, 50, 100]
    @test Makie.get_tickvalues(bmt, SymLog(1), 0, 1) == [0, 0.5, 1]
    @test Makie.get_tickvalues(bmt, SymLog(1), 0, 0.2) == [0, 0.1, 0.2]
    @test Makie.get_tickvalues(bmt, SymLog(1), 0, 0.099) ≈ [0, 0.01, 0.02, 0.05]
    @test Makie.get_tickvalues(bmt, SymLog(1), 0.09, 0.11) ≈ [0.1]
    @test Makie.get_tickvalues(bmt, SymLog(1), 9, 11) ≈ [10]
    @test Makie.get_tickvalues(bmt, SymLog(1), 9, 9.5) == []
    @test Makie.get_ticks(bmt, identity, Makie.Automatic(), 0.25, 100) == (
        [0.5, 1, 2, 5, 10, 20, 50, 100],
        ["0.5", "1", "2", "5", "10", "20", "50", "100"]
    )
    @test Makie.get_ticks(bmt, SymLog(1), Makie.Automatic(), -10, 100) == (
        [-10, -5, -2, -1, -0.5, 0, 0.5, 1, 2, 5, 10, 20, 50, 100],
        ["−10", "−5", "−2", "−1", "−0.5", "0", "0.5", "1", "2", "5", "10", "20", "50", "100"]
    )

    @test Makie.get_minor_tickvalues(bmt, identity, nothing, 3, 100) == Makie.get_tickvalues(bmt, identity, 3, 100)
    @test Makie.get_minor_tickvalues(bmt, SymLog(1), nothing, -3, 100) == [-2.0, -1.0, -0.5, -0.2, -0.1, 0.0, 0.1, 0.2, 0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 50.0, 100.0]
    @test Makie.get_minor_tickvalues(bmt, SymLog(1), nothing, 0, 1) == [0, 0.1, 0.2, 0.5, 1.0]
    @test Makie.get_minor_tickvalues(bmt, SymLog(1), nothing, 0, 0.2) == [0, 0.1, 0.2]

    @test Makie.get_ticks(Makie.Automatic(), identity, PercentFormatter(), -0.5, 2) == ([-0.5, 0.0, 0.5, 1.0, 1.5, 2.0], ["-50%", "0%", "50%", "100%", "150%", "200%"])
    @test Makie.get_ticks(Makie.Automatic(), identity, PercentFormatter(digits=3, sign=true), 0.5, 0.51) == ([0.5, 0.505, 0.51], ["+50.000%", "+50.500%", "+51.000%"])

    @test Makie.get_ticks(Makie.Automatic(), identity, Broadcast.BroadcastFunction(ff"{_:.5f}"), 0.5, 0.51) == ([0.5, 0.505, 0.51], ["0.50000", "0.50500", "0.51000"])
end

@testitem "scalebar" begin
    using MakieExtra.Unitful

    X = rand(100, 100)
    
    heatmap(X, axis=(aspect=DataAspect(),), alpha=0.1)
    scalebar!(0.15u"m")
    scalebar!(0.15u"m", position=(0.8, 0.1), color=:black)
    scalebar!((0.15u"m", x -> "a $x b"), position=(0.8, 0.1), color=:black)
    scalebar!((0.15, x -> "a $x b"), color=:black)
    scalebar!((0.15, x -> "a $x b"), color=:black, fontsize=20)
    
    heatmap(0..1e-5, 0..1e-5, X, axis=(aspect=DataAspect(),), alpha=0.1)
    scalebar!(0.15u"m")  # XXX: should test that scalebar! call doesn't change limits
end

@testitem "zoom_lines" begin
    fig = Figure()
    ax1, _ = heatmap(fig[1,1], rand(10, 10))
    ax2, _ = heatmap(fig[1,2], rand(100, 100))
    ax3, _ = heatmap(fig[2,1], rand(100, 100))
    ax4, _ = heatmap(fig[2,2], rand(100, 100))
    axs = [ax1, ax2, ax3, ax4]
    for aa in Iterators.product(axs, axs)
        zoom_lines!(aa...)
    end
end

@testitem "axis-wide function" begin
    lines(sin)
    lines(sin; color=:black)
    scatter!(sin)
    scatter!(current_axis(), sin)
    scatter!(Observable(sin))
    scatter!(Observable(sin); markersize=2)
    band(x -> sin(x)..2sin(x); alpha=0.5)
end

@testitem "contourf fast" begin
    using AxisKeysExtra

    contourf_fast(rand(100, 100))
    contourf_fast(rand(100, 100), levels=[0, 0.3, 1])
    @test current_axis().xlabel[] == ""
    contourf_fast(KeyedArray(rand(100, 100), a=range(0, 1, length=100), b=range(-1, 2, length=100)))
    @test current_axis().xlabel[] == "a"
end

@testitem "ecdfplot" begin
    using Unitful

    ecdfplotfull(rand(10))
    ecdfplotfull(rand(10); rev=true)
    ecdfplotfull(-2..5, rand(10))
    ecdfplotfull(-2..5, rand(10); rev=true)
    ecdfplotfull(-2..5, rand(10); rev=true, color=:red, markersize=10)
    
    ecdfplotfull(rand(10)*u"m"; rev=true, color=:red, markersize=10)
    @test_broken (ecdfplotfull(-1u"m"..2u"m", rand(10)*u"m"); true)
end

@testitem "glow" begin
    textglow((0,1), text="Some of My Text")
    textglow((0,1), text="Some of My Text", glowwidth=10)
    textglow((0,1), text="Some of My Text", glowwidth=10, glowcolor=(:lightgreen, 0.8))

    linesglow([1,2,3], [4,5,6])
    linesglow([4,5,6])
    linesglow([(1,2),(3,4)])
    linesglow(0..6, x->sin(x^2), glowwidth=15)
    linesglow(0..6, x->-sin(x^2), glowwidth=70, glowcolor=(:green, 0.4))
    linesglow(0..6, x->-sin(x^2), glowwidth=70, glowalpha=0.5)
    linesglow!(current_axis(), x->sin(x^2), glowwidth=70, glowalpha=0.5)

    linesglow(FPlot(1:5, identity, identity), glowwidth=15)
end

@testitem "text with box" begin
    using MakieExtra.IntervalSets

    textwithbox((0, 0), "Some of My Text")
    textwithbox!((0, 0), "Some of My Text", poly=(;padding=3))
    textwithbox!((0, 0), "Some of My Text", poly=(;padding=Rect(0±3, 0±3)))
    textwithbox!((0, 0), "Some of My Text", space=:relative, poly=(;color=:red))
    textwithbox!((0, 0), "Some of My Text", space=:pixel, poly=(;padding=Rect(0±3, 0±3), color=:red))
end

@testitem "bandstroke" begin
    using MakieExtra.IntervalSets

    bandstroke([1,2,3], [1..2, 3..4, 5..6])
    bandstroke([1,2,3], [1..2, 3..4, 5..6], strokecolor=:red, strokewidth=2)
    bandstroke(0..5, x -> x±1, strokewidth=2)
    bandstroke(FPlot(1:5, identity, x->x..x+1), strokecolor=:red, strokewidth=2)
    bandstroke(FPlot(1:5, identity, x->x..x+1, strokecolor=Ref(:red)), strokewidth=2)
end

@testitem "markers" begin
    scatter(rand(30), rand(30), marker=marker_lw(:vline, 0.5), markersize=30)
    scatter(rand(30), rand(30), marker=marker_lw(:hline, 0.5), markersize=30)
    scatter(rand(30), rand(30), marker=marker_lw(:cross, 0.5), markersize=30)

    @test marker_lw(:vline, 0.5) === marker_lw(:vline, 0.501)
    @test marker_lw(:vline, 0.5) != marker_lw(:vline, 0.53)
end

@testitem "offset_texts" begin
    scatter([1], [1])
    texts = [text!((0,0), text="Abc"), text!((0,0), text="Def")]
    offset_texts_auto_1d!(texts; direction=:x)
    offset_texts_auto_1d!(texts; direction=:y)
    offset_texts_auto_1d!(texts; direction=:y, height_frac_mindist=0.5, height_frac_for_line=0.1, Lines=(;linewidth=4))
    texts = [textwithbox!((0,0), text="Abc"), textwithbox!((0,0), text="Def")]
    offset_texts_auto_1d!(texts; direction=:x)
    texts = [textglow!((0,0), text="Abc"), textglow!((0,0), text="Def")]
    offset_texts_auto_1d!(texts; direction=:x)
end

@testitem "kwargs merging" begin
    using MakieExtra: merge_plot_kwargs, merge_axis_kwargs, merge_limits

    @test merge_plot_kwargs(nothing, nothing) == nothing
    @test merge_plot_kwargs(nothing, (;a=1)) == (;a=1)
    @test merge_plot_kwargs((;a=1, b=2), (;a=3, c=4)) == (;a=3, b=2, c=4)
    @test merge_plot_kwargs((;a=1, b=2, axis=(;c=3, d=4)), (;a=5, e=6)) == (;a=5, b=2, axis=(;c=3, d=4), e=6)
    @test merge_plot_kwargs((;a=1, b=2), (;a=3, c=4, axis=(;d=5, e=6))) == (;a=3, b=2, c=4, axis=(;d=5, e=6))
    @test merge_plot_kwargs((;a=1, b=2, axis=(;c=3, d=4)), (;a=5, e=6, axis=(;c=7, f=8))) == (;a=5, b=2, axis=(;c=7, d=4, f=8), e=6)

    @test merge_axis_kwargs(nothing, nothing) == nothing
    @test merge_axis_kwargs(nothing, (;a=1)) == (;a=1)
    @test merge_axis_kwargs((;a=1, b=2), (;a=3, c=4)) == (;a=3, b=2, c=4)
    @test merge_axis_kwargs((;a=1, b=2, limits=(3, 4)), (;a=5, c=6)) == (;a=5, b=2, limits=(3, 4), c=6)
    @test merge_axis_kwargs((;a=1, b=2), (;a=5, c=6, limits=(3, nothing))) == (;a=5, b=2, c=6, limits=(3, nothing))
    @test merge_axis_kwargs((;a=1, b=2, limits=((4,nothing), nothing)), (;a=5, c=6, limits=((5,6), nothing))) == (;a=5, b=2, limits=((5,6), nothing), c=6)

    @test merge_limits(nothing, nothing) == nothing
    @test merge_limits(nothing, (1..2, nothing)) == ((1,2), nothing)
    @test merge_limits((1..2, nothing), (3..4, 5..6)) == ((3,4), (5,6))
    @test merge_limits((1,2,nothing,4), (nothing,4,nothing,nothing)) == ((1,4), (nothing,4))
    @test merge_limits((1,2,nothing,4), (nothing,4,5,nothing)) == ((1,4), (5,4))
end

@testitem "to_xy_attrs" begin
    attrs = (a=1, b=123, xyz="4", limit=5, size=6)
    @test to_x_attrs(attrs) == (xa=1, xb=123, xxyz="4", limits=(5, nothing), width=6)
    @test to_y_attrs(attrs) == (ya=1, yb=123, yxyz="4", limits=(nothing, 5), height=6)
    @test to_xy_attrs(attrs) == (xa=1, xb=123, xxyz="4", limits=(5, 5), width=6, ya=1, yb=123, yxyz="4", height=6)
    @test to_x_attrs(a=1) === (xa=1,)
    @test to_y_attrs(a=1) === (ya=1,)
    @test to_xy_attrs(a=1) === (xa=1, ya=1)

    attrs = Attributes(attrs)
    @test NamedTuple(attrs).b[] == 123
    @test_broken (to_x_attrs(attrs); true)
end

@testitem "multiplot" begin
    import CairoMakie

    res = multiplot((Scatter, Lines), 1:10, 1:10, axis=(xlabel="x",))
    @test length(res) == 2
    @test res[1] isa Makie.FigureAxisPlot
    @test res[2] isa Plot
    @test res[1].axis.xlabel[] == "x"
    res = multiplot!((Scatter, Lines), 1:10, 1:10)
    @test length(res) == 2
    @test res[1] isa Plot
    @test res[2] isa Plot
    multiplot!(current_axis(), (Scatter, Lines), 1:10, 1:10)

    multiplot((Scatter, Lines), 1:10, 1:10, color=:red)
    (ax, _), _ = multiplot(current_figure()[1,2], (Scatter, Lines), 1:10, 1:10, markersize=5, axis=(;xlabel="x"))
    @test ax.xlabel[] == "x"
    multiplot((Scatter, Lines), 1:10, 1:10, markersize=5, linewidth=2)
    plts = multiplot!((Scatter, Lines), 1:10, 1:10, markersize=5, linewidth=2, color=:red)
    @test plts[1].markersize[] == 5
    @test plts[1].color[] == :red
    @test plts[2].linewidth[] == 2
    @test plts[2].color[] == :red

    multiplot((scatter, lines), 1:10, 1:10)
    multiplot!((scatter, lines), 1:10, 1:10)
    plts = multiplot!((scatter, lines), 1:10, 1:10, color=:red, markersize=5, linewidth=2)
    @test plts[1].markersize[] == 5
    @test plts[1].color[] == :red
    @test plts[2].linewidth[] == 2
    @test plts[2].color[] == :red

    multiplot((Scatter, Lines), current_figure()[1:2,3], 1:10, 1:10)
    Makie.colorbuffer(current_figure(); backend=CairoMakie)

    plts = multiplot!(
        (Scatter => (;color=:red), Lines => (;color=:blue), Scatter),
        1:10, 1:10, color=:black, markersize=5, linewidth=2)
    @test length(plts) == 3
    @test plts[1].markersize[] == plts[3].markersize[] == 5
    @test plts[1].color[] == :red
    @test plts[2].linewidth[] == 2
    @test plts[2].color[] == :blue
    @test plts[3].color[] == :black

    Makie.colorbuffer(current_figure(); backend=CairoMakie)
end

@testitem "arrowline" begin
    using MakieExtra: split_arrowstyle

    @test split_arrowstyle("<-|>") == (lmk = "<", rmk = "|>", linek = "-")
    @test split_arrowstyle("<|-->") == (lmk = "<|", rmk = ">", linek = "--")
    @test split_arrowstyle("->") == (lmk = "", rmk = ">", linek = "-")
    @test split_arrowstyle("-|>") == (lmk = "", rmk = "|>", linek = "-")
    @test split_arrowstyle("<->") == (lmk = "<", rmk = ">", linek = "-")
    @test split_arrowstyle("<-") == (lmk = "<", rmk = "", linek = "-")

    arrowlines([(0, 0), (1, 0.5)])
    arrowlines!([(0, 0), (1, 0.5)], markersize=50)
    arrowlines!([(0, 0), (1, 0.5)], arrowstyle="<-|>")
    arrowlines!([(0, 0), (10, -2), (1, 0.5)], arrowstyle="<-|>")
    arrowlines!(1:10, sin)
    arrowlines(1:10, sin; axis=(;xscale=log10))
end

@testitem "@define_plotfunc" begin
    struct MyType end
    struct MyTypeVec <: AbstractVector{Float64} end

    MakieExtra.@define_plotfunc scatter MyType
    MakieExtra.default_axis_attributes(::Type{Scatter}, ::MyType) = (;limits=((1, 2), (3, 4)))
    Makie.convert_arguments(::Type{Scatter}, ::MyType) = ([1, 2, 3], [1, 2, 3])

    MakieExtra.@define_plotfunc scatter MyTypeVec
    MakieExtra.default_axis_attributes(::Type{Scatter}, ::MyTypeVec) = (;limits=((1, 2), (3, 4)))
    Makie.expand_dimensions(::PointBased, ::MyTypeVec) = ([1, 2, 3], [1, 2, 3])

    MakieExtra.@define_plotfunc image MyType
    MakieExtra.default_axis_attributes(::Type{Image}, ::MyType) = (;limits=((1, 2), (3, 4)))
    Makie.convert_arguments(CT::Type{Image}, ::MyType) = ([1 2; 3 4],)

    MakieExtra.@define_plotfunc image MyTypeVec
    MakieExtra.default_axis_attributes(::Type{Image}, ::MyTypeVec) = (;limits=((1, 2), (3, 4)))
    Makie.convert_arguments(CT::Type{Image}, ::MyTypeVec) = ([1 2; 3 4],)

    @testset for plotf in (scatter, image),
                 T in (MyType, MyTypeVec)
        fig, ax, plt = plotf(T())
        @test ax.limits[] === ((1, 2), (3, 4))
        fig, ax, plt = plotf(Observable(T()))
        @test ax.limits[] === ((1, 2), (3, 4))
    end
end

@testitem "@define_plotfunc_conv" begin
    struct MyType end
    struct MyTypeVec <: AbstractVector{Float64} end

    MakieExtra.@define_plotfunc_conv scatter MyType
    MakieExtra.default_axis_attributes(::Type{Scatter}, ::MyType) = (;limits=((1, 2), (3, 4)))
    MakieExtra._convert_arguments_singlestep(::Type{Scatter}, ::MyType) = ([1, 2, 3],)

    MakieExtra.@define_plotfunc_conv scatter MyTypeVec
    MakieExtra.default_axis_attributes(::Type{Scatter}, ::MyTypeVec) = (;limits=((1, 2), (3, 4)))
    MakieExtra._convert_arguments_singlestep(::Type{Scatter}, ::MyTypeVec) = ([1, 2, 3],)

    MakieExtra.@define_plotfunc_conv image MyType
    MakieExtra.default_axis_attributes(::Type{Image}, ::MyType) = (;limits=((1, 2), (3, 4)))
    MakieExtra._convert_arguments_singlestep(::Type{Image}, ::MyType) = ([1 2; 3 4],)

    MakieExtra.@define_plotfunc_conv image MyTypeVec
    MakieExtra.default_axis_attributes(::Type{Image}, ::MyTypeVec) = (;limits=((1, 2), (3, 4)))
    MakieExtra._convert_arguments_singlestep(::Type{Image}, ::MyTypeVec) = ([1 2; 3 4],)

    @testset for plotf in (scatter, image),
                 T in (MyType, MyTypeVec)
        fig, ax, plt = plotf(T())
        @test ax.limits[] === ((1, 2), (3, 4))
        fig, ax, plt = plotf(Observable(T()))
        @test ax.limits[] === ((1, 2), (3, 4))
    end
    @testset for plotf in (scatter!, image!),
                 T in (MyType, MyTypeVec)
        plt = plotf(T())
        plt = plotf(Observable(T()))
    end
end

@testitem "lift" begin
    using MakieExtra.PyFormattedStrings

    # https://github.com/MakieOrg/Makie.jl/pull/3915
    u_noobs = "a"
    x = Observable(1.0)
    y = Observable(2.0)
    z = (x = x, y = y)

    noobs = @lift u_noobs * "b"
    @test noobs == "ab"

    noobs = @lift $u_noobs * "b"
    @test noobs == "ab"

    xx = @lift $x
    @test xx[] == 1.0

    t1 = @lift($x + $y)
    @test t1[] == 3.0
    t2 = @lift($(z.x) - $(z.y))
    @test t2[] == -1.0

    f = Observable(sin)

    t3 = @lift($f($x))
    @test t3[] == sin(x[])
    t4 = @lift($f($f($(z.x))))
    @test t4[] == sin(sin(z.x[]))

    arrobs = Observable([1, 2, 3])
    t5 = @lift($arrobs[2])
    @test t5[] == 2

    observables = [Observable(1.0), Observable(2.0)]
    t6 = @lift($(observables[1]) + $(observables[2]))
    @test t6[] == 3.0

    t7 = @lift f"abc {$x:0.2f} def"
    @test t7[] == "abc 1.00 def"
end

@testitem "liftT" begin
    u_noobs = "a"
    x = Observable(1.0)

    t = liftT(identity, Int, x)
    @test t isa Observable{Int}
    @test t[] == 1
    x[] = 2.; @test t[] == 2
    @test_throws InexactError x[] = 2.5

    x = Observable(1.0)
    t = liftT(x -> x > 2 ? nothing : x, Union{Int,Nothing}, x)
    @test t isa Observable{Union{Int,Nothing}}
    @test t[] == 1
    x[] = 3.; @test t[] == nothing

    x = Observable(1.0)
    t = @lift $x > 2 ? "a" : 1
    @test t isa Observable{Int}
    @test t[] == 1
    @test_throws "Cannot `convert" x[] = 3

    x = Observable(1.0)
    t = @lift ($x > 2 ? "a" : 1)::Union{Int,String}
    @test t isa Observable{Union{Int,String}}
    @test t[] == 1
    x[] = 3; @test t[] == "a"
end

@testitem "obs changes" begin
    # https://github.com/JuliaGizmos/Observables.jl/pull/115
    x = Observable(1)
    yupds = []
    y = lift(changes(x)) do x
        push!(yupds, x)
        x
    end
    x[] = 1
    x[] = 2
    x[] = 2
    x[] = 1
    x[] = 1
    @test yupds == [1, 2, 1]

    x = Observable{Any}(1)
    yupds = []
    y = lift(changes(x)) do x
        push!(yupds, x)
    end
    x[] = 1
    x[] = "2"
    x[] = "2"
    x[] = 1
    @test yupds == [1, "2", 1]
end

@testitem "obsmap" begin
    x = Observable(1)
    y = @lift $x + 1
    @test obsmap(x, 1:10, y) == 2:11
    @test obsmap(x, 1:5, @lift (;x=$x, y=$y)) == [(x=1, y=2), (x=2, y=3), (x=3, y=4), (x=4, y=5), (x=5, y=6)]
end

@testitem "record" begin
    import CairoMakie

    t = Observable(1)
    fig, ax, plt = scatter(@lift ($t, $t))
    Record(fig, t, 1:10)
    Record(t, 1:10)
end

@testitem "mouse_position_obs" begin
    using MakieExtra.Makie: StaticVector

    # smoke test only
    @test isequal(mouse_position_obs(current_axis())[]::StaticVector, [NaN, NaN])
    @test isequal(mouse_position_obs(current_axis(); consume=false)[]::StaticVector, [NaN, NaN])
    @test isequal(mouse_position_obs(current_axis(); key=Makie.Mouse.right)[]::StaticVector, [NaN, NaN])
end

@testitem "transform" begin
    using MakieExtra: rel2data, data2rel

    # smoke test only
    fig,ax,plt = scatter(randn(100); axis=(;xscale=log10))

    scatter!(@lift (10, 0) .+ $(rel2data(ax, :y, (0, 0.5))))
    scatter!(@lift (0, 1) .+ $(rel2data(ax, :x, (0.5, 0))))

    scatter!(@lift (10, 0 + $(rel2data(ax, :y, 0.5))))
    scatter!(@lift (0 + $(rel2data(ax, :x, 0.5)), 1))

    scatter!(space=:relative, @lift $(data2rel(ax, :x, (10, 0))) .+ (0, 0.5))
    scatter!(space=:relative, @lift $(data2rel(ax, :y, (0, 1))) .+ (0.5, 0))

    scatter!(space=:relative, @lift ($(data2rel(ax, :x, 10)) + 0, 0.5))
    scatter!(space=:relative, @lift (0.5, $(data2rel(ax, :y, 1)) + 0))
end

@testitem "func2type" begin
    # upstreamed to Makie
    using MakieExtra: func2type
    @test func2type(scatter) == Scatter
    @test func2type(scatter!) == Scatter
    @test func2type(scatterlines) == ScatterLines
    @test func2type(scatterlines!) == ScatterLines
    @test func2type(Lines) == Lines
end

@testitem "inverse" begin
    # upstreamed to Makie
    @test ReversibleScale(identity) === ReversibleScale(identity, identity)
    @test ReversibleScale(cbrt) === ReversibleScale(cbrt, Base.Fix2(^, 3))
end

@testitem "rectangles" begin
    using Accessors
    using MakieExtra: HyperRectangle

    @test intervals(Rect2(Vec(0, 1), Vec(2, 3))) == [0..2, 1..4]
    @test intervals(Rect3(Vec(0, 1, 2), Vec(2, 3, 4))) == [0..2, 1..4, 2..6]
    
    @test HyperRectangle(0..1, 2..5) == Rect2(Vec(0, 2), Vec(1, 3))
    @test Rect(0..1, 2..5) == Rect2(Vec(0, 2), Vec(1, 3))
    @test Rect2(0..1, 2..5) == Rect2(Vec(0, 2), Vec(1, 3))
    @test HyperRectangle(0..1, 2..5, 3..6) == Rect3(Vec(0, 2, 3), Vec(1, 3, 3))
    @test Rect(0..1, 2..5, 3..6) == Rect3(Vec(0, 2, 3), Vec(1, 3, 3))
    @test Rect3(0..1, 2..5, 3..6) == Rect3(Vec(0, 2, 3), Vec(1, 3, 3))

    @test Rect2(Rect3(Vec(0, 1, 2), Vec(2, 3, 4))) == Rect2(Vec(0, 1), Vec(2, 3))

    @test Rect2(Vec(0, 1), Vec(2, 3)) ⊆ Rect2(Vec(0, 1), Vec(2, 3))
    @test Rect2(Vec(0, 1), Vec(2, 3)) ⊆ Rect2(Vec(0, 1), Vec(3, 4))
    @test !(Rect2(Vec(0, 1), Vec(2, 3)) ⊆ Rect2(Vec(0, 1), Vec(1, 4)))

    Accessors.test_getset_laws(first∘intervals, Rect2(Vec(0., 1), Vec(2., 3)), -1.5..5.2, 10..20)
    Accessors.test_insertdelete_laws(first∘intervals, Rect2(Vec(0., 1), Vec(2., 3)), -1.5..5.2)

    @test dilate(Rect2(Vec(0, 1), Vec(2, 3)), Rect2(Vec(-1, -2), Vec(3, 5))) == Rect2(Vec(-1, -1), Vec(5, 8))
    @test erode(Rect2(Vec(0, 1), Vec(3, 5)), Rect2(Vec(-1, -2), Vec(2, 3))) == Rect2(Vec(1, 3), Vec(1, 2))
    @test erode(Rect2(Vec(0, 1), Vec(3, 5)), Rect2(Vec(-1, -2), Vec(20, 30))) == Rect2(Vec(1, 3), Vec(-17, -25))
end

@testitem "polygons" begin
    using Accessors

    p = Makie.Polygon([Point(1,0), Point(0,1), Point(1,1)])
    Accessors.test_getset_laws(Makie.coordinates, p, Point2f[Point(0,0), Point(1,1), Point(0,1), Point(-1, 0.5)], [Point(2,2), Point(3,3), Point(4,4)])
end

@testitem "rich" begin
    @test (@rich "abc") == "abc"
    @test string(@rich "abc $(rich("x", color=:red))") == string(rich("abc ", rich("x", color=:red)))
    @test string("abc " * rich("x", color=:red)) == string(rich("abc ", rich("x", color=:red)))
end

@testitem "radiobuttons" begin
    # smoke test only
    fig = Figure()
    rbs = MakieExtra.radiobuttons(Checkbox(fig[1,1]), Checkbox(fig[1,1], checked=true), Checkbox(fig[1,1]))
    @test rbs.selix[] == 2
    rbs = MakieExtra.radiobuttons(Checkbox(fig[1,1], checked=true) => Button(fig[1,2]), Checkbox(fig[1,1]) => Button(fig[1,2]), Checkbox(fig[1,1]) => Button(fig[1,2]))
    @test rbs.selix[] == 1
end

@testitem "geoaxis" begin
    # smoke test only
    using GeoMakie
    using MakieExtra.IntervalSets
    import CairoMakie

    MakieExtra.GeoAxis_radians!()
    MakieExtra.GeoAxis_splitwrap!()

	fig = Figure()
	ax = GeoAxis(fig[1,1], dest="+proj=moll")

	lines!(map(x->(x/50, x/1000), 1:20:1000))
	poly!([
		Rect(0±0.2, 0.5±0.1),
		Rect(3±0.2, -0.5±0.1),
	])
	poly!(Rect(3±0.2, 0.5±0.1))
	poly!(Circle(Point2(-3.1, 0), 0.1))

    colorbuffer(fig)
end

@testitem "_" begin
    import Aqua
    Aqua.test_all(MakieExtra; ambiguities=(;broken=true), undefined_exports=(;broken=true), piracies=(;broken=true))

    import CompatHelperLocal as CHL
    CHL.@check(checktest=false)
end
