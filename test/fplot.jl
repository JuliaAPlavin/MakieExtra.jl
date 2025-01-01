@testitem "fplot structure" begin
    using Accessors

    fp = FPlot(1:10, (@o _+1), (@o _^2), color=sqrt, linewidth=123)
    
    @test fp.data === 1:10
    @test fp.color === sqrt
    @test fp[1] === @o _+1
    @test fp[2] === @o _^2
    @test fp[:color] === sqrt

    @test (@set fp.argfuncs = (identity,)) === FPlot(1:10, identity, color=sqrt, linewidth=123)
    @test (@set fp.kwargfuncs = (;)) === FPlot(1:10, (@o _+1), (@o _^2))
    @test (@set fp.kwargfuncs = (;color=sin, markersize=sqrt)) === FPlot(1:10, (@o _+1), (@o _^2), color=sin, markersize=sqrt)

    @test (@set fp.data = [1,2,3]) == FPlot([1,2,3], (@o _+1), (@o _^2), color=sqrt, linewidth=123)
    @test (@delete fp.data) === FPlot(nothing, (@o _+1), (@o _^2), color=sqrt, linewidth=123)
    fp_nov = FPlot(nothing, (@o _+1), (@o _^2), color=sqrt)
    @test (@insert fp_nov.data = 1:10) === FPlot(1:10, (@o _+1), (@o _^2), color=sqrt)
    
    @test (@set fp.color = sin) === FPlot(1:10, (@o _+1), (@o _^2), color=sin, linewidth=123)
    @test (@delete fp.color) === FPlot(1:10, (@o _+1), (@o _^2), linewidth=123)
    @test (@insert fp.markersize = sin) === FPlot(1:10, (@o _+1), (@o _^2), color=sqrt, linewidth=123, markersize=sin)
    @test (@set fp[:color] = sin) === @set fp.color = sin
    @test (@set fp[(:linewidth, :color)] = (sin, cos)) === FPlot(1:10, (@o _+1), (@o _^2), color=cos, linewidth=sin)
    @test (@delete fp[:color]) === @delete fp.color
    @test (@delete fp[(:linewidth, :color)]) === FPlot(1:10, (@o _+1), (@o _^2))
    @test (@insert fp[:markersize] = sin) === FPlot(1:10, (@o _+1), (@o _^2), color=sqrt, linewidth=123, markersize=sin)
    @test (@insert fp[(:markersize, :abc)] = (sin, cos)) === FPlot(1:10, (@o _+1), (@o _^2), color=sqrt, linewidth=123, markersize=sin, abc=cos)
    
    @test (@set fp[1] = @o _+2) === FPlot(1:10, (@o _+2), (@o _^2), color=sqrt, linewidth=123)
    @test (@set fp[1:2] = (@o _+2), (@o _^3)) === FPlot(1:10, (@o _+2), (@o _^3), color=sqrt, linewidth=123)
    @test (@delete fp[1]) === FPlot(1:10, nothing, (@o _^2), color=sqrt, linewidth=123)
    @test (@delete fp[2]) === FPlot(1:10, (@o _+1), color=sqrt, linewidth=123)
    @test (@delete fp[1:2]) === FPlot(1:10, color=sqrt, linewidth=123)
    @test (@insert fp[3] = @o _+2) === FPlot(1:10, (@o _+1), (@o _^2), (@o _+2), color=sqrt, linewidth=123)
    @test (@insert fp[3:4] = (@o _+2), (@o _^3)) === FPlot(1:10, (@o _+1), (@o _^2), (@o _+2), (@o _^3), color=sqrt, linewidth=123)

    fp = FPlot(1:10, (@o _+1), (@o _^2), color=sqrt, linewidth=123, axis=(;limits=(1..2, nothing)))
    @test FPlot(fp, markersize=5) === FPlot(1:10, (@o _+1), (@o _^2), color=sqrt, linewidth=123, markersize=5, axis=(;limits=((1,2), nothing)))
    @test FPlot(fp, color=log, markersize=5) === FPlot(1:10, (@o _+1), (@o _^2), color=log, linewidth=123, markersize=5, axis=(;limits=((1,2), nothing)))
    @test FPlot(fp, axis=(;limits=(nothing, (0, nothing)))) === FPlot(1:10, (@o _+1), (@o _^2), color=sqrt, linewidth=123, axis=(;limits=((1,2), (0, nothing))))
    @test FPlot(fp, log) === FPlot(1:10, log, (@o _^2), color=sqrt, linewidth=123, axis=(;limits=((1,2), nothing)))
    @test FPlot(fp, color=log, data=10:15) === FPlot(10:15, (@o _+1), (@o _^2), color=log, linewidth=123, axis=(;limits=((1,2), nothing)))
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

    fplt = Observable(FPlot(x->x+1, (@o _^2), color=sqrt, linewidth=Ref(10)))
    plt = lines!(1:10, fplt)
    @test plt.linewidth[] == 10
    fplt[] = FPlot(x->x+1, (@o _^2), color=sqrt, linewidth=Ref(15))
    @test plt.linewidth[] == 15

    fplt = Observable(FPlot(x->x+1, (@o _^2), color=sqrt))
    plt = lines!(1:10, fplt, linewidth=10)
    @test plt.linewidth[] == 10
    fplt[] = FPlot(x->x+1, (@o _^2), color=log)
    @test plt.linewidth[] == 10

    plt = lines!(1:10, FPlot(x->x+1, (@o _^2), color=sqrt, markersize=identity), linewidth=15)
    @test plt.linewidth[] == 15
