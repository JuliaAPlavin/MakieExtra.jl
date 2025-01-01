Makie.used_attributes(T::Type{<:Plot}, ::FPlot) = (:reorder_args, intersect(Makie.attribute_names(T), (:direction,))...)
Makie.used_attributes(T::Type{<:Plot}, _, fplt::FPlot) = Makie.used_attributes(T, fplt)

Makie.convert_arguments(ct::Type{<:AbstractPlot}, data, X::FPlot; kwargs...) = Makie.convert_arguments(ct, (@set X.data = data); kwargs...)

function Makie.convert_arguments(ct::Type{<:AbstractPlot}, X::FPlot; reorder_args=true, kwargs...)
	@assert !isnothing(X.data)
	pargs = map(argfuncs_for_plotargs(ct, X; reorder_args, kwargs...)) do f
		getval(X.data, f) |> convert_to_categorical_if_needed
	end
	pkws_keys = Tuple(keys(X.kwargfuncs) ∩ Makie.attribute_names(ct))
	pkws = map(NamedTuple{pkws_keys}(pkws_keys), X.kwargfuncs[pkws_keys]) do k, f
		getval(X.data, k, f)
	end
	pspec = Makie.to_plotspec(ct, pargs; pkws..., kwargs...)
end

@inline getval(data, f) = getval(data, nothing, f)
@inline getval(data, k, f) =
	isempty(methods(f)) ? f :
	k == :inspector_label ? (self, i, p) -> f(data[i]) :
	map(f, data)
@inline getval(data, _, f::Ref) = f[]

convert_to_categorical_if_needed(x) = x
convert_to_categorical_if_needed(x::AbstractArray{<:Union{
	AbstractString,Symbol,
	NTuple{<:Any,AbstractString},NTuple{<:Any,Symbol},
}}) = Categorical(x)

axis_attributes(ct, X::FPlot, kwargs) = (; xlabel=_xlabel(ct, X, kwargs), ylabel=_ylabel(ct, X, kwargs), X.axis...)

_xlabel(ct, X::FPlot, kwargs) = _xylabel(ct, X, kwargs, 1)
_ylabel(ct, X::FPlot, kwargs) = _xylabel(ct, X, kwargs, 2)
function _xylabel(ct, X::FPlot, kwargs, i)
	afuncs = argfuncs_for_xy(ct, X; kwargs...)
	afunc = isnothing(afuncs) ? nothing : get(afuncs, i, nothing)
	return shortlabel(afunc)
end
