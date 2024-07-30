module MakieExtra

using Reexport
using Accessors
using InverseFunctions
@reexport using Makie
export Makie

export SymLog, AsinhScale, BaseMulTicks

include("scales.jl")
include("ticks.jl")

end