end

@testitem "axplot" begin
    using Accessors
    using CairoMakie

    fig, ax, plt = lines(FPlot(1:10, (@o _+1), (@o _^2), color=sqrt), axis=(ylabel="Abc",))
    @test content(fig[1,1]).xlabel[] == ""
    @test content(fig[1,1]).ylabel[] == "Abc"
    Makie.colorbuffer(current_figure(); backend=CairoMakie)

    ax, plt = axplot(lines)(current_figure()[2,1], FPlot(1:10, (@o _+1), (@o _^2), color=sqrt), axis=(ylabel="Abc",))
    @test content(fig[2,1]).xlabel[] == "_ + 1"
    @test content(fig[2,1]).ylabel[] == "Abc"
    Makie.colorbuffer(current_figure(); backend=CairoMakie)

    fig, ax, plt = axplot(lines, autolimits_refresh=false)(Observable(FPlot(1:10, (@o _+1), (@o _^2); color=sqrt, axis=(ylabel="Abc",))))
    @test content(fig[1,1]).xlabel[] == "_ + 1"
    @test content(fig[1,1]).ylabel[] == "Abc"
    Makie.colorbuffer(current_figure(); backend=CairoMakie)


    fig, ax, plt = scatter([(0,0)])
    axplot(lines!)(ax, FPlot(1:10, (@o _/1), (@o _+2), color=sqrt))
    @test content(fig[1,1]).xlabel[] == "_ / 1"
    @test content(fig[1,1]).ylabel[] == "_ + 2"

    fig, ax, plt = scatter([(0,0)])
    axplot(lines!)(FPlot(1:10, (@o _/1), (@o _+2), color=sqrt), axis=(;xlabel=Observable("Abc"),))
    @test content(fig[1,1]).xlabel[] == "Abc"
    @test content(fig[1,1]).ylabel[] == "_ + 2"
end

@testitem "axfunc" begin
    fplt = FPlot(1:10, AxFunc(x->x+1, label="Abc", ticks=-10:100), AxFunc(x->x^2, label="Def"))
    axplot(lines)(fplt)
    @test current_axis().xlabel[] == "Abc"
    @test current_axis().ylabel[] == "Def"
    @test current_axis().xticks[] == -10:100
