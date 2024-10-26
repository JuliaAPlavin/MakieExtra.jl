using TestItems
using TestItemRunner
@run_package_tests

@testitem "scales, ticks" begin
    fig = Figure(size=(1200, 300))
    xs = range(-10, 10, length=1000)
    
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

    # smoke tests to probee the actual inverse:
    Makie.ReversibleScale(SymLog(1))
    Makie.ReversibleScale(AsinhScale(1))
end

@testitem "scalebar" begin
    using MakieExtra.Unitful

    X = rand(100, 100)
    
	heatmap(X, axis=(aspect=DataAspect(),), alpha=0.1)
	scalebar!(0.15u"m")
	scalebar!(0.15u"m", position=Point2(0.8, 0.1), color=:black)
	scalebar!((0.15u"m", x -> "a $x b"), position=Point2(0.8, 0.1), color=:black)
	scalebar!((0.15, x -> "a $x b"), color=:black)
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
    scatter!(sin)
    scatter!(Observable(sin))
    band(x -> sin(x)..2sin(x))
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

@testitem "_" begin
    import Aqua
    Aqua.test_all(MakieExtra; ambiguities=false, undefined_exports=false, piracies=false, persistent_tasks=false)

    import CompatHelperLocal as CHL
    CHL.@check()
end
