GeometryBasics.HyperRectangle(ints::Vararg{Interval, N}) where {N} = HyperRectangle{N}(
    Vec(leftendpoint.(ints)),
    Vec(rightendpoint.(ints) .- leftendpoint.(ints))
)
GeometryBasics.HyperRectangle{N}(ints::Vararg{Interval, N}) where {N} = HyperRectangle{N}(
    Vec(leftendpoint.(ints)),
    Vec(rightendpoint.(ints) .- leftendpoint.(ints))
)

Base.:(⊆)(a::HyperRectangle, b::HyperRectangle) = all(map(⊆, intervals(a), intervals(b)))
Base.:(⊇)(a::HyperRectangle, b::HyperRectangle) = b ⊆ a

shift_range(p::T, (r1, r2)::Pair{<:Rect2,<:Rect2}) where {T<:Point2} =
    T(shift_range.(p, intervals(r1) .=> intervals(r2)))

_which_to_ix(which::Integer) = which == -1 ? 1 : which == 1 ? 2 : error("which must be -1 or 1, got $which")
corner(r::HyperRectangle{2}, which::NTuple{2,Integer}) = Point(extrema(r)[_which_to_ix(which[1])][1], extrema(r)[_which_to_ix(which[2])][2])
corners(r::HyperRectangle{2}) = (bottomleft(r), topleft(r), topright(r), bottomright(r))

intervals(r::HyperRectangle) = SVector(Interval.(r.origin, r.origin + r.widths))
Accessors.set(r::HyperRectangle, ::typeof(intervals), ints) = HyperRectangle(ints...)

Accessors.set(obj::Makie.Polygon, ::typeof(Makie.coordinates), val) = Makie.Polygon(val)

dilate(o::HyperRectangle, kern::HyperRectangle) = Rect(o.origin + kern.origin, o.widths + kern.widths)
erode(o::HyperRectangle, kern::HyperRectangle) = Rect(o.origin - kern.origin, o.widths - kern.widths)

Makie.defaultlimits(userlimits::Rect2, xscale, yscale) = userlimits
Makie.convert_limit_attribute(lims::Rect2) = Tuple(tuple.(lims.origin, lims.origin .+ lims.widths))
