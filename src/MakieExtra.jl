module MakieExtra

using Reexport
using Accessors
using InverseFunctions
using PyFormattedStrings
using Makie: left, right, bottom, top, bottomleft, topleft, bottomright, topright
using Makie.IntervalSets
using Makie.IntervalSets: width
using Makie.Unitful
using DataPipes
import DataManipulation: shift_range

@reexport using Makie
export Makie

export SymLog, AsinhScale, BaseMulTicks, EngTicks, zoom_lines!

include("scales.jl")
include("ticks.jl")
include("scalebar.jl")
include("zoom_lines.jl")
include("helpers.jl")
include("axisfunction.jl")


# XXX: should upstream these!

function Accessors.set(attrs::Attributes, il::IndexLens, val)
	res = deepcopy(attrs)
	res[only(il.indices)] = val
	return res
end

Base.:(⊆)(a::Rect2, b::Rect2) = xint(a) ⊆ xint(b) && yint(a) ⊆ yint(b)

shift_range(p::T, (r1, r2)::Pair{<:Rect2,<:Rect2}) where {T<:Point2} = T(
	shift_range(p[1], xint(r1) => xint(r2)),
	shift_range(p[2], yint(r1) => yint(r2)),
)

end
