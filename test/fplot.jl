@testitem "fplot structure" begin
    using Accessors

    fp = FPlot(1:10, (@o _+1), (@o _^2), color=sqrt)
    @test values(fp) === 1:10
    @test fp.color === sqrt
    @test fp[1] === @o _+1
    @test fp[2] === @o _^2
    @test fp[:color] === sqrt
    @test (@set values(fp) = [1,2,3]) == FPlot([1,2,3], (@o _+1), (@o _^2), color=sqrt)
    @test (@set fp.color = sin) === FPlot(1:10, (@o _+1), (@o _^2), color=sin)
    @test (@set fp[:color] = sin) === FPlot(1:10, (@o _+1), (@o _^2), color=sin)
    @test (@insert fp.markersize = sin) === FPlot(1:10, (@o _+1), (@o _^2), color=sqrt, markersize=sin)
    @test (@set fp[1] = @o _+2) === FPlot(1:10, (@o _+2), (@o _^2), color=sqrt)
    @test (@delete values(fp)) === FPlot(nothing, (@o _+1), (@o _^2), color=sqrt)
    fp_nov = FPlot(nothing, (@o _+1), (@o _^2), color=sqrt)
    @test (@insert values(fp_nov) = 1:10) === FPlot(1:10, (@o _+1), (@o _^2), color=sqrt)
end

@testitem "basic" begin
    using Accessors

    lines(FPlot(1:10, (@o _+1), (@o _^2), color=sqrt))
    fig, ax, plt = lines(FPlot(1:10, (@o _+1), (@o _^2), color=sqrt), linewidth=10)
    @test ax.xlabel[] == ""
    @test plt.linewidth[] == 10
    plt = lines!(FPlot(1:10, (@o _+1), (@o _^2), color=sqrt))
    plt = lines!(FPlot(1:10, (@o _+1), (@o _^2), color=Ref(:black)))
    plt = lines!(FPlot(1:10, x->x+1, (@o _^2), color=sqrt), linewidth=15)
    @test plt.linewidth[] == 15
    plt = lines!(1:10, FPlot(x->x+1, (@o _^2), color=sqrt), linewidth=15)
    @test ax.xlabel[] == ""
    @test plt.linewidth[] == 15
    plt = lines!(1:10, FPlot(x->x+1, (@o _^2), color=sqrt, markersize=identity), linewidth=15)
end

@testitem "doaxis" begin
    using Accessors
    using CairoMakie

    fig, ax, plt = lines(FPlot(1:10, (@o _+1), (@o _^2), color=sqrt), axis=(ylabel="Abc",))
    lines!(FPlot(1:10, (@o _+1), (@o _^2), color=sqrt))
    @test content(fig[1,1]).xlabel[] == ""
    @test content(fig[1,1]).ylabel[] == "Abc"
    Makie.colorbuffer(current_figure(); backend=CairoMakie)

    fig, ax, plt = lines(FPlot(1:10, (@o _+1), (@o _^2), color=sqrt), doaxis=true, _axis=(ylabel="Abc",))
    lines!(FPlot(1:10, (@o _/1), (@o _+2), color=sqrt), doaxis=true)
    @test content(fig[1,1]).xlabel[] == "_ + 1"
    @test content(fig[1,1]).ylabel[] == "Abc"
    Makie.colorbuffer(current_figure(); backend=CairoMakie)

    fig, ax, plt = lines(FPlot(1:10, (@o _+1), (@o _^2), color=sqrt, axis=(ylabel="Abc",)), doaxis=true)
    lines!(FPlot(1:10, (@o _/1), (@o _+2), color=sqrt), doaxis=true)
    @test content(fig[1,1]).xlabel[] == "_ + 1"
    @test content(fig[1,1]).ylabel[] == "Abc"
    Makie.colorbuffer(current_figure(); backend=CairoMakie)
end

@testitem "categorical" begin
    using Accessors

    lines(FPlot(1:10, string, (@o _^2), color=sqrt), doaxis=true)
    @test current_axis().xlabel[] == "string(_)"
end

@testitem "unitful" begin
    using Accessors, Unitful

    lines(FPlot((1:10)u"m", (@o ustrip(u"cm", 2*_)), (@o ustrip(_^2))), doaxis=true)
    @test current_axis().xlabel[] == "2 * _ (cm)"
    @test_broken current_axis().ylabel[] == "^(_, 2) (m^2)"
end

