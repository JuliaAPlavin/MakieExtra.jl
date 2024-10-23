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
    using CairoMakie, GLMakie

    fig, ax, plt = lines(FPlot(1:10, (@o _+1), (@o _^2), color=sqrt))
    lines!(FPlot(1:10, (@o _+1), (@o _^2), color=sqrt))
    @test content(fig[1,1]).xlabel[] == ""
    Makie.colorbuffer(current_figure(); backend=CairoMakie)
    Makie.colorbuffer(current_figure(); backend=GLMakie)

    fig, ax, plt = lines(FPlot(1:10, (@o _+1), (@o _^2), color=sqrt), doaxis=true)
    lines!(FPlot(1:10, (@o _/1), (@o _+2), color=sqrt), doaxis=true)
    @test content(fig[1,1]).xlabel[] == "+(_, 1)"
    Makie.colorbuffer(current_figure(); backend=CairoMakie)
    Makie.colorbuffer(current_figure(); backend=GLMakie)
end

@testitem "categorical" begin
    using Accessors

    lines(FPlot(1:10, string, (@o _^2), color=sqrt), doaxis=true)
    @test current_axis().xlabel[] == "string"
end

@testitem "unitful" begin
    using Accessors, Unitful

    lines(FPlot((1:10)u"m", (@o ustrip(u"cm", 2*_)), (@o ustrip(_^2))), doaxis=true)
    @test current_axis().xlabel[] == "*(2, _) (cm)"
    @test_broken current_axis().ylabel[] == "^(_, 2) (m^2)"
end

@testitem "flipped xy" begin
    using Accessors

    barplot(FPlot(1:10, (@o _), (@o _^2)), doaxis=true)
    @test current_axis().xlabel[] == "identity"
    @test current_axis().ylabel[] == "^(_, 2)"
    barplot(FPlot(1:10, (@o _), (@o _^2)), direction=:x, doaxis=true)
    @test current_axis().xlabel[] == "^(_, 2)"
    @test current_axis().ylabel[] == "identity"
end

@testitem "multiplot" begin
    using Accessors
    using CairoMakie, GLMakie

    res = multiplot((Scatter, Lines), FPlot(1:10, (@o _), (@o _^2)), doaxis=true)
    @test res[1] isa Makie.FigureAxisPlot
    ax = content(res[1].figure[:,:])
    @test ax.xlabel[] == "identity"
    @test ax.ylabel[] == "^(_, 2)"
    Makie.colorbuffer(current_figure(); backend=CairoMakie)
    Makie.colorbuffer(current_figure(); backend=GLMakie)
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
