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

# https://github.com/MakieOrg/Makie.jl/pull/3695
Makie.convert_arguments(P::Type{<: Band}, x::AbstractVector{<:Number}, y::AbstractVector{<:Makie.Interval}) =
    Makie.convert_arguments(P, x, Makie.leftendpoint.(y), Makie.rightendpoint.(y))
Makie.convert_arguments(P::Type{<:Rangebars}, x::AbstractVector{<:Number}, y::AbstractVector{<:Makie.Interval}) =
    Makie.convert_arguments(P, x, Makie.endpoints.(y))
Makie.convert_arguments(P::Type{<:Union{HSpan, VSpan}}, x::Makie.Interval) =
    Makie.convert_arguments(P, Makie.endpoints(x)...)

end