@testitem "modified/reordered args" begin
    using Accessors
    using MakieExtra: xint, yint
    using UncertaintiesNaive

    ## reorder_args = false
    barplot(FPlot(1:10, (@o _), (@o _^2)), doaxis=true, reorder_args=false)
    @test xint(current_axis().targetlimits[]) ≈ 0.1..10  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ -5..105  rtol=0.2
    @test current_axis().xlabel[] == "_"
    @test current_axis().ylabel[] == "_ ^ 2"

    barplot(FPlot(1:10, (@o _), (@o _^2)), direction=:x, doaxis=true, reorder_args=false)
    @test xint(current_axis().targetlimits[]) ≈ -5..105  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ 0.1..10  rtol=0.2
    @test current_axis().xlabel[] == "_ ^ 2"
    @test current_axis().ylabel[] == "_"

    rangebars(FPlot(1:10, (@o _), (@o _^2 ± 3)), doaxis=true, reorder_args=false)
    @test xint(current_axis().targetlimits[]) ≈ 0.1..10  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ -5..105  rtol=0.2
    @test current_axis().xlabel[] == "_"
    @test current_axis().ylabel[] == "_ ^ 2 ± 3"

    rangebars(FPlot(1:10, (@o _), (@o _^2 ± 3)), direction=:x, doaxis=true, reorder_args=false)
    @test xint(current_axis().targetlimits[]) ≈ -5..105  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ 0.1..10  rtol=0.2
    @test current_axis().xlabel[] == "_ ^ 2 ± 3"
    @test current_axis().ylabel[] == "_"

    scatter(FPlot(1:10, (@o _), (@o _^2 ± 3)), doaxis=true, reorder_args=false)
    @test xint(current_axis().targetlimits[]) ≈ 0.1..10  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ -5..105  rtol=0.2
    @test current_axis().xlabel[] == "_"
    @test current_axis().ylabel[] == "_ ^ 2 ± 3"


    ## reorder_args = true
    barplot(FPlot(1:10, (@o _), (@o _^2)), doaxis=true)
    @test xint(current_axis().targetlimits[]) ≈ 0.1..10  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ -5..105  rtol=0.2
    @test current_axis().xlabel[] == "_"
    @test current_axis().ylabel[] == "_ ^ 2"

    barplot(FPlot(1:10, (@o _), (@o _^2)), direction=:x, doaxis=true)
    @test xint(current_axis().targetlimits[]) ≈ 0.1..10  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ -5..105  rtol=0.2
    @test current_axis().xlabel[] == "_"
    @test current_axis().ylabel[] == "_ ^ 2"

    rangebars(FPlot(1:10, (@o _), (@o _^2 ± 3)), doaxis=true)
    @test xint(current_axis().targetlimits[]) ≈ 0.1..10  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ -5..105  rtol=0.2
    @test current_axis().xlabel[] == "_"
    @test current_axis().ylabel[] == "_ ^ 2 ± 3"

    rangebars(FPlot(1:10, (@o _ ± 0.5), (@o _^2 ± 3)), direction=:x, doaxis=true)
    @test xint(current_axis().targetlimits[]) ≈ 0.1..10  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ -5..105  rtol=0.2
    @test current_axis().xlabel[] == "_ ± 0.5"
    @test current_axis().ylabel[] == "_ ^ 2 ± 3"

    vlines(FPlot(1:10, (@o _^2), (@o _^3)), doaxis=true)
    @test xint(current_axis().targetlimits[]) ≈ -4..105  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ 0..10  rtol=0.2
    @test current_axis().xlabel[] == "_ ^ 2"
    @test current_axis().ylabel[] == ""

    hlines(FPlot(1:10, (@o _^2 ± 0.5), (@o _^3 ± 5)), doaxis=true)
    @test xint(current_axis().targetlimits[]) ≈ 0.1..10  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ -50..1050  rtol=0.2
    @test current_axis().xlabel[] == ""
    @test current_axis().ylabel[] == "_ ^ 3 ± 5"
    
    hist(FPlot(1:10, (@o _^2), (@o _^3)), doaxis=true)
    @test xint(current_axis().targetlimits[]) ≈ 0..105  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ -0.1..2.1  rtol=0.2
    @test current_axis().xlabel[] == "_ ^ 2"
    @test current_axis().ylabel[] == ""
    
    hist(FPlot(1:10, nothing, (@o _^3)), doaxis=true, direction=:x)
    @test xint(current_axis().targetlimits[]) ≈ -0.2..4.2  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ -49..1050  rtol=0.2
    @test current_axis().xlabel[] == ""
    @test current_axis().ylabel[] == "_ ^ 3"
end

