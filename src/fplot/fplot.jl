struct FPlot
	data
	argfuncs::Tuple
	kwargfuncs::NamedTuple
	axis::NamedTuple
end
@batteries FPlot

FPlot(data, argfuncs...; axis::NamedTuple=(;), kwargsfuncs...) = FPlot(data, argfuncs, NamedTuple(kwargsfuncs), axis)

Base.getindex(X::FPlot, i::Int) = X.argfuncs[i]
Base.getindex(X::FPlot, i::Symbol) = X.kwargfuncs[i]
Base.setindex(X::FPlot, v, i::Int) = @set X.argfuncs[i] = v
Base.setindex(X::FPlot, v, i::Symbol) = @set X.kwargfuncs[i] = v
Accessors.insert(X::FPlot, p::IndexLens, v) = 
	if all(i -> i isa Integer, p.indices)
		@insert X.argfuncs |> p = v
	else
		@insert X.kwargfuncs |> p = v
	end
Accessors.delete(X::FPlot, p::IndexLens) =
	if all(i -> i isa Integer, p.indices)
		@set X.argfuncs |> p = nothing
	else
		@delete X.kwargfuncs |> p
	end

Base.getproperty(X::FPlot, i::Symbol) = hasfield(typeof(X), i) ? getfield(X, i) : X.kwargfuncs[i]
Base.propertynames(X::FPlot) = (fieldnames(typeof(X))..., keys(X.kwargfuncs)...)
function Accessors.setproperties(X::FPlot, patch::NamedTuple)
	fnames = fieldnames(typeof(X))
	if keys(patch) ⊆ fnames
		FPlot(merge(getfields(X), patch)...)
	elseif isdisjoint(keys(patch), fnames)
		@modify(kws -> merge(kws, patch), X.kwargfuncs)
	else
		error("Cannot set both fields and kwarg-properties of FPlot at the same time")
	end
end
Accessors.insert(X::FPlot, p::PropertyLens, v) = @insert X.kwargfuncs |> p = v
Accessors.delete(X::FPlot, p::PropertyLens) = @delete X.kwargfuncs |> p

Accessors.delete(X::FPlot, ::PropertyLens{:data}) = @set X.data = nothing
Accessors.insert(X::FPlot, ::PropertyLens{:data}, v) = (@assert isnothing(X.data); @set X.data = v)

include("makieconvert.jl")
include("axisorder.jl")
include("interactive.jl")

# should go into AccessorsExtra?

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
