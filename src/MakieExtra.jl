module MakieExtra

using Reexport
using AccessorsExtra
using InverseFunctions
using PyFormattedStrings
using Makie: left, right, bottom, top, bottomleft, topleft, bottomright, topright
using Makie.MakieCore: documented_attributes
using Makie.IntervalSets
using Makie.IntervalSets: width
using Makie.Unitful
using DataPipes
import DataManipulation: shift_range
using StructHelpers

@reexport using Makie
export Makie

export 
	SymLog, AsinhScale,
	BaseMulTicks, EngTicks,
	zoom_lines!,
	marker_lw,
	to_x_attrs, to_y_attrs, to_xy_attrs,
	multiplot, multiplot!,
	FPlot,
	changes

include("lift.jl")
include("scales.jl")
include("ticks.jl")
include("helpers.jl")
include("scalebar.jl")
include("zoom_lines.jl")
include("contourf.jl")
include("markers.jl")
include("glow.jl")
include("bandstroke.jl")
include("axisfunction.jl")
include("arrowline.jl")
include("multiplot.jl")
include("fplot/fplot.jl")


to_x_attrs(attrs) = @modify(k -> Symbol(:x, k), keys(attrs)[∗])
to_y_attrs(attrs) = @modify(k -> Symbol(:y, k), keys(attrs)[∗])
to_xy_attrs(attrs) = merge(to_x_attrs(attrs), to_y_attrs(attrs))


function __init__()
	if ccall(:jl_generating_output, Cint, ()) != 1
		# to support SpecApi
		Core.eval(Makie, Expr(:global, :BandStroke))
		Makie.BandStroke = BandStroke

		Core.eval(Makie, Expr(:global, :LinesGlow))
		Makie.LinesGlow = LinesGlow
	end
end

# XXX: should upstream these!


# https://github.com/JuliaGizmos/Observables.jl/pull/115
"""
     changes(obs::AbstractObservable)

Returns an `Observable` that only forwards `obs` updates when its value changes.
"""
function changes(obs::Makie.AbstractObservable{T}) where {T}
	result = Observable{T}(obs[])
    oldobs = Observable{T}(obs[])
	on(obs) do val
		if val != oldobs[]
			result[] = val
			oldobs[] = val
		end
	end
	return result
end


# https://github.com/MakieOrg/Makie.jl/pull/4037
# Base.setindex(x::Attributes, value, key::Symbol) = merge(Attributes(; NamedTuple{(key,)}((value,))...), x)
function Base.setindex(x::Attributes, value::Observable, key::Symbol)
	y = copy(x)
	y[key] = value
	return y
end
Base.setindex(x::Attributes, value, key::Symbol) = Base.setindex(x, Observable(value), key)

function Accessors.insert(attrs::Attributes, il::IndexLens, val)
	res = copy(attrs)
	res[only(il.indices)] = val
	return res
end

function Accessors.delete(attrs::Attributes, il::IndexLens)
	res = copy(attrs)
	delete!(res, only(il.indices))
	return res
end


function Makie.convert_arguments(P::Type{<:Union{Band,BandStroke,Rangebars}}, i::AbstractInterval, f::Function)
    x, y = Makie.PlotUtils.adapted_grid(x -> Makie.mean(f(x)), endpoints(i))
    return convert_arguments(P, x, f.(x))
end


Base.:(⊆)(a::Rect2, b::Rect2) = xint(a) ⊆ xint(b) && yint(a) ⊆ yint(b)

shift_range(p::T, (r1, r2)::Pair{<:Rect2,<:Rect2}) where {T<:Point2} = T(
	shift_range(p[1], xint(r1) => xint(r2)),
	shift_range(p[2], yint(r1) => yint(r2)),
)


# XXX: hack, ignore kwargs that Makie erroneously propagates
# this is very low-specificity method that should only trigger when no kwargs-accepting methods exist
# this method is relied upon in, for example, VLBIPlots.jl
Makie.convert_arguments(args...; kwargs...) = isempty(kwargs) ? throw(MethodError(convert_arguments, args)) : convert_arguments(args...)

end