@testitem "smaller number of args" begin
    using Accessors
    using MakieExtra: xint, yint

    barplot(FPlot(1:10, (@o _ + 1)), doaxis=true)
    @test xint(current_axis().targetlimits[]) ≈ 0.1..11  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ -0.5..11.5  rtol=0.2
    @test current_axis().xlabel[] == ""
    @test current_axis().ylabel[] == ""

    barplot(FPlot(1:10, (@o (_ + 1, _^2))), doaxis=true)
    @test xint(current_axis().targetlimits[]) ≈ 1.1..11.9  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ -5..105  rtol=0.2
    @test current_axis().xlabel[] == ""
    @test current_axis().ylabel[] == ""

    barplot(FPlot(1:10, (@o (_ + 1, _^2))), doaxis=true, direction=:x)
    @test xint(current_axis().targetlimits[]) ≈ -5..105  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ 1.1..11.9  rtol=0.2
    @test current_axis().xlabel[] == ""
    @test current_axis().ylabel[] == ""

    scatter(FPlot(1:10, (@o (_ + 1, _^2))), doaxis=true)
    @test xint(current_axis().targetlimits[]) ≈ 1.1..11.9  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ -5..105  rtol=0.2
    @test_broken current_axis().xlabel[] == ""
    @test current_axis().ylabel[] == ""
end

@testitem "multiplot" begin
    using Accessors
    using CairoMakie

    res = multiplot((Scatter, lines), FPlot(1:10, (@o _), (@o _^2), axis=(xlabel="Abc",)), doaxis=true, _axis=(;width=1234))
    @test res[1] isa Makie.FigureAxisPlot
    ax = content(res[1].figure[:,:])
    @test ax.xlabel[] == "Abc"
    @test ax.ylabel[] == "_ ^ 2"
    @test ax.width[] == 1234
    Makie.colorbuffer(current_figure(); backend=CairoMakie)

    res = multiplot(current_figure()[1,2], (scatter, Lines), FPlot(1:10, (@o _), (@o _^2), axis=(xlabel="Abc",)), doaxis=true, _axis=(;width=1234))
    @test current_axis().xlabel[] == "Abc"
    @test current_axis().ylabel[] == "_ ^ 2"
    @test current_axis().width[] == 1234
    Makie.colorbuffer(current_figure(); backend=CairoMakie)
end

    # fig, ax, plt = lines(FPlot(1:10, (@o _+1), (@o _^2), color=sqrt, axis=(xlabel="Abcdef", yscale=log10)), linewidth=10, doaxis=true)
    # ax = content(fig[1,1])
    # @test ax.xlabel[] == "Abcdef"
    # @test ax.ylabel[] == "^(_, 2)"
    # @test ax.yscale[] == log10
    # fig, ax, plt = lines(FPlot(1:10, (@o _+1), (@o _^2), color=sqrt, axis=(xlabel="Abcdef", yscale=log10)), linewidth=10, doaxis=true, axis=(ylabel="Def",))
    # ax = content(fig[1,1])
    # @test ax.xlabel[] == "Abcdef"
    # @test ax.ylabel[] == "Def"
    # @test ax.yscale[] == log10
    # fig, ax, plt = lines(FPlot(1:10, (@o _+1), (@o _^2), color=sqrt, axis=(xlabel="Abcdef", yscale=log10)), linewidth=10, doaxis=false, axis=(ylabel="Def",))
    # ax = content(fig[1,1])
    # @test ax.xlabel[] == ""
    # @test ax.ylabel[] == "Def"
    # @test ax.yscale[] == identity
    # fig, ax, plt = lines(FPlot(1:10, (@o _+1), (@o _^2), color=sqrt, axis=(xlabel="Abcdef", yscale=log10)), linewidth=10, doaxis=false)
    # @test ax.xlabel[] == ""
    # @test ax.ylabel[] == ""
    # @test ax.yscale[] == identity

