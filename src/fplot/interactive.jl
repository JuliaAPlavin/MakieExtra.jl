abstract type FPlotAddon end

with_widgets(plotf, ws) = function (args...; kwargs...)
    plt = plotf(args...; kwargs...)
    fplt = filteronly(a -> a isa Union{FPlot,Observable{<:FPlot}}, args) |> to_value
    ax = if hasproperty(plt, :axis)
        plt.axis
    elseif !isempty(args) && args[1] isa Axis
        args[1]
    else
        current_axis()
    end
    for w in ws
        add!(ax, w, fplt, plt; kwargs...)
    end
    return plt
end

include("datacursor.jl")
include("rectselect.jl")
include("interactivepoints.jl")