end

@testitem "categorical" begin
    using Accessors

    axplot(lines)(FPlot(1:10, string, (@o _^2), color=sqrt))
    @test current_axis().xlabel[] == "string(_)"

    axplot(lines)(FPlot(1:10, string, (@o _^2), color=(@o _ > 5 ? :blue : :red)))
end

@testitem "unitful" begin
    using Accessors, Unitful

    axplot(lines)(FPlot((1:10)u"m", (@o ustrip(u"cm", 2*_)), (@o ustrip(_^2))))
    @test current_axis().xlabel[] == "2 * _ (cm)"
    @test_broken current_axis().ylabel[] == "^(_, 2) (m^2)"
end

@testitem "modified/reordered args" begin
    using Accessors
    using MakieExtra: xint, yint
    using Uncertain

    ## reorder_args = false
    axplot(barplot)(FPlot(1:10, (@o _), (@o _^2)), reorder_args=false)
    autolimits!()
    @test xint(current_axis().targetlimits[]) ≈ 0.1..10  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ -5..105  rtol=0.2
    @test current_axis().xlabel[] == "_"
    @test current_axis().ylabel[] == "_ ^ 2"

    axplot(barplot)(FPlot(1:10, (@o _), (@o _^2)), direction=:x, reorder_args=false)
    autolimits!()
    @test xint(current_axis().targetlimits[]) ≈ -5..105  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ 0.1..10  rtol=0.2
    @test current_axis().xlabel[] == "_ ^ 2"
    @test current_axis().ylabel[] == "_"

    axplot(rangebars)(FPlot(1:10, (@o _), (@o _^2 ±ᵤ 3)), reorder_args=false)
    autolimits!()
    @test xint(current_axis().targetlimits[]) ≈ 0.1..10  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ -5..105  rtol=0.2
    @test current_axis().xlabel[] == "_"
    @test current_axis().ylabel[] == "(_ ^ 2) ±ᵤ 3"

    axplot(rangebars)(FPlot(1:10, (@o _), (@o _^2 ±ᵤ 3)), direction=:x, reorder_args=false)
    autolimits!()
    @test xint(current_axis().targetlimits[]) ≈ -5..105  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ 0.1..10  rtol=0.2
    @test current_axis().xlabel[] == "(_ ^ 2) ±ᵤ 3"
    @test current_axis().ylabel[] == "_"

    axplot(scatter)(FPlot(1:10, (@o _), (@o _^2 ±ᵤ 3)), reorder_args=false)
    autolimits!()
    @test xint(current_axis().targetlimits[]) ≈ 0.1..10  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ -5..105  rtol=0.2
    @test current_axis().xlabel[] == "_"
    @test current_axis().ylabel[] == "(_ ^ 2) ±ᵤ 3"


    ## reorder_args = true
    axplot(barplot)(FPlot(1:10, (@o _), (@o _^2)))
    autolimits!()
    @test xint(current_axis().targetlimits[]) ≈ 0.1..10  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ -5..105  rtol=0.2
    @test current_axis().xlabel[] == "_"
    @test current_axis().ylabel[] == "_ ^ 2"

    axplot(barplot)(FPlot(1:10, (@o _), (@o _^2)), direction=:x)
    autolimits!()
    @test xint(current_axis().targetlimits[]) ≈ 0.1..10  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ -5..105  rtol=0.2
    @test current_axis().xlabel[] == "_"
    @test current_axis().ylabel[] == "_ ^ 2"

    axplot(rangebars)(FPlot(1:10, (@o _), (@o _^2 ±ᵤ 3)))
    autolimits!()
    @test xint(current_axis().targetlimits[]) ≈ 0.1..10  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ -5..105  rtol=0.2
    @test current_axis().xlabel[] == "_"
    @test current_axis().ylabel[] == "(_ ^ 2) ±ᵤ 3"

    axplot(rangebars)(FPlot(1:10, (@o _ ±ᵤ 0.5), (@o _^2 ±ᵤ 3)), direction=:x)
    autolimits!()
    @test xint(current_axis().targetlimits[]) ≈ 0.1..10  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ -5..105  rtol=0.2
    @test current_axis().xlabel[] == "_ ±ᵤ 0.5"
    @test current_axis().ylabel[] == "(_ ^ 2) ±ᵤ 3"

    axplot(vlines)(FPlot(1:10, (@o _^2), (@o _^3)))
    autolimits!()
    @test xint(current_axis().targetlimits[]) ≈ -4..105  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ 0..10  rtol=0.2
    @test current_axis().xlabel[] == "_ ^ 2"
    @test current_axis().ylabel[] == ""

    axplot(hlines)(FPlot(1:10, (@o _^2 ±ᵤ 0.5), (@o _^3 ±ᵤ 5)))
    autolimits!()
    @test xint(current_axis().targetlimits[]) ≈ 0.1..10  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ -50..1050  rtol=0.2
    @test current_axis().xlabel[] == ""
    @test current_axis().ylabel[] == "(_ ^ 3) ±ᵤ 5"
    
    axplot(hist)(FPlot(1:10, (@o _^2), (@o _^3)))
    autolimits!()
    @test xint(current_axis().targetlimits[]) ≈ 0..105  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ -0.1..2.1  rtol=0.2
    @test current_axis().xlabel[] == "_ ^ 2"
    @test current_axis().ylabel[] == ""
    
    axplot(hist)(FPlot(1:10, nothing, (@o _^3)), direction=:x)
    autolimits!()
    @test xint(current_axis().targetlimits[]) ≈ -0.2..4.2  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ -49..1050  rtol=0.2
    @test current_axis().xlabel[] == ""
    @test current_axis().ylabel[] == "_ ^ 3"
