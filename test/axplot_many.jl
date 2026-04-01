@testitem "axplot_many: structural shape" begin
    using Accessors
    using CairoMakie
    using MakieExtra: axplot_many, ToAes

    data = [
        (x=1.0, y=2.0, group=:a, kind=:p),
        (x=2.0, y=4.0, group=:a, kind=:q),
        (x=3.0, y=6.0, group=:b, kind=:p),
        (x=4.0, y=8.0, group=:b, kind=:q),
        (x=5.0, y=10.0, group=:c, kind=:p),
    ]

    # 1.1 No drivers → 1×1 grid; no colorbar when no color
    res = axplot_many(scatter, FPlot(data, (@o _.x), (@o _.y)))
    @test res.figure isa Figure
    @test res.gl isa GridLayout
    @test size(res.axes) == (1, 1)
    @test res.axes[1, 1] isa Axis
    @test res.colorbar === nothing
    Makie.colorbuffer(res.figure; backend=CairoMakie)

    # 1.1b No drivers + numeric color → 1×1 grid with shared colorbar
    res = axplot_many(scatter, FPlot(data, (@o _.x), (@o _.y), color=(@o _.x)))
    @test size(res.axes) == (1, 1)
    @test res.colorbar isa Colorbar

    # 1.2 col=f only → 1 × N grid in first-occurrence order
    res = axplot_many(scatter, FPlot(data, (@o _.x), (@o _.y), col=(@o _.group)))
    @test size(res.axes) == (1, 3)
    @test all(ax isa Axis for ax in res.axes)

    # 1.3 row=f only → mirror of 1.2
    res = axplot_many(scatter, FPlot(data, (@o _.x), (@o _.y), row=(@o _.kind)))
    @test size(res.axes) == (2, 1)
    @test all(ax isa Axis for ax in res.axes)

    # 1.4 col=f + row=g → M×N grid; every combo gets an Axis (empty if no data)
    res = axplot_many(scatter, FPlot(data, (@o _.x), (@o _.y),
                                     col=(@o _.group), row=(@o _.kind)))
    @test size(res.axes) == (2, 3)
    @test count(x -> x isa Axis, res.axes) == 6

    # 1.5 ToAes(:col, funcs) in argfuncs, no kwarg-facet → 1 × length(funcs)
    res = axplot_many(scatter,
        FPlot(data, ToAes(:col, ((@o _.x), (@o _.y))), (@o _.x)))
    @test size(res.axes) == (1, 2)

    # 1.6 ToAes(:row, funcs) in argfuncs → length(funcs) × 1
    res = axplot_many(scatter,
        FPlot(data, ToAes(:row, ((@o _.x), (@o _.y))), (@o _.x)))
    @test size(res.axes) == (2, 1)

    # 1.7 ToAes(:col, funcs) × row=f → length(funcs) cols, N rows
    res = axplot_many(scatter,
        FPlot(data, ToAes(:col, ((@o _.x), (@o _.y))), (@o _.x), row=(@o _.kind)))
    @test size(res.axes) == (2, 2)

    # 1.8 kwargfunc-ToAes (`color=ToAes(:row, ...)`) → length(funcs) rows
    res = axplot_many(scatter,
        FPlot(data, (@o _.x), (@o _.y), color=ToAes(:row, ((@o sqrt(_.x)), (@o log10(_.x))))))
    @test size(res.axes) == (2, 1)

    # 1.9 Parallel zip across argfunc + kwargfunc on same axis
    res = axplot_many(scatter,
        FPlot(data, ToAes(:row, ((@o _.x), (@o _.y))), (@o _.x),
              color=ToAes(:row, ((@o sqrt(_.x)), (@o log10(_.x))))))
    @test size(res.axes) == (2, 1)

    # 1.10 Length-mismatch parallel zip → throws
    @test_throws Exception axplot_many(scatter,
        FPlot(data, ToAes(:row, ((@o _.x), (@o _.y))), (@o _.x),
              color=ToAes(:row, ((@o sqrt(_.x)), (@o log10(_.x)), (@o exp(_.x))))))  # 2 vs 3

    # 1.11 Same-axis double driver → throws
    @test_throws Exception axplot_many(scatter,
        FPlot(data, ToAes(:col, ((@o _.x), (@o _.y))), (@o _.x), col=(@o _.group)))

    # 1.12 Empty ToAes funcs tuple → throws
    @test_throws Exception axplot_many(scatter,
        FPlot(data, ToAes(:row, ()), (@o _.x), (@o _.y)))
end


