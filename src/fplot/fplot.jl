struct FPlot
    data
    argfuncs::Tuple
    kwargfuncs::NamedTuple
    axis::NamedTuple

    # to only have the constructor with correctly typed arguments, avoid auto convert attempts
    # when eg FPlot(data, f1, f2, f3) is passed
    function FPlot(data, argfuncs::Tuple, kwargfuncs::NamedTuple, axis::NamedTuple)
        @assert !(data isa FPlot)
        new(data, argfuncs, kwargfuncs, axis)
    end
end
@batteries FPlot

FPlot(data, argfuncs...; axis::NamedTuple=(;), kwargsfuncs...) = FPlot(data, argfuncs, NamedTuple(kwargsfuncs), axis)

FPlot(fplt::FPlot, args...; data=nothing, axis=(;), kwargs...) = FPlot(something(data, fplt.data), merge(fplt.argfuncs, args), merge(fplt.kwargfuncs, kwargs), merge_axis_kwargs(fplt.axis, axis))

const TUP_IX_TYPES = Union{Integer,NTuple{<:Any,<:Integer},AbstractVector{<:Integer}}
const NTUP_IX_TYPES = Union{Symbol,NTuple{<:Any,<:Symbol},AbstractVector{<:Symbol}}
Base.getindex(X::FPlot, i::TUP_IX_TYPES) = X.argfuncs[i]
Base.getindex(X::FPlot, i::NTUP_IX_TYPES) = X.kwargfuncs[i]
Base.setindex(X::FPlot, v, i::TUP_IX_TYPES) = @set X.argfuncs[i] = v
Base.setindex(X::FPlot, v, i::NTUP_IX_TYPES) = @set X.kwargfuncs[i] = v
Accessors.insert(X::FPlot, p::IndexLens, v) = 
    if all(i -> i isa TUP_IX_TYPES, p.indices)
        @insert X.argfuncs |> p = v
    elseif all(i -> i isa NTUP_IX_TYPES, p.indices)
        @insert X.kwargfuncs |> p = v
    else
        error("Cannot insert to FPlot at indices $(p.indices)")
    end
Accessors.delete(X::FPlot, p::IndexLens) =
    if all(i -> i isa TUP_IX_TYPES, p.indices)
        ix = only(p.indices)
        if minimum(ix) == length(X.argfuncs) - length(ix) + 1
            @delete X.argfuncs |> p
        else
            @set X.argfuncs |> p = nothing
        end
    elseif all(i -> i isa NTUP_IX_TYPES, p.indices)
        @delete X.kwargfuncs |> p
    else
        error("Cannot delete from FPlot at indices $(p.indices)")
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

include("axfuncs.jl")
include("makieconvert.jl")
include("axisorder.jl")
include("interactive.jl")


# XXX: upstream cleaner version!
Makie.plot!(ax::Axis, plot::Plot{plot, Tuple{Makie.GridLayoutSpec}}) = plotlist!(ax, plot.converted[][].content[].second.plots[])
