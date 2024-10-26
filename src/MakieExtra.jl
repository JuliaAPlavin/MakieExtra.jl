module MakieExtra

using Reexport
using Accessors
using InverseFunctions
@reexport using Makie
export Makie

export SymLog, AsinhScale, BaseMulTicks, EngTicks

include("scales.jl")
include("ticks.jl")

end
