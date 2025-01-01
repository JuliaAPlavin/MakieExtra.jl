@recipe Contourf_Fast (X,) begin
    levels = 10
    colormap = @inherit colormap
    extendlow = nothing
    extendhigh = nothing
    nan_color = :transparent
    Makie.MakieCore.mixin_generic_plot_attributes()...
end

function Makie.plot!(p::Contourf_Fast)
    levels_c = @lift Makie._get_isoband_levels(Val(:normal), $(p.levels), $(p.X))
    colorrange = @lift extrema($levels_c)
    colormap_c = @lift Makie.compute_contourf_colormap($levels_c, $(p.colormap), $(p.extendlow), $(p.extendhigh))
    X_c = @lift map($(p.X)) do x
        if x < $colorrange[1]
            isnothing($(p.extendlow)) ? oftype(x, NaN) : oftype(x, -Inf)
        elseif x > $colorrange[2]
            isnothing($(p.extendhigh)) ? oftype(x, NaN) : oftype(x, +Inf)
        else
            x
        end
    end
    attrs = @p let
        p.attributes
        @delete __[:levels]
        @delete __[:extendlow]
        @delete __[:extendhigh]
        @insert __[:colormap] = colormap_c
        @insert __[:colorrange] = colorrange
        @insert __[:lowclip] = @lift isnothing($(p.extendlow)) ? nothing : Makie.compute_lowcolor($(p.extendlow), $(p.colormap))
        @insert __[:highclip] = @lift isnothing($(p.extendhigh)) ? nothing : Makie.compute_highcolor($(p.extendhigh), $(p.colormap))
    end
    image!(p, attrs, X_c)
end

Makie.needs_tight_limits(c::Contourf_Fast) = true

function Makie.plot!(ax::Makie.AbstractAxis, plot::Contourf_Fast)
    PT = typeof(plot)
    @invoke plot!(ax, plot::supertype(PT))
    applicable(fill!, ax, only(plot.plots)) && fill!(ax, only(plot.plots))
end
