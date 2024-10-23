module MakieExtra

using Reexport
using Accessors
using InverseFunctions
using PyFormattedStrings
using Makie.IntervalSets

@reexport using Makie
export Makie

export SymLog, AsinhScale, BaseMulTicks, EngTicks

include("scales.jl")
include("ticks.jl")
include("helpers.jl")
include("axisfunction.jl")

end
