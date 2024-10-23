function cross_lw(m)
    w = m*0.1245
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
end

function vline_lw(m)
    w = m*0.063143668438509
    h = 0.315718342192545
    Makie.Polygon(Point2f[
        (w, -h),
        (w, h),
        (-w, h),
        (-w, -h)
    ])
end

function hline_lw(m)
    w = m*0.063143668438509
    h = 0.315718342192545
    Makie.Polygon(Point2f[
        (-h, w),
        (h, w),
        (h, -w),
        (-h, -w),
    ])
end
