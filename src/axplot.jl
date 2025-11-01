struct Axplot
    plotf::Function
    widgets::Vector
    autolimits_refresh::Bool
end

axplot(plotf::Function; widgets=[], autolimits_refresh=false) = Axplot(plotf, widgets, autolimits_refresh)

function (axp::Axplot)(pos::Union{GridPosition, GridSubposition}, args...; axis=(;), kwargs...)
    @assert !haskey(kwargs, :doaxis) && !haskey(kwargs, :_axis)
    axis = merge(
        axis_attributes(plotfunc(axp.plotf), args..., kwargs),
        axis
    )

    axplt = axp.plotf(pos, args...; kwargs..., axis)
    fplt = filteronly(a -> a isa Union{FPlot,Observable{<:FPlot}}, args) |> to_value
    ax = axplt.axis
    for w in axp.widgets
        add!(ax, w, fplt, axplt.plot; kwargs...)
    end

    if axp.autolimits_refresh
        on(args...) do _
            reset_limits!(ax)
        end
    end
    axplt
end

function (axp::Axplot)(ax::Axis, args...; axis=(;), kwargs...)
    @assert !haskey(kwargs, :doaxis) && !haskey(kwargs, :_axis)
    axis = merge(
        axis_attributes(plotfunc(axp.plotf), args..., kwargs),
        axis
    )
    for (k, v) in pairs(axis)
        if v isa Observable
            map!(identity, getproperty(ax, k), v)
        else
            getproperty(ax, k)[] = v
        end
    end
    
    plt = axp.plotf(ax, args...; kwargs...)
    fplt = filteronly(a -> a isa Union{FPlot,Observable{<:FPlot}}, args) |> to_value
    for w in axp.widgets
        add!(ax, w, fplt, plt; kwargs...)
    end

    if axp.autolimits_refresh
        on(args...) do _
            reset_limits!(ax)
        end
    end
    plt
end

function (axp::Axplot)(args...; figure=(;), kwargs...)
    if endswith(string(nameof(axp.plotf)), "!")
        return axp(current_axis(), args...; kwargs...)
    else
        fig = Figure(;figure...)
        ax, plot = axp(fig[1,1], args...; kwargs...)
        return Makie.FigureAxisPlot(fig, ax, plot)
    end
end
