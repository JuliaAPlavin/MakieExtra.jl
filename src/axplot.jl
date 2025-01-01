struct Axplot
    plotf::Function
    widgets::Vector
    autolimits_refresh::Bool
end

axplot(plotf::Function; widgets=[], autolimits_refresh=false) = Axplot(plotf, widgets, autolimits_refresh)

function (axp::Axplot)(pos::Union{GridPosition, GridSubposition}, args...; axis=(;), kwargs...)
    @assert !haskey(kwargs, :doaxis) && !haskey(kwargs, :_axis)
    axis = merge(
        axis_attributes(axp.plotf, to_value.(args)..., kwargs),
        axis
    )
    res = with_widgets(axp.plotf, axp.widgets)(pos, args...; kwargs..., axis)
    ax = current_axis()
    if axp.autolimits_refresh
        on(args...) do _
            reset_limits!(ax)
        end
    end
    res
end

function (axp::Axplot)(args...; figure=(;), kwargs...)
    fig = Figure(;figure...)
    ax, plot = axp(fig[1,1], args...; kwargs...)
    return Makie.FigureAxisPlot(fig, ax, plot)
end
