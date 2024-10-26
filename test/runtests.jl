using TestItems
using TestItemRunner
@run_package_tests

@testitem "scales, ticks" begin
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
    
    ax, _ = lines(fig[1,5], xs, xs, axis=(xscale=SymLog(1), yscale=AsinhScale(1), xtickformat=EngTicks(), ytickformat=EngTicks(:symbol)))
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

@testitem "bandstroke" begin
    bandstroke([1,2,3], [1..2, 3..4, 5..6])
    bandstroke([1,2,3], [1..2, 3..4, 5..6], strokecolor=:red, strokewidth=2)
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

@testitem "to_xy_attrs" begin
    attrs = (a=1, b=123, xyz="4")
    @test to_x_attrs(attrs) == (xa=1, xb=123, xxyz="4")
    @test to_y_attrs(attrs) == (ya=1, yb=123, yxyz="4")
    @test to_xy_attrs(attrs) == (xa=1, xb=123, xxyz="4", ya=1, yb=123, yxyz="4")

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
end

@testitem "_" begin
    import Aqua
    Aqua.test_all(MakieExtra; ambiguities=false, undefined_exports=false, piracies=false, persistent_tasks=false)

    import CompatHelperLocal as CHL
    CHL.@check()
end