@testitem "axplot_many: titles" begin
    using Accessors
    using CairoMakie
    using MakieExtra: axplot_many, ToAes

    data = [
        (x=1.0, y=2.0, group=:a, kind=:p),
        (x=2.0, y=4.0, group=:a, kind=:q),
        (x=3.0, y=6.0, group=:b, kind=:p),
        (x=4.0, y=8.0, group=:b, kind=:q),
    ]

    # Helper: collapse Rich/string title to plain string for substring checks
    titletext(t) = string(t)

    # 2.1 col=f only → title is "shortlabel(f) = value", no graying (single row)
    res = axplot_many(scatter, FPlot(data, (@o _.x), (@o _.y), col=(@o _.group)))
    @test res.axes[1, 1].title[] == "group = a"
    @test res.axes[1, 2].title[] == "group = b"

    # 2.2 row=g only → mirror
    res = axplot_many(scatter, FPlot(data, (@o _.x), (@o _.y), row=(@o _.kind)))
    @test res.axes[1, 1].title[] == "kind = p"
    @test res.axes[2, 1].title[] == "kind = q"

    # 2.3 col=f + row=g → composed; first row/col plain, others grayed
    res = axplot_many(scatter, FPlot(data, (@o _.x), (@o _.y),
                                     col=(@o _.group), row=(@o _.kind)))
    # top-left: both contributions plain
    @test occursin("kind = p", titletext(res.axes[1, 1].title[]))
    @test occursin("group = a", titletext(res.axes[1, 1].title[]))
    # row 1, col 2: row contribution should be grayed (gray70)
    t12 = res.axes[1, 2].title[]
    @test occursin("kind = p", titletext(t12))
    @test occursin("group = b", titletext(t12))
    @test occursin("gray70", repr(t12))  # rich(...; color=:gray70) should appear
    # row 2, col 1: col contribution should be grayed
    t21 = res.axes[2, 1].title[]
    @test occursin("kind = q", titletext(t21))
    @test occursin("group = a", titletext(t21))
    @test occursin("gray70", repr(t21))

    # 2.4 argfunc-ToAes(:row, ...) only → title == ""; xlabel/ylabel reflect per-row func
    res = axplot_many(scatter,
        FPlot(data, ToAes(:row, ((@o _.x), (@o _.y))), (@o _.x)))
    @test res.axes[1, 1].title[] == ""
    @test res.axes[2, 1].title[] == ""
    @test res.axes[1, 1].xlabel[] == "x"
    @test res.axes[2, 1].xlabel[] == "y"

    # 2.5 kwargfunc-ToAes(:row, ...) only → "color: <shortlabel>" per row
    res = axplot_many(scatter,
        FPlot(data, (@o _.x), (@o _.y), color=ToAes(:row, ((@o sqrt(_.x)), (@o log10(_.x))))))
    @test res.axes[1, 1].title[] == "color: √x"
    @test res.axes[2, 1].title[] == "color: log₁₀(x)"

    # 2.6 argfunc-ToAes(:row, ...) + col=f → row contribution empty;
    #     col contribution plain on first row, gray on others.
    res = axplot_many(scatter,
        FPlot(data, ToAes(:row, ((@o _.x), (@o _.y))), (@o _.x), col=(@o _.group)))
    @test occursin("group = a", titletext(res.axes[1, 1].title[]))
    @test occursin("group = a", titletext(res.axes[2, 1].title[]))
    @test occursin("gray70", repr(res.axes[2, 1].title[]))

    # 2.7 Parallel-zip kwargfunc-ToAes (two kwargs varying) → titles join with ", "
    res = axplot_many(scatter,
        FPlot(data, (@o _.x), (@o _.y),
              color=ToAes(:row, ((@o sqrt(_.x)), (@o log10(_.x)))),
              markersize=ToAes(:row, ((@o _.x), (@o _.y)))))
    @test occursin("color: √x", titletext(res.axes[1, 1].title[]))
    @test occursin("markersize:", titletext(res.axes[1, 1].title[]))
    @test occursin(", ", titletext(res.axes[1, 1].title[]))

    # 2.8 An axis=(;title="X") set inside FPlot is overridden by the auto-title
    res = axplot_many(scatter,
        FPlot(data, (@o _.x), (@o _.y), col=(@o _.group), axis=(;title="USERTITLE")))
    @test !occursin("USERTITLE", titletext(res.axes[1, 1].title[]))
    @test occursin("group = a", titletext(res.axes[1, 1].title[]))

    # 2.8b No-driver case: FPlot's axis.title is still overridden
    res = axplot_many(scatter,
        FPlot(data, (@o _.x), (@o _.y), axis=(;title="USERTITLE")))
    @test res.axes[1, 1].title[] == ""
