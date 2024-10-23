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
	firstres = plotfunc(plt)(args...; keep_attrs(plt, kwargs, args...)...)
	
	tailres = map(Base.tail(plts)) do plt
		plotfunc!(plt)(args...; keep_attrs(plt, kwargs, args...)...)
	end
    return (firstres, tailres...)
end

function multiplot(pos::Union{GridPosition, GridSubposition}, plts, args...; kwargs...)
	plt = first(plts)
	firstres = plotfunc(plt)(pos, args...; keep_attrs(plt, kwargs, args...)...)
	
	tailres = map(Base.tail(plts)) do plt
		plotfunc!(plt)(args...; keep_attrs(plt, kwargs, args...)...)
	end
    return (firstres, tailres...)
end

keep_attrs(plt::Type{<:Plot}, kwargs, args...) = kwargs[collect(keys(kwargs) ∩ (Makie.attribute_names(plt) ∪ used_attributes(plt, args...)))]
keep_attrs(plt::Function, kwargs, args...) = keep_attrs(Plot{plt}, kwargs)
keep_attrs((plt, _)::Pair, kwargs, args...) = keep_attrs(plt, kwargs)

plotfunc(::Type{<:Plot{F}}) where {F} = F
plotfunc(F::Function) = F
function plotfunc((F, kws)::Pair)
	F = plotfunc(F)
	(args...; newkwargs...) -> F(args...; newkwargs..., kws...)
end

function plotfunc!(P)
	F = plotfunc(P)
	return eval(Symbol(nameof(F), :!))
end
function plotfunc!((F, kws)::Pair)
	F! = plotfunc!(F)
	(args...; newkwargs...) -> F!(args...; newkwargs..., kws...)
end
