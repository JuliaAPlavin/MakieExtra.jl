using Makie

struct S end

Makie.used_attributes(::Type{<:Plot}, ::S) = (:markersize,)

function Makie.convert_arguments(::Type{<:AbstractPlot}, ::S; markersize)
    res = [Point(1, markersize)]
    @info "" markersize res
    return (res,)
end

s = Observable(S())
scatter(s, markersize=123)
s[] = S()
