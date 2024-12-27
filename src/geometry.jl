GeometryBasics.HyperRectangle{N}(ints::Vararg{Interval, N}) where {N} = HyperRectangle{N}(
    Point(leftendpoint.(ints)),
    Point(rightendpoint.(ints) .- leftendpoint.(ints))
)

Base.:(⊆)(a::Rect2, b::Rect2) = xint(a) ⊆ xint(b) && yint(a) ⊆ yint(b)

shift_range(p::T, (r1, r2)::Pair{<:Rect2,<:Rect2}) where {T<:Point2} = T(
    shift_range(p[1], xint(r1) => xint(r2)),
    shift_range(p[2], yint(r1) => yint(r2)),
)

_which_to_ix(which::Integer) = which == -1 ? 1 : which == 1 ? 2 : error("which must be -1 or 1, got $which")
corner(r::HyperRectangle{2}, which::NTuple{2,Integer}) = Point(extrema(r)[_which_to_ix(which[1])][1], extrema(r)[_which_to_ix(which[2])][2])
corners(r::HyperRectangle{2}) = (bottomleft(r), topleft(r), topright(r), bottomright(r))

xint(rect::Rect) = minimum(rect)[1]..maximum(rect)[1]
yint(rect::Rect) = minimum(rect)[2]..maximum(rect)[2]
