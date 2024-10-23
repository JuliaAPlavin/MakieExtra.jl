struct FPlot
	data
	argfuncs::Tuple
	kwargfuncs::NamedTuple
	axis::NamedTuple
end
@batteries FPlot

FPlot(data, argfuncs...; axis::NamedTuple=(;), kwargsfuncs...) = FPlot(data, argfuncs, NamedTuple(kwargsfuncs), axis)

@accessor Base.values(X::FPlot) = X.data
Accessors.delete(X::FPlot, ::typeof(values)) = @set X.data = nothing
Accessors.insert(X::FPlot, ::typeof(values), v) = (@assert isnothing(X.data); @set X.data = v)

Base.getindex(X::FPlot, i::Int) = X.argfuncs[i]
Base.getindex(X::FPlot, i::Symbol) = X.kwargfuncs[i]
Base.setindex(X::FPlot, v, i::Int) = @set X.argfuncs[i] = v
Base.setindex(X::FPlot, v, i::Symbol) = @set X.kwargfuncs[i] = v

Base.getproperty(X::FPlot, i::Symbol) = hasfield(typeof(X), i) ? getfield(X, i) : X.kwargfuncs[i]
Base.propertynames(X::FPlot) = (fieldnames(typeof(X))..., keys(X.kwargfuncs)...)
function Accessors.setproperties(X::FPlot, patch::NamedTuple)
	fnames = Tuple(fieldnames(typeof(X)) ∩ keys(patch))
	fields = (;
		getproperties(X)...,
		patch[fnames]...,
		kwargfuncs = merge(X.kwargfuncs, get(patch, :kwargfuncs, (;)), @delete patch[fnames]),
	)
	@assert keys(fields) == fieldnames(typeof(X))
	FPlot(fields...)
end
Accessors.insert(X::FPlot, p::PropertyLens, v) = @insert X.kwargfuncs |> p = v
Accessors.insert(X::FPlot, p::IndexLens, v) = @insert X.argfuncs |> p = v

Makie.used_attributes(T::Type{<:Plot}, ::FPlot) = (:doaxis, :_axis, :reorder_args, Makie.attribute_names(T)...)
Makie.used_attributes(T::Type{<:Plot}, _, ::FPlot) = (:doaxis, :_axis, :reorder_args, Makie.attribute_names(T)...)

Makie.convert_arguments(ct::Type{<:AbstractPlot}, data, X::FPlot; kwargs...) = Makie.convert_arguments(ct, (@set X.data = data); kwargs...)

function Makie.convert_arguments(ct::Type{<:AbstractPlot}, X::FPlot; doaxis=false, _axis=(;), reorder_args=true, kwargs...)
	@assert !isnothing(X.data)
	pargs = map(argfuncs_for_plotargs(ct, X; reorder_args, kwargs...)) do f
		getval(f, X.data)
	end
	pkws_keys = Tuple(keys(X.kwargfuncs) ∩ Makie.attribute_names(ct))
	pkws = map(X.kwargfuncs[pkws_keys]) do f
		getval(f, X.data)
	end
	pspec = Makie.to_plotspec(ct, pargs; pkws..., kwargs...)
	if doaxis
		S = Makie.SpecApi
		# can set axis attributes (eg xylabels), but cannot be plotted on existing axes
		S.GridLayout([S.Axis(plots=[pspec]; axis_attributes(ct, X, (;kwargs..., reorder_args))..., _axis...)])
	else
		# can be plotted either from scratch or on existing axes, but cannot set axis attributes
		pspec
	end
end

axis_attributes(ct, X::FPlot, kwargs) = (; xlabel=_xlabel(ct, X, kwargs), ylabel=_ylabel(ct, X, kwargs), X.axis...)

@inline getval(f, data) = convert_to_makie(map(f, data))
@inline getval(f::Ref, data) = f[]

convert_to_makie(x) = x
convert_to_makie(x::AbstractArray{<:Union{String,Symbol}}) = Categorical(x)

_xlabel(ct, X::FPlot, kwargs) = _xylabel(ct, X, kwargs, 1)
_ylabel(ct, X::FPlot, kwargs) = _xylabel(ct, X, kwargs, 2)
function _xylabel(ct, X::FPlot, kwargs, i)
	afuncs = argfuncs_for_xy(ct, X; kwargs...)
	afunc = isnothing(afuncs) ? nothing : get(afuncs, i, nothing)
	return shortlabel(afunc)
end


# reorder if reorder_args == true, otherwise original order
argfuncs_for_plotargs(ct, X::FPlot; reorder_args::Bool, kwargs...) =
	if reorder_args
		ixs = argixs_xy_axes(ct, X, kwargs)
		if isnothing(ixs)
			# default behavior if argixs_xy_axes is not defined
			X.argfuncs
		elseif maximum(ixs) ≤ length(X.argfuncs)
			# reorder args according to argixs_xy_axes
			X.argfuncs[collect(ixs)]
		else
			# got fewer args than argixs_xy_axes expects, use args as-is
			# this handles stuff like scatter() and many others with a single argument
			X.argfuncs
		end
	else
		X.argfuncs
	end

# original order if reorder_args == true, otherwise reorder
function argfuncs_for_xy(ct, X::FPlot; reorder_args::Bool, kwargs...)
	argixs = argixs_xy_axes(ct, X, kwargs)
	if !isnothing(argixs) && !all(∈(eachindex(X.argfuncs)), argixs)
		# got fewer args than argixs_xy_axes expects, likely something unusual like scatter() and many others with a single argument
		return nothing
	end
	ixs = if isnothing(argixs)
		# default behavior if argixs_xy_axes is not defined
		X.argfuncs
	elseif reorder_args
		# argfuncs in the original order, but only those present in argixs
		map(1:maximum(argixs)) do i
			i ∈ argixs ? X.argfuncs[i] : nothing
		end
	else
		# argfuncs reordered according to argixs
		X.argfuncs[collect(argixs)]
	end
end


argixs_xy_axes(ct, X::FPlot, kwargs) = nothing
argixs_xy_axes(::Type{<:VLines}, X::FPlot, kwargs) = (1,)
argixs_xy_axes(::Type{<:HLines}, X::FPlot, kwargs) = (2,)
argixs_xy_axes(::Type{<:Union{BarPlot,Errorbars,Rangebars}}, X::FPlot, kwargs) = get(kwargs, :direction, :y) == :x ? (2, 1) : (1, 2)
argixs_xy_axes(::Type{<:Hist},    X::FPlot, kwargs) = get(kwargs, :direction, :y) == :x ? (2,) : (1,)
argixs_xy_axes(::Type{<:Density}, X::FPlot, kwargs) = get(kwargs, :direction, :y) == :x ? (1,) : (2,)

shortlabel(::Nothing) = ""
function shortlabel(f)
	o, unit = _split_unit(f)
	ostr = AccessorsExtra.barebones_string(o)
	isnothing(unit) ? ostr : "$ostr ($unit)"
end

_split_unit(o) = (o, nothing)
_split_unit(::typeof(rad2deg)) = (identity, "°")
function _split_unit(o::ComposedFunction)
    oshow, unit = _split_unit(o.outer)
    (_stripidentity(oshow ∘ o.inner), unit)
end

_stripidentity(o::ComposedFunction) = @delete Accessors.decompose(o) |> filter(==(identity))
_stripidentity(o) = o

# XXX: upstream cleaner version!
Makie.plot!(ax::Axis, plot::Plot{plot, Tuple{Makie.GridLayoutSpec}}) = plotlist!(ax, plot.converted[][].content[].second.plots[])
