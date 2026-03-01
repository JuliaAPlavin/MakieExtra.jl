@testitem "geoaxis" begin
    using GeoMakie
    using MakieExtra.IntervalSets
    using MakieExtra.GeometryBasics: MultiPolygon
    import CairoMakie

    MakieExtra.GeoAxis_radians!()
    MakieExtra.GeoAxis_splitwrap!()

	fig = Figure()
	ax = GeoAxis(fig[1,1], dest="+proj=moll")

	lp = lines!(ax, map(x->(x/50, x/1000), 1:20:1000))
	pp_vec = poly!(ax, [
		Rect(0±0.2, 0.5±0.1),
		Rect(3±0.2, -0.5±0.1),
	])
	pp_cross = poly!(ax, Rect(3±0.2, 0.5±0.1))
	pp_circle = poly!(ax, Circle(Point2(-3.1, 0), 0.1))

    colorbuffer(fig)

    # verify splitting is used in the rendered plots
    @test count(p -> any(isnan, p), lp[1][]) > 0
    @test pp_cross[1][] isa MultiPolygon
    @test length(pp_cross[1][].polygons) == 2
    @test pp_vec[1][] isa AbstractVector{<:MultiPolygon}
    @test length(pp_vec[1][][1].polygons) == 1  # Rect(0±0.2, ...) doesn't cross boundary
    @test length(pp_vec[1][][2].polygons) == 2  # Rect(3±0.2, ...) crosses π
    @test pp_circle[1][] isa MultiPolygon
    @test length(pp_circle[1][].polygons) == 2
end

@testitem "geoaxis observable" begin
    using GeoMakie
    using MakieExtra.IntervalSets
    using MakieExtra.GeometryBasics: MultiPolygon
    import CairoMakie

    MakieExtra.GeoAxis_radians!()
    MakieExtra.GeoAxis_splitwrap!()

    fig = Figure()
    ax = GeoAxis(fig[1,1], dest="+proj=moll")

    # initial data: lines cross boundary, poly vec has one crossing one not, single rect crosses, circle crosses
    lp_obs = Observable(map(x->(x/50, x/1000), 1:20:1000))
    pp_vec_obs = Observable([Rect(0±0.2, 0.5±0.1), Rect(3±0.2, -0.5±0.1)])
    pp_cross_obs = Observable(Rect(3±0.2, 0.5±0.1))
    pp_circle_obs = Observable(Circle(Point2(-3.1, 0), 0.1))

    lp = lines!(ax, lp_obs)
    pp_vec = poly!(ax, pp_vec_obs)
    pp_cross = poly!(ax, pp_cross_obs)
    pp_circle = poly!(ax, pp_circle_obs)

    colorbuffer(fig)

    # verify splitting on initial data
    @test count(p -> any(isnan, p), lp[1][]) > 0
    @test pp_cross[1][] isa MultiPolygon
    @test length(pp_cross[1][].polygons) == 2
    @test pp_vec[1][] isa AbstractVector{<:MultiPolygon}
    @test length(pp_vec[1][][1].polygons) == 1
    @test length(pp_vec[1][][2].polygons) == 2
    @test pp_circle[1][] isa MultiPolygon
    @test length(pp_circle[1][].polygons) == 2

    # update: lines no longer cross boundary (small range within [-π, π])
    lp_obs[] = map(x->(x/500, x/1000), 1:20:1000)
    # update: swap crossing — first rect now crosses, second doesn't
    pp_vec_obs[] = [Rect(3±0.2, 0.5±0.1), Rect(0±0.2, -0.5±0.1)]
    # update: single rect no longer crosses
    pp_cross_obs[] = Rect(1±0.2, 0.5±0.1)
    # update: circle no longer crosses (moved away from ±π)
    pp_circle_obs[] = Circle(Point2(0.0, 0), 0.1)

    colorbuffer(fig)

    # verify updated splitting
    @test count(p -> any(isnan, p), lp[1][]) == 0  # no crossing now
    @test pp_vec[1][] isa AbstractVector{<:MultiPolygon}
    @test length(pp_vec[1][][1].polygons) == 2  # first rect now crosses
    @test length(pp_vec[1][][2].polygons) == 1  # second rect doesn't cross
    @test pp_cross[1][] isa MultiPolygon
    @test length(pp_cross[1][].polygons) == 1  # no longer crosses
    @test pp_circle[1][] isa MultiPolygon
    @test length(pp_circle[1][].polygons) == 1  # no longer crosses
end

