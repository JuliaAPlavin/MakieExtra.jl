Makie.used_attributes(T::Type{<:Plot}, ::FPlot) = (:doaxis, :_axis, :reorder_args, intersect(Makie.attribute_names(T), (:direction,))...)
Makie.used_attributes(T::Type{<:Plot}, _, fplt::FPlot) = Makie.used_attributes(T, fplt)

Makie.convert_arguments(ct::Type{<:AbstractPlot}, data, X::FPlot; kwargs...) = Makie.convert_arguments(ct, (@set X.data = data); kwargs...)

function Makie.convert_arguments(ct::Type{<:AbstractPlot}, X::FPlot; doaxis=false, _axis=(;), reorder_args=true, kwargs...)
	@assert !isnothing(X.data)
	pargs = map(argfuncs_for_plotargs(ct, X; reorder_args, kwargs...)) do f
		getval(f, X.data) |> convert_to_categorical_if_needed
	end
	pkws_keys = Tuple(keys(X.kwargfuncs) ∩ Makie.attribute_names(ct))
	pkws = map(X.kwargfuncs[pkws_keys]) do f
		getval(f, X.data)
	end
	pspec = Makie.to_plotspec(ct, pargs; pkws..., kwargs...)
	if doaxis
		S = Makie.SpecApi
		# can set axis attributes (eg xylabels), but cannot be plotted on existing axes
		S.GridLayout([S.Axis(plots=[pspec]; axis_attributes(ct, X, (;reorder_args, kwargs...))..., _axis...)])
	else
		# can be plotted either from scratch or on existing axes, but cannot set axis attributes
		pspec
	end
end

@inline getval(f, data) = map(f, data)
@inline getval(f::Ref, data) = f[]

convert_to_categorical_if_needed(x) = x
convert_to_categorical_if_needed(x::AbstractArray{<:Union{String,Symbol}}) = Categorical(x)

axis_attributes(ct, X::FPlot, kwargs) = (; xlabel=_xlabel(ct, X, kwargs), ylabel=_ylabel(ct, X, kwargs), X.axis...)

_xlabel(ct, X::FPlot, kwargs) = _xylabel(ct, X, kwargs, 1)
_ylabel(ct, X::FPlot, kwargs) = _xylabel(ct, X, kwargs, 2)
function _xylabel(ct, X::FPlot, kwargs, i)
	afuncs = argfuncs_for_xy(ct, X; kwargs...)
	afunc = isnothing(afuncs) ? nothing : get(afuncs, i, nothing)
	return shortlabel(afunc)
end
