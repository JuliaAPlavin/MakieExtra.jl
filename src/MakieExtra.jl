module MakieExtra

using Reexport
using Accessors
using InverseFunctions
using PyFormattedStrings
using Makie.IntervalSets
using Makie.IntervalSets: width
using Makie.Unitful
using DataPipes

@reexport using Makie
export Makie

export SymLog, AsinhScale, BaseMulTicks, EngTicks

include("scales.jl")
include("ticks.jl")
include("scalebar.jl")
include("helpers.jl")
include("axisfunction.jl")


# XXX: should upstream
function Accessors.set(attrs::Attributes, il::IndexLens, val)
	res = deepcopy(attrs)
	res[only(il.indices)] = val
	return res
end

end