@testitem "geoaxis fplot" begin
    using GeoMakie
    using MakieExtra.IntervalSets
    using MakieExtra.GeometryBasics: MultiPolygon
    import CairoMakie

    MakieExtra.GeoAxis_radians!()
    MakieExtra.GeoAxis_splitwrap!()

    fig = Figure()
    ax = GeoAxis(fig[1,1], dest="+proj=moll")

    lp = lines!(ax, FPlot(map(x->(x/50, x/1000), 1:20:1000), identity))
    pp_vec = poly!(ax, FPlot([
        Rect(0±0.2, 0.5±0.1),
        Rect(3±0.2, -0.5±0.1),
    ], identity))
    pp_cross = poly!(ax, FPlot([Rect(3±0.2, 0.5±0.1)], identity))
    pp_circle = poly!(ax, FPlot([Circle(Point2(-3.1, 0), 0.1)], identity))

    colorbuffer(fig)

    # Access child plots inside PlotList
    lp_child = only(lp.plots)
    pp_vec_child = only(pp_vec.plots)
    pp_cross_child = only(pp_cross.plots)
    pp_circle_child = only(pp_circle.plots)

    # verify splitting is used in the rendered plots
    @test count(p -> any(isnan, p), lp_child[1][]) > 0
    @test pp_vec_child[1][] isa AbstractVector{<:MultiPolygon}
    @test length(pp_vec_child[1][][1].polygons) == 1  # Rect(0±0.2, ...) doesn't cross boundary
    @test length(pp_vec_child[1][][2].polygons) == 2  # Rect(3±0.2, ...) crosses π
    @test pp_cross_child[1][] isa AbstractVector{<:MultiPolygon}
    @test length(pp_cross_child[1][][1].polygons) == 2
    @test pp_circle_child[1][] isa AbstractVector{<:MultiPolygon}
    @test length(pp_circle_child[1][][1].polygons) == 2
end

@testitem "geoaxis fplot observable" begin
    using GeoMakie
    using MakieExtra.IntervalSets
    using MakieExtra.GeometryBasics: MultiPolygon
    import CairoMakie

    MakieExtra.GeoAxis_radians!()
    MakieExtra.GeoAxis_splitwrap!()

    fig = Figure()
    ax = GeoAxis(fig[1,1], dest="+proj=moll")

    # initial data: lines cross, poly vec has one crossing one not, single rect crosses, circle crosses
    lp_obs = Observable(FPlot(map(x->(x/50, x/1000), 1:20:1000), identity))
    pp_vec_obs = Observable(FPlot([Rect(0±0.2, 0.5±0.1), Rect(3±0.2, -0.5±0.1)], identity))
    pp_cross_obs = Observable(FPlot([Rect(3±0.2, 0.5±0.1)], identity))
    pp_circle_obs = Observable(FPlot([Circle(Point2(-3.1, 0), 0.1)], identity))

    lp = lines!(ax, lp_obs)
    pp_vec = poly!(ax, pp_vec_obs)
    pp_cross = poly!(ax, pp_cross_obs)
    pp_circle = poly!(ax, pp_circle_obs)

    colorbuffer(fig)

    lp_child = only(lp.plots)
    pp_vec_child = only(pp_vec.plots)
    pp_cross_child = only(pp_cross.plots)
    pp_circle_child = only(pp_circle.plots)

    # verify splitting on initial data
    @test count(p -> any(isnan, p), lp_child[1][]) > 0
    @test pp_vec_child[1][] isa AbstractVector{<:MultiPolygon}
    @test length(pp_vec_child[1][][1].polygons) == 1
    @test length(pp_vec_child[1][][2].polygons) == 2
    @test pp_cross_child[1][] isa AbstractVector{<:MultiPolygon}
    @test length(pp_cross_child[1][][1].polygons) == 2
    @test pp_circle_child[1][] isa AbstractVector{<:MultiPolygon}
    @test length(pp_circle_child[1][][1].polygons) == 2

    # update: lines no longer cross boundary
    lp_obs[] = FPlot(map(x->(x/500, x/1000), 1:20:1000), identity)
    # update: swap crossing — first rect now crosses, second doesn't
    pp_vec_obs[] = FPlot([Rect(3±0.2, 0.5±0.1), Rect(0±0.2, -0.5±0.1)], identity)
    # update: single rect no longer crosses
    pp_cross_obs[] = FPlot([Rect(1±0.2, 0.5±0.1)], identity)
    # update: circle no longer crosses
    pp_circle_obs[] = FPlot([Circle(Point2(0.0, 0), 0.1)], identity)

    colorbuffer(fig)

    # child plots may have been replaced — re-fetch
    lp_child = only(lp.plots)
    pp_vec_child = only(pp_vec.plots)
    pp_cross_child = only(pp_cross.plots)
    pp_circle_child = only(pp_circle.plots)

    # verify updated splitting
    @test count(p -> any(isnan, p), lp_child[1][]) == 0  # no crossing now
    @test pp_vec_child[1][] isa AbstractVector{<:MultiPolygon}
    @test length(pp_vec_child[1][][1].polygons) == 2  # first rect now crosses
    @test length(pp_vec_child[1][][2].polygons) == 1  # second rect doesn't cross
    @test pp_cross_child[1][] isa AbstractVector{<:MultiPolygon}
    @test length(pp_cross_child[1][][1].polygons) == 1  # no longer crosses
    @test pp_circle_child[1][] isa AbstractVector{<:MultiPolygon}
    @test length(pp_circle_child[1][][1].polygons) == 1  # no longer crosses
