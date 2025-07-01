abstract type FPlotAddon end

add!(addon::FPlotAddon, fplt::FPlot, plt::Plot; kwargs...) = add!(current_axis(), addon, fplt, plt; kwargs...)

with_widgets(plotf, ws) = function (args...; kwargs...)
    plt = plotf(args...; kwargs...)
    fplt = filteronly(a -> a isa Union{FPlot,Observable{<:FPlot}}, args) |> to_value
    for w in ws
        add!(w, fplt, plt; kwargs...)
    end
    return plt
end

include("datacursor.jl")
include("rectselect.jl")
include("interactivepoints.jl")
