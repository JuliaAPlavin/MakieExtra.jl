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

include("makieconvert.jl")
include("axisorder.jl")

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
