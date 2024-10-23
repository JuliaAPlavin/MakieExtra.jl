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

Makie.used_attributes(T::Type{<:Plot}, ::FPlot) = (:doaxis, Makie.attribute_names(T)...)
Makie.used_attributes(T::Type{<:Plot}, _, ::FPlot) = (:doaxis, Makie.attribute_names(T)...)

Makie.convert_arguments(ct::Type{<:AbstractPlot}, data, X::FPlot; kwargs...) = Makie.convert_arguments(ct, (@set X.data = data); kwargs...)

function Makie.convert_arguments(ct::Type{<:AbstractPlot}, X::FPlot; doaxis=false, kwargs...)
	@assert !isnothing(X.data)
	pargs = map(X.argfuncs) do f
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
		S.GridLayout([S.Axis(plots=[pspec]; axis_attributes(X)...)])
	else
		# can be plotted either from scratch or on existing axes, but cannot set axis attributes
		pspec
	end
end

# Makie.plot!(ax::Axis, plot::Plot{plot, Tuple{Makie.GridLayoutSpec}}) = plotlist!(ax, plot.converted[][].content[].second.plots[])

axis_attributes(X::FPlot) = (; xlabel=_xlabel(X), ylabel=_ylabel(X), X.axis...)

@inline getval(f, data) = map(f, data)
@inline getval(f::Ref, data) = f[]

_xlabel(X::FPlot) = shortlabel(X.argfuncs[1])
_ylabel(X::FPlot) = shortlabel(X.argfuncs[2])
shortlabel(f) = AccessorsExtra.barebones_string(f)