end


@testitem "axplot_many: linking and label hiding" begin
    using Accessors
    using CairoMakie
    using MakieExtra: axplot_many, ToAes

    data = [
        (x=1.0, y=2.0, group=:a, kind=:p),
        (x=2.0, y=4.0, group=:a, kind=:q),
        (x=3.0, y=6.0, group=:b, kind=:p),
        (x=4.0, y=8.0, group=:b, kind=:q),
        (x=5.0, y=10.0, group=:c, kind=:p),
        (x=6.0, y=12.0, group=:c, kind=:q),
    ]

    # 3.1 col=f only with linkxaxes=true, linkyaxes=true:
    #     X uniform → all rows show X (only 1 row anyway), Y label only on left col.
    res = axplot_many(scatter, FPlot(data, (@o _.x), (@o _.y), col=(@o _.group)))
    @test res.axes[1, 1].xlabelvisible[]
    @test res.axes[1, 2].xlabelvisible[]
    @test res.axes[1, 1].ylabelvisible[]
    @test !res.axes[1, 2].ylabelvisible[]
    @test !res.axes[1, 3].ylabelvisible[]

    # row=g + col=f case: X visible only on bottom row, Y only on left col
    res = axplot_many(scatter, FPlot(data, (@o _.x), (@o _.y),
                                     col=(@o _.group), row=(@o _.kind)))
    # bottom row (index 2) all X visible; top row hidden
    for c in 1:3
        ax = res.axes[2, c]
        ax === nothing && continue
        @test ax.xlabelvisible[]
    end
    for c in 1:3
        ax = res.axes[1, c]
        ax === nothing && continue
        @test !ax.xlabelvisible[]
    end
    # left col Y visible; other cols hidden
    for r in 1:2
        ax = res.axes[r, 1]
        ax === nothing && continue
        @test ax.ylabelvisible[]
    end
    for r in 1:2, c in 2:3
        ax = res.axes[r, c]
        ax === nothing && continue
        @test !ax.ylabelvisible[]
    end

    # 3.2 argfunc-ToAes(:row, (f1,f2)) at index 1 (X) → X varies row-to-row;
    #     X labels NOT hidden across rows. Y uniform → Y hidden on internal cols (no internal cols here).
    res = axplot_many(scatter,
        FPlot(data, ToAes(:row, ((@o _.x), (@o _.y))), (@o _.x)))
    @test res.axes[1, 1].xlabelvisible[]
    @test res.axes[2, 1].xlabelvisible[]

    # 3.3 argfunc-ToAes(:col, (f1,f2)) at index 2 (Y) → Y varies col-to-col;
    #     Y labels NOT hidden across cols.
    res = axplot_many(scatter,
        FPlot(data, (@o _.x), ToAes(:col, ((@o _.x), (@o _.y)))))
    @test res.axes[1, 1].ylabelvisible[]
    @test res.axes[1, 2].ylabelvisible[]

    # 3.4 Parallel zip: ToAes(:row,...) at idx 1 AND idx 2 → both X and Y vary per row
    res = axplot_many(scatter,
        FPlot(data, ToAes(:row, ((@o _.x), (@o _.y))),
                    ToAes(:row, ((@o _.y), (@o _.x)))))
    for r in 1:2
        @test res.axes[r, 1].xlabelvisible[]
        @test res.axes[r, 1].ylabelvisible[]
    end

    # 3.5 linkxaxes=false → X labels not hidden anywhere
    res = axplot_many(scatter, FPlot(data, (@o _.x), (@o _.y),
                                     col=(@o _.group), row=(@o _.kind)),
                      linkxaxes=false)
    for r in 1:2, c in 1:3
        ax = res.axes[r, c]
        ax === nothing && continue
        @test ax.xlabelvisible[]
    end

    # 3.6 kwargfunc-ToAes(:row, ...) only (no argfunc-ToAes) → linking grid-wide
    #     for both X and Y (kwargfunc-ToAes doesn't change physical axes).
    res = axplot_many(scatter,
        FPlot(data, (@o _.x), (@o _.y), color=ToAes(:row, ((@o sqrt(_.x)), (@o log10(_.x))))))
    # 2 rows × 1 col; X uniform across rows → bottom row visible, top hidden
    @test !res.axes[1, 1].xlabelvisible[]
    @test res.axes[2, 1].xlabelvisible[]
end


