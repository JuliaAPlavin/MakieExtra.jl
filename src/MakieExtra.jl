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

export SymLog, AsinhScale, BaseMulTicks, EngTicks, zoom_lines!, to_x_attrs, to_y_attrs, to_xy_attrs

include("lift.jl")
include("scales.jl")
include("ticks.jl")
include("scalebar.jl")
include("zoom_lines.jl")
include("helpers.jl")
include("axisfunction.jl")
include("contourf.jl")


to_x_attrs(attrs) = @modify(k -> Symbol(:x, k), keys(attrs)[∗])
to_y_attrs(attrs) = @modify(k -> Symbol(:y, k), keys(attrs)[∗])
to_xy_attrs(attrs) = merge(to_x_attrs(attrs), to_y_attrs(attrs))

# XXX: should upstream these!

function Accessors.set(attrs::Attributes, il::IndexLens, val)
	res = deepcopy(attrs)
	res[only(il.indices)] = val
	return res
end

function Accessors.insert(attrs::Attributes, il::IndexLens, val)
	res = deepcopy(attrs)
	res[only(il.indices)] = val
	return res
end

function Accessors.delete(attrs::Attributes, il::IndexLens)
	res = deepcopy(attrs)
	delete!(res, only(il.indices))
	return res
end


Base.:(⊆)(a::Rect2, b::Rect2) = xint(a) ⊆ xint(b) && yint(a) ⊆ yint(b)

shift_range(p::T, (r1, r2)::Pair{<:Rect2,<:Rect2}) where {T<:Point2} = T(
	shift_range(p[1], xint(r1) => xint(r2)),
	shift_range(p[2], yint(r1) => yint(r2)),
)

end
