function multiplot!(plts, args...; kwargs...)
	map(plts) do plt
		plotfunc!(plt)(args...; keep_attrs(plt, kwargs)...)
	end
end

function multiplot(plts, args...; kwargs...)
	plt = first(plts)
	firstres = plotfunc(plt)(args...; keep_attrs(plt, kwargs)...)
	
	tailres = map(Base.tail(plts)) do plt
		plotfunc!(plt)(args...; keep_attrs(plt, kwargs)...)
	end
    return (firstres, tailres...)
end

keep_attrs(plt::Type{<:Plot}, kwargs) = kwargs[collect(keys(kwargs) ∩ Makie.attribute_names(plt))]
keep_attrs(plt::Function, kwargs) = keep_attrs(Plot{plt}, kwargs)

plotfunc(::Type{<:Plot{F}}) where {F} = F
plotfunc(F::Function) = F

function plotfunc!(P)
	F = plotfunc(P)
	return eval(Symbol(nameof(F), :!))
end
