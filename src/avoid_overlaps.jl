using NonNegLeastSquares: nonneg_lsq
using LinearAlgebra: tril


function offsets_to_move_min_distance(targets, o; min_dist::Real)
    targets_sort = sortview(targets; by=o)

    n = length(targets_sort)
    x0_min = o(first(targets_sort)) - n * min_dist
    A = tril(ones(n, n))
    b = o.(targets_sort) .- (x0_min .+ (0:(n-1)) .* min_dist)

    out = nonneg_lsq(A, b) |> vec
    sol = cumsum(out) .+ x0_min .+ (0:(n-1)) .* min_dist

    map(targets, sol[invperm(parentindices(targets_sort)[1])]) do tgt, x
        x - o(tgt)
    end
end

function offset_texts_auto_1d!(texts::AbstractVector; direction, height_frac_mindist=0.9, height_frac_for_line=0.1, Lines=(;))
    @assert direction ∈ (:x, :y)
    dir_i = Dict(:x => 1, :y => 2)[direction]
    height = @p texts map(boundingbox(_, :pixel)) map(extrema) map(abs(_[2][dir_i] - _[1][dir_i])) mean
    offsets = @p texts map(boundingbox(_, :pixel).origin[dir_i]) offsets_to_move_min_distance(__, identity; min_dist=height_frac_mindist*height)
    foreach(texts, offsets) do t, o
        t.offset[] = @set $(t.offset[])[dir_i] = o
        pixpos = Makie.project(t.parent, Makie.apply_transform(Makie.transform_func(t.parent), _tposition(t)))
        if !isnothing(Lines) && abs(o) ≥ height_frac_for_line*height
            @assert length(t.offset[]) == 2 || length(t.offset[]) == 3 && iszero(t.offset[][3])
            lines!(t.parent, [pixpos, pixpos .+ t.offset[][1:2]]; space=:pixel, Lines...)
        end
    end
end

_tposition(t::Makie.Text) = only(t.positions[])
_tposition(t::TextWithBox) = t.position[]
_tposition(t::TextGlow) = t.position[]
