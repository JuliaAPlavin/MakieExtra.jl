struct FPlot
	data
	argfuncs
	kwargfuncs
end

FPlot(data, argfuncs...; kwargsfuncs...) = FPlot(data, argfuncs, NamedTuple(kwargsfuncs))

Makie.used_attributes(T::Type{<:Plot}, ::FPlot) = (:doaxis, Makie.attribute_names(T)...)
Makie.used_attributes(T::Type{<:Plot}, _, ::FPlot) = (:doaxis, Makie.attribute_names(T)...)

Makie.convert_arguments(ct::Type{<:AbstractPlot}, data, X::FPlot; kwargs...) = Makie.convert_arguments(ct, (@set X.data = data); kwargs...)

function Makie.convert_arguments(ct::Type{<:AbstractPlot}, X::FPlot; doaxis=false, kwargs...)
	@assert !isnothing(X.data)
	pargs = map(X.argfuncs) do f
		getval(f, X.data)
	end
	pkws = map(X.kwargfuncs) do f
		getval(f, X.data)
	end
	pspec = Makie.to_plotspec(ct, pargs; pkws..., kwargs...)
	if doaxis
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
