using TestItems
using TestItemRunner
@run_package_tests

@testitem "basic" begin
    fig = Figure(size=(1200, 300))
    xs = range(-10, 10, length=1000)
    
    series(fig[1,1], [
        (xs, mul .* xs)
        for mul in [1, 3, 10, 100]
    ], axis=(yscale=SymLog(1),))
    
    series(fig[1,2], [
        (xs, mul .* xs)
        for mul in [1, 3, 10, 100]
    ], axis=(yscale=AsinhScale(1),))
    
    ax, _ = lines(fig[1,3], xs, xs, axis=(xscale=SymLog(1), yscale=AsinhScale(1),))
    lines!(ax, [Point(0, 0), Point(1, 1)], color=:black, linestyle=:dash, space=:relative)
end


@testitem "_" begin
    import Aqua
    Aqua.test_all(MakieExtra; ambiguities=false, undefined_exports=false)

    import CompatHelperLocal as CHL
    CHL.@check()
end
