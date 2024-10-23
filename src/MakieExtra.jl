module MakieExtra

using Reexport
using Accessors
using InverseFunctions
using PyFormattedStrings
@reexport using Makie
export Makie

export SymLog, AsinhScale, BaseMulTicks, EngTicks

include("scales.jl")
include("ticks.jl")
include("helpers.jl")


# almost https://github.com/MakieOrg/Makie.jl/pull/3697
__precompile__(false)
function Base.show(io::IO, ::MIME"text/html", vs::VideoStream)
    mktempdir() do dir
        path = save(joinpath(dir, "video.mp4"), vs)
        print(
            io,
            """<video autoplay controls loop><source src="data:video/x-m4v;base64,""",
            Makie.base64encode(open(read, path)),
            """" type="video/mp4"></video>"""
        )
    end
end

end
