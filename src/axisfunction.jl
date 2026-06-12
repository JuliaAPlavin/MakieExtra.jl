for plotf in (
        :scatter, :lines, :scatterlines,
        :stairs, :stem,
        :errorbars, :rangebars, :band,
        :barplot,
        :linesglow)
    plotf_excl = Symbol(plotf, :!)
    fullname_excl = isdefined(Makie, plotf) ? :(Makie.$plotf_excl) : :($(@__MODULE__).$plotf_excl)
    
    @eval $fullname_excl(f::Union{Function,Observable{<:Function}}; kwargs...) = $plotf_excl(current_axis(), f; kwargs...)

    @eval function $fullname_excl(ax::Axis, f::Union{Function,Observable{<:Function}}; kwargs...)
        interval = lift(l -> intervals(l).x, ax.finallimits)
        $plotf_excl(ax, interval, f; merge((; xautolimits=false), kwargs)...)
    end
end
