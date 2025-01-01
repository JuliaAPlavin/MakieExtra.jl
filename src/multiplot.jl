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
keep_attrs(plt::Function, kwargs, args...) = keep_attrs(Plot{plt}, kwargs, args...)
keep_attrs((plt, _)::Pair, kwargs, args...) = keep_attrs(plt, kwargs, args...)
keep_attrs(plt::AxplotFunc, kwargs, args...) = keep_attrs(plt.plotf, kwargs, args...)

function plotfunc((F, kws)::Pair)
    F = plotfunc(F)
    (args...; newkwargs...) -> F(args...; newkwargs..., kws...)
end

plotfunc(f::AxplotFunc) = f

function plotfunc!((F, kws)::Pair)
    F! = plotfunc!(F)
    (args...; newkwargs...) -> F!(args...; newkwargs..., kws...)
end