end

@testitem "smaller number of args" begin
    using Accessors
    using MakieExtra: xint, yint

    axplot(barplot)(FPlot(1:10, (@o _ + 1)))
    @test xint(current_axis().targetlimits[]) ≈ 0.1..11  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ -0.5..11.5  rtol=0.2
    @test current_axis().xlabel[] == ""
    @test current_axis().ylabel[] == ""

    axplot(barplot)(FPlot(1:10, (@o (_ + 1, _^2))))
    autolimits!()
    @test xint(current_axis().targetlimits[]) ≈ 1.1..11.9  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ -5..105  rtol=0.2
    @test current_axis().xlabel[] == ""
    @test current_axis().ylabel[] == ""

    axplot(barplot)(FPlot(1:10, (@o (_ + 1, _^2))), direction=:x)
    autolimits!()
    @test xint(current_axis().targetlimits[]) ≈ -5..105  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ 1.1..11.9  rtol=0.2
    @test current_axis().xlabel[] == ""
    @test current_axis().ylabel[] == ""

    axplot(scatter)(FPlot(1:10, (@o (_ + 1, _^2))))
    autolimits!()
    @test xint(current_axis().targetlimits[]) ≈ 1.1..11.9  rtol=0.2
    @test yint(current_axis().targetlimits[]) ≈ -5..105  rtol=0.2
    @test_broken current_axis().xlabel[] == ""
    @test current_axis().ylabel[] == ""
end

