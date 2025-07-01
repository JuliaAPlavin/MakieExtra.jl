abstract type FPlotAddon end

add!(addon::FPlotAddon, fplt::FPlot, plt::Plot; kwargs...) = add!(current_axis(), addon, fplt, plt; kwargs...)

with_widgets(plotf, ws) = function (args...; kwargs...)
    depwarn("with_widgets is deprecated, use axplot instead", :with_widgets)
    result = plotf(args...; kwargs...)
    fplt = filteronly(a -> a isa Union{FPlot,Observable{<:FPlot}}, args) |> to_value
    plt = func2type(plotf)
    for w in ws
        add!(w, fplt, plt; kwargs...)
    end
    return result
end

include("datacursor.jl")
include("rectselect.jl")
include("interactivepoints.jl")
