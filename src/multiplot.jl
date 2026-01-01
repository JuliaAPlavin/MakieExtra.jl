"""    multiplot([pos], plts, args...; kwargs...)

Make multiple plots with the same data.

Any combination of `plts` that take the same data is supported.
Common examples include:
- `(lines, band)`,
- `(scatter, rangebars)`,
- `(scatter, rangebars, rangebars => (;direction=:x))`
"""
function multiplot end

"""    multiplot!([ax], plts, args...; kwargs...)

Like `multiplot`, but plots on an existing axis.
"""
function multiplot! end

function multiplot!(plts, args...; kwargs...)
    map(plts) do plt
        plotfunc!(plt)(args...; keep_attrs(plt, kwargs, args...)...)
    end
end

function multiplot!(ax::Axis, plts, args...; kwargs...)
    map(plts) do plt
        plotfunc!(plt)(ax, args...; keep_attrs(plt, kwargs, args...)...)
    end
end

function multiplot(plts, args...; kwargs...)
    plt = first(plts)
    firstres = plotfunc(plt)(args...; keep_attrs(plt, kwargs, args...)..., (haskey(kwargs, :axis) ? (;axis=kwargs[:axis]) : (;))...)
    
    tailres = map(Base.tail(plts)) do plt
        plotfunc!(plt)(args...; keep_attrs(plt, kwargs, args...)...)
    end
    return (firstres, tailres...)
end

function multiplot(pos::Union{GridPosition, GridSubposition}, plts, args...; kwargs...)
    plt = first(plts)
    firstres = plotfunc(plt)(pos, args...; keep_attrs(plt, kwargs, args...)..., (haskey(kwargs, :axis) ? (;axis=kwargs[:axis]) : (;))...)
    
    tailres = map(Base.tail(plts)) do plt
        plotfunc!(plt)(args...; keep_attrs(plt, kwargs, args...)...)
    end
    return (firstres, tailres...)
end

keep_attrs(plt::Type{<:Plot}, kwargs, args...) = kwargs[collect(
    keys(kwargs) ∩ (
        Makie.attribute_names(plt) ∪
        Makie.MakieCore.attribute_name_allowlist() ∪
        used_attributes(plt, args...)
    )
)]
keep_attrs(plt::Function, kwargs, args...) = keep_attrs(func2type(plt), kwargs, args...)
keep_attrs((plt, _)::Pair, kwargs, args...) = keep_attrs(plt, kwargs, args...)
keep_attrs(plt::Axplot, kwargs, args...) = merge(keep_attrs(plt.plotf, kwargs, args...), kwargs[keys(kwargs) ∩ (:axis,)])

function plotfunc((F, kws)::Pair)
    F = plotfunc(F)
    (args...; newkwargs...) -> F(args...; newkwargs..., kws...)
end

function plotfunc!((F, kws)::Pair)
    F! = plotfunc!(F)
    (args...; newkwargs...) -> F!(args...; newkwargs..., kws...)
end

plotfunc(f::Axplot) = @modify(plotfunc, f.plotf)
plotfunc!(f::Axplot) = @modify(plotfunc!, f.plotf)