@testitem "multiplot" begin
    using Accessors
    using CairoMakie

    res = multiplot((axplot(scatter), lines), FPlot(1:10, (@o _), (@o _^2), axis=(xlabel="Abc",)), axis=(;width=1234))
    @test res[1] isa Makie.FigureAxisPlot
    ax = content(res[1].figure[:,:])
    @test ax.xlabel[] == "Abc"
    @test ax.ylabel[] == "_ ^ 2"
    @test ax.width[] == 1234
    Makie.colorbuffer(current_figure(); backend=CairoMakie)

    res = multiplot(current_figure()[1,2], (axplot(scatter), Lines), FPlot(1:10, (@o _), (@o _^2), axis=(xlabel="Abc",)), axis=(;width=1234))
    @test current_axis().xlabel[] == "Abc"
    @test current_axis().ylabel[] == "_ ^ 2"
    @test current_axis().width[] == 1234
    Makie.colorbuffer(current_figure(); backend=CairoMakie)

    scatter([0,0])
    multiplot!((axplot(scatter), Lines), FPlot(1:10, (@o _), (@o _^2), axis=(xlabel="Abc",)), axis=(;width=1234))
    @test current_axis().xlabel[] == "Abc"
    @test current_axis().ylabel[] == "_ ^ 2"
    @test current_axis().width[] == 1234

    fplt = FPlot(1:10, (@o _), (@o _^2))
    multiplot((Hist, HLines => (xmin=0, xmax=0.06, linewidth=0.5)), fplt, normalization=:pdf, direction=:x)
    Makie.colorbuffer(current_figure(); backend=CairoMakie)
end

    # fig, ax, plt = axplot(lines)(FPlot(1:10, (@o _+1), (@o _^2), color=sqrt, axis=(xlabel="Abcdef", yscale=log10)), linewidth=10)
    # ax = content(fig[1,1])
    # @test ax.xlabel[] == "Abcdef"
    # @test ax.ylabel[] == "^(_, 2)"
    # @test ax.yscale[] == log10
    # fig, ax, plt = axplot(lines)(FPlot(1:10, (@o _+1), (@o _^2), color=sqrt, axis=(xlabel="Abcdef", yscale=log10)), linewidth=10, axis=(ylabel="Def",))
    # ax = content(fig[1,1])
    # @test ax.xlabel[] == "Abcdef"
    # @test ax.ylabel[] == "Def"
    # @test ax.yscale[] == log10
    # fig, ax, plt = lines(FPlot(1:10, (@o _+1), (@o _^2), color=sqrt, axis=(xlabel="Abcdef", yscale=log10)), linewidth=10, axis=(ylabel="Def",))
    # ax = content(fig[1,1])
    # @test ax.xlabel[] == ""
    # @test ax.ylabel[] == "Def"
    # @test ax.yscale[] == identity
    # fig, ax, plt = lines(FPlot(1:10, (@o _+1), (@o _^2), color=sqrt, axis=(xlabel="Abcdef", yscale=log10)), linewidth=10)
    # @test ax.xlabel[] == ""
    # @test ax.ylabel[] == ""
    # @test ax.yscale[] == identity

