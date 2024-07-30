struct FPlot
	data
	argfuncs
	kwargfuncs
	axis::Bool
end

FPlot(data, argfuncs...; axis=false, kwargsfuncs...) = FPlot(data, argfuncs, NamedTuple(kwargsfuncs), axis)

Makie.used_attributes(T::Type{<:Plot}, ::FPlot) = Tuple(Makie.attribute_names(T))

function Makie.convert_arguments(ct::Type{<:AbstractPlot}, X::FPlot; kwargs...)
	@assert !isnothing(X.data)
	pargs = map(X.argfuncs) do f
		getval(f, X.data)
	end
	pkws = map(X.kwargfuncs) do f
		getval(f, X.data)
	end
	pspec = Makie.to_plotspec(ct, pargs; pkws..., kwargs...)
	if X.axis
		S = Makie.SpecApi
		# can set axis attributes (eg xylabels), but cannot be plotted on existing axes
		S.GridLayout([S.Axis(plots=[pspec], xlabel=_xlabel(X), ylabel=_ylabel(X))])
	else
		# can be plotted either from scratch or on existing axes, but cannot set axis attributes
		pspec
	end
end

@inline getval(f, data) = map(f, data)
@inline getval(f::Ref, data) = f[]

_xlabel(X::FPlot) = shortlabel(X.argfuncs[1])
_ylabel(X::FPlot) = shortlabel(X.argfuncs[2])
shortlabel(f) = AccessorsExtra.barebones_string(f)