@testitem "axplot_many: color attributes (regression)" begin
    using Accessors
    using AccessorsExtra
    using CairoMakie
    using MakieExtra: axplot_many, ToAes
    using MakieExtra.IntervalSets

    data = [
        (x=1.0, y=2.0, c=10.0, group=:a),
        (x=2.0, y=4.0, c=20.0, group=:a),
        (x=3.0, y=6.0, c=30.0, group=:b),
        (x=4.0, y=8.0, c=40.0, group=:b),
    ]

    # 4.1 Numeric color → shared Colorbar with computed colorrange
    res = axplot_many(scatter,
        FPlot(data, (@o _.x), (@o _.y), color=(@o _.c), col=(@o _.group)))
    @test res.colorbar isa Colorbar
    @test res.colorbar.colorrange[] == (10.0, 40.0)

    # 4.2 color = AxFunc(f, scale=log10, limit=1..100) → both subplots and Colorbar use log10/(1,100)
    res = axplot_many(scatter,
        FPlot(data, (@o _.x), (@o _.y),
              color=AxFunc((@o _.c), scale=log10, limit=1..100),
              col=(@o _.group)))
    @test res.colorbar.colorrange[] == (1.0, 100.0)
    @test res.colorbar.scale[] == log10

    # 4.3 lowclip/highclip propagate; nan_color filtered out of Colorbar
    res = axplot_many(scatter,
        FPlot(data, (@o _.x), (@o _.y), color=(@o _.c),
              col=(@o _.group),
              lowclip=Ref(:black), highclip=Ref(:white), nan_color=Ref(:gray)))
    @test res.colorbar.lowclip[] == :black || string(res.colorbar.lowclip[]) == "black"
    @test res.colorbar.highclip[] == :white || string(res.colorbar.highclip[]) == "white"
    # nan_color is not a Colorbar attribute → not set; subplots may still pick it up
    @test !hasproperty(res.colorbar, :nan_color) || res.colorbar.nan_color[] != :gray

    # 4.4 colorscale=Ref(log10) works equivalently to colorscale=log10
    res = axplot_many(scatter,
        FPlot(data, (@o _.x), (@o _.y), color=(@o _.c),
              col=(@o _.group), colorscale=Ref(log10)))
    @test res.colorbar.scale[] == log10

    # 4.5 legend=(;color=false) → no Label+Colorbar
    res = axplot_many(scatter,
        FPlot(data, (@o _.x), (@o _.y), color=(@o _.c), col=(@o _.group)),
        legend=(;color=false))
    @test res.colorbar === nothing

    # 4.6 Categorical color → no shared legend
    res = axplot_many(scatter,
        FPlot(data, (@o _.x), (@o _.y),
              color=AsCategorical(@o _.group), col=(@o _.group)))
    @test res.colorbar === nothing

    # 4.7 color=ToAes(:row, ...) → no shared Colorbar (deferred case)
    res = axplot_many(scatter,
        FPlot(data, (@o _.x), (@o _.y), color=ToAes(:row, ((@o _.c), (@o _.x)))))
    @test res.colorbar === nothing
    @test size(res.axes) == (2, 1)
end


@testitem "axplot_many: observables" begin
    using Accessors
    using CairoMakie
    using MakieExtra: axplot_many, ToAes

    data0 = [
        (x=1.0, y=2.0, group=:a),
        (x=2.0, y=4.0, group=:a),
        (x=3.0, y=6.0, group=:b),
    ]

    # 5.1 Observable{<:FPlot} with col=f; mutate data (same group keys) → cells update; no new cells
    fplt = Observable(FPlot(data0, (@o _.x), (@o _.y), col=(@o _.group)))
    res = axplot_many(scatter, fplt)
    @test size(res.axes) == (1, 2)
    fplt[] = FPlot([
        (x=10.0, y=20.0, group=:a),
        (x=30.0, y=60.0, group=:b),
    ], (@o _.x), (@o _.y), col=(@o _.group))
    @test size(res.axes) == (1, 2)

    # 5.2 New group key in data → silently dropped (no new cells)
    fplt[] = FPlot([
        (x=1.0, y=2.0, group=:a),
        (x=2.0, y=4.0, group=:b),
        (x=5.0, y=10.0, group=:c),  # not in initial set
    ], (@o _.x), (@o _.y), col=(@o _.group))
    @test size(res.axes) == (1, 2)

    # 5.3 Initial group key now has empty data → cell remains, no error
    fplt[] = FPlot([
        (x=10.0, y=20.0, group=:b),  # only :b now; :a empty
    ], (@o _.x), (@o _.y), col=(@o _.group))
    @test size(res.axes) == (1, 2)

    # 5.4 ToAes length change → silently ignored (cells frozen to initial layout)
    fplt2 = Observable(FPlot(data0,
        ToAes(:row, ((@o _.x), (@o _.y))), (@o _.x)))
    res2 = axplot_many(scatter, fplt2)
    @test size(res2.axes) == (2, 1)
    fplt2[] = FPlot(data0, ToAes(:row, ((@o _.x),)), (@o _.x))  # length changed: 2 → 1
    @test size(res2.axes) == (2, 1)

    # 5.6 kwarg×kwarg with an initially-empty (row, col) combo: cell exists from the start
    # and is populated reactively when data fills the combo via fplt[] mutation.
    data_ragged = [
        (x=1.0, y=2.0, group=:a, kind=:p),
        (x=2.0, y=4.0, group=:a, kind=:q),
        (x=3.0, y=6.0, group=:b, kind=:p),
        (x=4.0, y=8.0, group=:b, kind=:q),
        (x=5.0, y=10.0, group=:c, kind=:p),
        # missing: (group=:c, kind=:q)
    ]
    fplt3 = Observable(FPlot(data_ragged, (@o _.x), (@o _.y),
                             col=(@o _.group), row=(@o _.kind)))
    res3 = axplot_many(scatter, fplt3)
    @test size(res3.axes) == (2, 3)
    @test all(ax -> ax isa Axis, res3.axes)  # no nothing entries, even for the empty combo
    # Now fill the missing combo via observable update
    fplt3[] = FPlot([data_ragged...; (x=6.0, y=12.0, group=:c, kind=:q)],
                    (@o _.x), (@o _.y), col=(@o _.group), row=(@o _.kind))
    @test size(res3.axes) == (2, 3)
    @test all(ax -> ax isa Axis, res3.axes)
    Makie.colorbuffer(res3.figure; backend=CairoMakie)