@testitem "datacursor" begin
    using MakieExtra: with_widgets, DataCursor, RectSelection, cursor_vals, to_value
    using Accessors

    @test isequal(cursor_vals(DataCursor(), FPlot(nothing, (@o _.a), (@o _.b)), Scatter, 1) |> to_value, [NaN])
    @test isequal(cursor_vals(DataCursor(
        vals=Observable([(@o _.a) => 123])
    ), FPlot(nothing, (@o _.a), (@o _.b)), Scatter, 1) |> to_value, [123])
    @test isequal(cursor_vals(DataCursor(
        vals=Observable([(@o _.a) => 123])
    ), FPlot(nothing, (@o _.a), (@o _.b)), Scatter, 2) |> to_value, [NaN])

    @test isequal(cursor_vals(DataCursor(
        vals=Observable([(@o _.a) => 123, (@o _.b) => 456])
    ), FPlot(nothing, (@o _.a), (@o _.b)), Hist, 1) |> to_value, [123])
    @test isequal(cursor_vals(DataCursor(
        vals=Observable([(@o _.a) => 123, (@o _.b) => 456])
    ), FPlot(nothing, (@o _.a), (@o _.b)), Hist, 2) |> to_value, [NaN])

    @test isequal(cursor_vals(DataCursor(
        vals=Observable([(@o _.a) => 123, (@o _.b) => 456])
    ), FPlot(nothing, (@o _.a), (@o _.b)), Hist, 1; direction=:x) |> to_value, [NaN])
    @test isequal(cursor_vals(DataCursor(
        vals=Observable([(@o _.a) => 123, (@o _.b) => 456])
    ), FPlot(nothing, (@o _.a), (@o _.b)), Hist, 2; direction=:x) |> to_value, [456])
end

@testitem "rectselect" begin
    using MakieExtra: with_widgets, DataCursor, RectSelection, sel_ints, sel_poly, sel_span, to_value
    using Accessors

    @test isequal(
        sel_ints(RectSelection(), FPlot(nothing, (@o _.a), (@o _.b)), Scatter) |> to_value,
        (NaN .. NaN, NaN .. NaN))
    @test isequal(
        sel_ints(RectSelection(vals=Observable([(@o _.a) => 2..5])), FPlot(nothing, (@o _.a), (@o _.b)), Scatter) |> to_value,
        (2 .. 5, NaN .. NaN))
    @test isequal(
        sel_ints(RectSelection(vals=Observable([(@o _.a) => 2..5, (@o _.b) => 10..12])), FPlot(nothing, (@o _.a), (@o _.b)), Scatter) |> to_value,
        (2 .. 5, 10 .. 12))
    @test isequal(
        sel_ints(RectSelection(vals=Observable([(@o _.a) => 2..5, (@o _.b) => 10..12])), FPlot(nothing, (@o _.a), (@o _.b)), Hist) |> to_value,
        [2 .. 5])
    @test isequal(
        sel_ints(RectSelection(vals=Observable([(@o _.a) => 2..5, (@o _.b) => 10..12])), FPlot(nothing, (@o _.a), (@o _.b)), Hist; direction=:x) |> to_value,
        [NaN .. NaN, 10 .. 12])

    @test isequal(
        sel_span(RectSelection(vals=Observable([(@o _.a) => 2..5, (@o _.b) => 10..12])), FPlot(nothing, (@o _.a), (@o _.b)), Hist, 1) |> to_value,
        2 .. 5)
    @test isequal(
        sel_span(RectSelection(vals=Observable([(@o _.a) => 2..5, (@o _.b) => 10..12])), FPlot(nothing, (@o _.a), (@o _.b)), Hist, 2) |> to_value,
        NaN .. NaN)
end

@testitem "interactive smoke test" begin
    using MakieExtra: with_widgets, DataCursor, RectSelection
    using Accessors

    data = [(randn(), rand(), randn()) for _ in 1:1000]

    fplt1 = FPlot(data, (@o _[1]), (@o _[2]))
    dc = DataCursor(lines=(;color=:black, linestyle=:dot))
    rs = RectSelection(poly=(;color=:orange, alpha=0.3))

    fig,_,_ = with_widgets(scatter, [dc, rs])(fplt1, doaxis=true)

    with_widgets(hist, [dc, rs])(fig[2,1], fplt1, doaxis=true)

    fplt2 = @set fplt1[1] = @o _[3]
    with_widgets(scatter, [dc, rs])(fig[1,2], fplt2, doaxis=true, _axis=(;yscale=SymLog(0.1)))
end

@testitem "conversion to FPlot" begin
    using Accessors

    struct MyObj end
    Makie.used_attributes(T::Type{<:Plot}, ::MyObj) = Tuple(Makie.attribute_names(T))
    Makie.convert_arguments(ct::Type{<:AbstractPlot}, ::MyObj; kwargs...) = Makie.convert_arguments(ct, FPlot(1:10, (@o _+1), (@o _^2), color=sqrt); doaxis=true, kwargs...)

    lines(MyObj(); linewidth=15)
    lines(MyObj())
    lines!(MyObj())
    lines!(MyObj(), linewidth=10)
end
