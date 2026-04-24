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
    ax = axplt.axis
    if any(is_fplot_like, args)
        fplt = filteronly(is_fplot_like, args) |> to_value
        for w in axp.widgets
            add!(ax, w, fplt, axplt.plot; kwargs...)
        end
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
    keys_toset_after = Set([:xscale, :yscale, :zscale, :xticks, :yticks, :zticks])
    for (k, v) in pairs(axis)
        k ∈ keys_toset_after && continue
        if v isa MyObservables.AbstractNode
            effect!(MyObservables.runtime(v)) do
                getproperty(ax, k)[] = v[]
            end
        elseif v isa Observable
            map!(identity, getproperty(ax, k), v)
        else
            getproperty(ax, k)[] = v
        end
    end

    plt = axp.plotf(ax, args...; kwargs...)
    if any(is_fplot_like, args)
        fplt = filteronly(is_fplot_like, args) |> to_value
        for w in axp.widgets
            add!(ax, w, fplt, plt; kwargs...)
        end
    end

    for (k, v) in pairs(axis)
        k ∈ keys_toset_after || continue
        if v isa MyObservables.AbstractNode
            effect!(MyObservables.runtime(v)) do
                getproperty(ax, k)[] = v[]
            end
        elseif v isa Observable
            map!(identity, getproperty(ax, k), v)
        else
            getproperty(ax, k)[] = v
        end
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
