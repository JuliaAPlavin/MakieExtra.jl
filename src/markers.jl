# caching is to avoid overflowing Makie "texture atlas"
const _markerlock = ReentrantLock()
const _markercache = Dict{Symbol, Vector{Pair}}()
const _marker_lw_max_Δ = 0.02

"""    marker_lw(base::Symbol, lw_mul::Real)

Adjust the line width of a `base` marker by a factor of `lw_mul`.
"""
function marker_lw(base, lw_mul)
    lock(_markerlock) do
        cache = get!(_markercache, base, Pair[])
        closest = isempty(cache) ? nothing : argmin(c -> abs(first(c) - lw_mul), cache)
        if !isnothing(closest) && abs(first(closest) - lw_mul) ≤ _marker_lw_max_Δ
            return last(closest)
        else
            push!(cache, lw_mul => _marker_lw(base, lw_mul))
            return last(last(cache))
        end
    end
end

_marker_lw(base, lw_mul) =
    if base == :vline
        w = lw_mul * 0.063143668438509
        h = 0.315718342192545
        Makie.Polygon(Point2f[
            (w, -h),
            (w, h),
            (-w, h),
            (-w, -h)
        ])
    elseif base == :hline
        w = lw_mul * 0.063143668438509
        h = 0.315718342192545
        Makie.Polygon(Point2f[
            (-h, w),
            (h, w),
            (h, -w),
            (-h, -w),
        ])
    elseif base == :cross
        w = lw_mul * 0.1245
        h = 0.375
        Makie.Polygon(Point2f[
            (w, h),
            (w, w),
            (h, w),
            (h, -w),
            (w, -w),
            (w, -h),
            (-w, -h),
            (-w, -w),
            (-h, -w),
            (-h, w),
            (-w, w),
            (-w, h),
        ])
    else
        error("Unsupported marker type: $base")
    end
