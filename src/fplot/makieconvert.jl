Makie.used_attributes(T::Type{<:Plot}, ::FPlot) = (:reorder_args, intersect(Makie.attribute_names(T), (:direction,))...)
Makie.used_attributes(T::Type{<:Plot}, _, fplt::FPlot) = Makie.used_attributes(T, fplt)

Makie.convert_arguments(ct::Type{<:AbstractPlot}, data, X::FPlot; kwargs...) = Makie.convert_arguments(ct, (@set X.data = data); kwargs...)


_lab_to_textprops(x) = string(x) => (;)
_lab_to_textprops(x::AbstractString) = x => (;)
_lab_to_textprops(x::Pair) = x

function Makie.convert_arguments(ct::Type{<:AbstractPlot}, X::FPlot; reorder_args=true, kwargs...)
    @assert !isnothing(X.data)
	categ_kwargfuncs = filter(f -> f isa AsCategorical, X.kwargfuncs)
	if !isempty(categ_kwargfuncs)
		categ_kwargfunc = only(categ_kwargfuncs)
		map(group_vg(categ_kwargfunc.f, X.data) |> collect) do gr
			curX = @p let
				X
				@set __.data = value(gr)
				@delete __[keys(categ_kwargfuncs)]
			end
			lab = categ_kwargfunc.label(key(gr))
			labtext, labprops = _lab_to_textprops(lab)
			convert_arguments(ct, curX; reorder_args, label="$(labtext)" => labprops, kwargs...)
		end
	else
	    pargs = map(argfuncs_for_plotargs(ct, X; reorder_args, kwargs...)) do f
	        getval(X.data, f) |> convert_to_categorical_if_needed
	    end
	    anames = Makie.attribute_names(ct)
	    pkws_keys = Tuple(keys(X.kwargfuncs) ∩ anames)
	    pkws = map(NamedTuple{pkws_keys}(pkws_keys), X.kwargfuncs[pkws_keys]) do k, f
	        getval(X.data, k, f)
	    end
	    pkws_extra = @p pairs(X.kwargfuncs) collect flatmap(((k,v),) -> extra_plot_kwargs(k, v))
	    pkws_attrs = if haskey(X.kwargfuncs, :_attrs)
	        @assert :_attrs ∉ anames
	        vals = getval(X.data, nothing, X.kwargfuncs._attrs)
	        getproperties(StructArray(vals))
	    else
	        (;)
	    end
	    pspec = Makie.to_plotspec(ct, pargs; pkws..., pkws_extra..., pkws_attrs..., kwargs...)
	end
end

# disambiguation:
Makie.convert_arguments(ct::Type{<:Makie.Text}, fplt::FPlot) = @invoke convert_arguments(ct::Type{<:AbstractPlot}, fplt)

@inline getval(data, f) = getval(data, nothing, f)
@inline getval(data, k, f::Symbol) =
	k ∈ (:color, :colormap, :direction) ? f :  # attributes that commonly have Symbol values – for them, interpret Symbol as actual value, not property accessor
	map(f, data)
@inline getval(data, k, f) =
    isempty(methods(f)) ? f :
    k == :inspector_label ? (self, i, p) -> f(data[i]) :
    k == :inspector_hover ? (self, p, i, _...) -> f(data[i]) :
    map(f, data)
@inline getval(data, _, f::Ref) = f[]

convert_to_categorical_if_needed(x) = x
convert_to_categorical_if_needed(x::AbstractArray{<:Union{
    AbstractString,Symbol,
    NTuple{<:Any,AbstractString},NTuple{<:Any,Symbol},
}}) = Categorical(x)


function axis_attributes(ct, X::FPlot, kwargs)
    afuncs = argfuncs_for_xy(ct, X; kwargs...)
    merge_non_nothing(
        merge_axis_kwargs(
            (@oget to_x_attrs(ax_attrs_from_func(afuncs[1]))),
            (@oget to_y_attrs(ax_attrs_from_func(afuncs[2]))),
        ),
        X.axis,
    )
end


function axis_attributes(ct, X::Observable{<:FPlot}, kwargs) 
    result_obs = @lift let
        afuncs = argfuncs_for_xy(ct, $X; kwargs...)
        merge_non_nothing(
            merge_axis_kwargs(
                (@oget to_x_attrs(ax_attrs_from_func(afuncs[1]))),
                (@oget to_y_attrs(ax_attrs_from_func(afuncs[2]))),
            ),
            $X.axis,
        )
    end::Any
    result = map(Observable{Any}, result_obs[])::NamedTuple
    on(result_obs) do new_attrs
        for (k, v) in pairs(new_attrs)
            result[k][] = v
        end
    end
    return result
end
