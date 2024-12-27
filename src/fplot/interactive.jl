abstract type FPlotAddon end

add!(addon::FPlotAddon, fplt::FPlot, plt::Type{<:Plot}; kwargs...) = add!(current_axis(), addon, fplt, plt; kwargs...)

with_widgets(plotf, ws) = function (args...; kwargs...)
    result = plotf(args...; kwargs...)
    fplt = filteronly(a -> a isa FPlot, args)
    plt = func2type(plotf)
    for w in ws
        add!(w, fplt, plt; kwargs...)
    end
    return result
end

include("datacursor.jl")
include("rectselect.jl")