@testitem "datacursor" begin
    using MakieExtra: cursor_vals, to_value
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
    using MakieExtra: sel_ints, sel_poly, sel_span, to_value, normalized_selints
    using Accessors

    @test isequal(
        sel_ints(RectSelection(), FPlot(nothing, (@o _.a), (@o _.b)), Scatter) |> to_value,
        (NaN..NaN, NaN..NaN))
    @test isequal(
        sel_ints(RectSelection(vals=Observable([(@o _.a) => 2..5])), FPlot(nothing, (@o _.a), (@o _.b)), Scatter) |> to_value,
        (2..5, NaN..NaN))
    @test isequal(
        sel_ints(RectSelection(vals=Observable([(@o _.a) => 2..5, (@o _.b) => 10..12])), FPlot(nothing, (@o _.a), (@o _.b)), Scatter) |> to_value,
        (2..5, 10..12))
    @test isequal(
        sel_ints(RectSelection(vals=Observable([(@o _.a) => 2..5, (@o _.b) => 10..12])), FPlot(nothing, (@o _.a), (@o _.b)), Hist) |> to_value,
        [2..5])
    @test isequal(
        sel_ints(RectSelection(vals=Observable([(@o _.a) => 2..5, (@o _.b) => 10..12])), FPlot(nothing, (@o _.a), (@o _.b)), Hist; direction=:x) |> to_value,
        [NaN..NaN, 10..12])

    @test isequal(
        sel_span(RectSelection(vals=Observable([(@o _.a) => 2..5, (@o _.b) => 10..12])), FPlot(nothing, (@o _.a), (@o _.b)), Hist, 1) |> to_value,
        2..5)
    @test isequal(
        sel_span(RectSelection(vals=Observable([(@o _.a) => 2..5, (@o _.b) => 10..12])), FPlot(nothing, (@o _.a), (@o _.b)), Hist, 2) |> to_value,
        NaN..NaN)

    rs = RectSelection(vals=Observable([(@o _.a) => 2..5, (@o _.b) => 12..10]))
    @test to_value(normalized_selints(rs)::Observable) == [(@o _.a) => 2..5, (@o _.b) => 10..12]
    data = [(a=1, b=2, c="x"), (a=4, b=5, c="y"), (a=4, b=11, c="z"), (a=5, b=10, c="w"), (a=6, b=10, c="v")]
    @test selected_data(data, rs)::Observable |> to_value == [(a=4, b=11, c="z"), (a=5, b=10, c="w")]
    mdata = mark_selected_data(data, rs)::Observable |> to_value
    @test map(is_selected, mdata) == [false, false, false, true, true]
    @test issetequal(map(x -> x[(:a,:b,:c)], mdata), data)

    rs = RectSelection(vals=Observable([]))
    @test to_value(normalized_selints(rs)::Observable) == []
    data = [(a=1, b=2, c="x"), (a=4, b=5, c="y"), (a=4, b=11, c="z"), (a=5, b=10, c="w"), (a=6, b=10, c="v")]
    @test selected_data(data, rs)::Observable |> to_value == data
    mdata = mark_selected_data(data, rs)::Observable |> to_value
    @test map(is_selected, mdata) |> all
    @test map(x -> x[(:a,:b,:c)], mdata) == data

    rs = RectSelection(vals=Observable([(@o _.a) => 2..2, (@o _.b) => 12..12]))
    @test to_value(normalized_selints(rs)::Observable) == [(@o _.a) => 2..2, (@o _.b) => 12..12]
    data = [(a=1, b=2, c="x"), (a=4, b=5, c="y"), (a=4, b=11, c="z"), (a=5, b=10, c="w"), (a=6, b=10, c="v")]
    @test selected_data(data, rs)::Observable |> to_value == data
    mdata = mark_selected_data(data, rs)::Observable |> to_value
    @test map(is_selected, mdata) |> all
    @test map(x -> x[(:a,:b,:c)], mdata) == data
end

@testitem "interactive smoke test" begin
    using Accessors

    data = [(randn(), rand(), randn()) for _ in 1:1000]

    fplt1 = FPlot(data, (@o _[1]), (@o _[2]))
    dc = DataCursor(lines=(;color=:black, linestyle=:dot))
    rs = RectSelection(poly=(;color=:orange, alpha=0.3))

    fig,_,_ = axplot(scatter, widgets=[dc, rs])(fplt1)

    axplot(hist, widgets=[dc, rs])(fig[2,1], fplt1)

    fplt2 = @set fplt1[1] = @o _[3]
    axplot(scatter, widgets=[dc, rs])(fig[1,2], fplt2, axis=(;yscale=SymLog(0.1)))
end

@testitem "conversion to FPlot" begin
    using Accessors

    struct MyObj end
    Makie.convert_arguments(ct::Type{<:AbstractPlot}, ::MyObj; kwargs...) = Makie.convert_arguments(ct, FPlot(1:10, (@o _+1), (@o _^2), color=sqrt); kwargs...)

    lines(MyObj(); linewidth=15)
    lines(MyObj())
    lines!(MyObj())
    lines!(MyObj(), linewidth=10)
end