end

@testitem "geoaxis splitting" begin
    import GeoMakie
    using GeoMakie: GeoAxis
    using MakieExtra.IntervalSets
    using MakieExtra.GeometryBasics: MultiPolygon, MultiLineString, Polygon, LineString, coordinates
    import CairoMakie

    ext = Base.get_extension(MakieExtra, :GeoMakieExt)
    split_curve = ext.split_curve

    # split_curve: open, no crossing — identity
    @test split_curve(Point2.([(1.,0), (2.,1)]), rng=0±π, closed=false) == [Point2.([(1.,0), (2.,1)])]

    # split_curve: open, single crossing — 2 segments with boundary points
    @test split_curve(Point2.([(1.,0), (4.,1)]), rng=0±π, closed=false) ≈ [
        Point2.([[1.0, 0.0], [π, 0.7138642029621032]]),
        Point2.([[π, 0.7138642327644256], [4.0, 1.0]]),
    ]

    # split_curve: open, many points — no spurious boundary at start (regression test)
    r = split_curve(Point2.(map(x -> (x, 0.1x), range(0, 3.5, 10))), rng=0±π, closed=false)
    @test length(r) == 2
    @test r[1][1] ≈ Point2(0., 0.)
    @test r[2][end] ≈ Point2(3.5, 0.35)

    # split_curve: closed, no crossing — identity
    @test split_curve(Point2.([(0.,0), (1.,0), (1.,1), (0.,1)]), rng=0±π, closed=true) == [Point2.([(0.,0), (1.,0), (1.,1), (0.,1)])]

    # split_curve: closed, single crossing — 2 segments, first/last merged
    r = split_curve(Point2.([(2.8,0.), (3.5,0.), (3.5,1.), (2.8,1.)]), rng=0±π, closed=true)
    @test length(r) == 2
    @test isapprox(r[1], Point2.([[π,1], [2.8,1], [2.8,0], [π,0]]), atol=0.001)
    @test isapprox(r[2], Point2.([[π,0], [3.5,0], [3.5,1], [π,1]]), atol=0.001)

    # postprocess_plotargs integration tests
    MakieExtra.GeoAxis_radians!()
    MakieExtra.GeoAxis_splitwrap!()
    fig = Figure()
    ax = GeoAxis(fig[1,1], dest="+proj=moll")
    pp = ext.postprocess_plotargs

    ## Lines: no crossing — unchanged
    r = pp(ax, Makie.Lines, Point2.([(0., 0), (1., 1), (2., 0.5)]))
    @test r == (Point2.([(0., 0), (1., 1), (2., 0.5)]),)

    ## Lines: single crossing — NaN-separated
    r = pp(ax, Makie.Lines, Point2.([(1., 0), (4., 1)]))
    @test isapprox(r[1], Point2.([
        [1, 0], [π, 0.714],
        [NaN, NaN],
        [π, 0.714], [4, 1],
    ]), nans=true, atol=0.001)

    ## Lines: multiple crossings — 3 segments
    r = pp(ax, Makie.Lines, Point2.([(2., 0), (5., 1), (9., 0.5)]))
    @test isapprox(r[1], Point2.([
        [2, 0], [π, 0.381],
        [NaN, NaN],
        [π, 0.381], [5, 1], [π, 0.593],
        [NaN, NaN],
        [3π, 0.593], [9, 0.5],
    ]), nans=true, atol=0.001)

    ## Poly: Rect crossing π — split into 2 polygons
    polycoords(r) = map(coordinates, r[1].polygons)
    r = pp(ax, Makie.Poly, Rect(3±0.2, 0.5±0.1))
    @test r[1] isa MultiPolygon
    @test isapprox(polycoords(r), [
        Point2.([ [π,0.6], [2.8,0.6], [2.8,0.4], [π,0.4] ]),
        Point2.([ [π,0.4], [3.2,0.4], [3.2,0.6], [π,0.6] ]),
    ], atol=0.001)

    ## Poly: vector — mix of crossing and non-crossing
    r = pp(ax, Makie.Poly, [Rect(0±0.2, 0.5±0.1), Rect(3±0.2, -0.5±0.1)])
    @test r[1] isa AbstractVector{<:MultiPolygon}
    @test length(r[1][1].polygons) == 1
    @test isapprox(map(coordinates, r[1][2].polygons), [
        Point2.([ [π,-0.4], [2.8,-0.4], [2.8,-0.6], [π,-0.6] ]),
        Point2.([ [π,-0.6], [3.2,-0.6], [3.2,-0.4], [π,-0.4] ]),
    ], atol=0.001)
end