end


@testitem "axplot_many: return value" begin
    using Accessors
    using CairoMakie
    using MakieExtra: axplot_many

    data = [
        (x=1.0, y=2.0, group=:a, kind=:p),
        (x=2.0, y=4.0, group=:a, kind=:q),
        (x=3.0, y=6.0, group=:b, kind=:p),
        (x=4.0, y=8.0, group=:b, kind=:q),
        (x=5.0, y=10.0, group=:c, kind=:p),
    ]

    # 6.1 Top-level: NamedTuple with the right keys; figure isa Figure
    res = axplot_many(scatter, FPlot(data, (@o _.x), (@o _.y), col=(@o _.group)))
    @test propertynames(res) == (:figure, :gl, :axes, :plots, :colorbar)
    @test res.figure isa Figure

    # 6.2 Positional: figure === nothing; gl isa GridLayout
    fig = Figure()
    res = axplot_many(fig[1, 1], scatter, FPlot(data, (@o _.x), (@o _.y), col=(@o _.group)))
    @test res.figure === nothing
    @test res.gl isa GridLayout

    # 6.3 axes is a Matrix; every cell is an Axis (empty cells included)
    res = axplot_many(scatter, FPlot(data, (@o _.x), (@o _.y),
                                     col=(@o _.group), row=(@o _.kind)))
    @test res.axes isa Matrix
    @test size(res.axes) == (2, 3)
    @test count(x -> x isa Axis, res.axes) == 6

    # 6.4 plots matrix matches axes shape; every entry populated
    @test size(res.plots) == size(res.axes)
    @test all(!isnothing, res.plots)

    # 6.5 colorbar is Colorbar when produced; nothing otherwise
    @test res.colorbar === nothing  # no color in this FPlot
    res2 = axplot_many(scatter, FPlot(data, (@o _.x), (@o _.y),
                                      color=(@o _.x), col=(@o _.group)))
    @test res2.colorbar isa Colorbar
end


@testitem "axplot_many: smoke" begin
    using Accessors
    using CairoMakie
    using MakieExtra: axplot_many

    data = [
        (x=1.0, y=2.0, group=:a),
        (x=2.0, y=4.0, group=:a),
        (x=3.0, y=6.0, group=:b),
    ]

    # 7.1 multiplot-style plotf=(scatter, lines) works through axplot_many
    res = axplot_many((scatter, lines),
                      FPlot(data, (@o _.x), (@o _.y), col=(@o _.group)))
    @test size(res.axes) == (1, 2)
    Makie.colorbuffer(res.figure; backend=CairoMakie)

    # 7.2 Top-level form returns a Figure-bearing NamedTuple, no errors
    res = axplot_many(scatter, FPlot(data, (@o _.x), (@o _.y), col=(@o _.group)))
    @test res.figure isa Figure

    # 7.3 axplot_many rejects unknown kwargs
    @test_throws Exception axplot_many(scatter,
        FPlot(data, (@o _.x), (@o _.y), col=(@o _.group)); markersize=10)
end
