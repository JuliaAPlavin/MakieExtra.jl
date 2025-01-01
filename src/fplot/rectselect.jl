@kwdef struct RectSelection <: FPlotAddon
    key = true
    vals::Observable{Vector{Pair}} = Observable([])
    poly = (;)
end

function sel_ints(rs::RectSelection, fplt::FPlot, plt::Type{<:Plot}; kwargs...)
    @lift let
        map(argfuncs_for_xy(plt, fplt; reorder_args=true, kwargs...)) do afunc
            vs = @p $(rs.vals) |> filter(((o, v),) -> o == afunc) |> map(last)
            v = @oget only(vs) NaN..NaN
        end
    end
end

function sel_poly(rs::RectSelection, fplt::FPlot, plt::Type{<:Plot}; kwargs...)
    emptyval = Rect2(NaN..NaN, NaN..NaN)
    ints = sel_ints(rs, fplt, plt; kwargs...)
    @lift let
        length($ints) == 2 || return emptyval
        Rect2($ints...)
    end
end

function sel_span(rs::RectSelection, fplt::FPlot, plt::Type{<:Plot}, i::Int; kwargs...)
    emptyval = NaN..NaN
    ints = sel_ints(rs, fplt, plt; kwargs...)
    @lift let
        length($ints) == 2 && all(i -> all(!isnan, endpoints(i)), $ints) && return emptyval # 2d rect is shown instead
        get($ints, i, emptyval)
    end
end

function add!(ax::Axis, rs::RectSelection, fplt::FPlot, plt::Type{<:Plot}; kwargs...)
    poly!(ax, sel_poly(rs, fplt, plt; kwargs...); rs.poly...)
    vspan!(ax, sel_span(rs, fplt, plt, 1; kwargs...); rs.poly...)
    hspan!(ax, sel_span(rs, fplt, plt, 2; kwargs...); rs.poly...)

    isrecting = Observable(false)
    on(events(ax).mousebutton, priority=100) do evt
        try
            if evt.button == Mouse.left
                if is_mouseinside(ax) && evt.action == Mouse.press
                    rs.vals[] = map((o, m) -> o => m..m, fplt.argfuncs, _mouseposition(ax))
                    isrecting[] = true
                    return Consume(true)
                end
                if is_mouseinside(ax) && isrecting[] && evt.action == Mouse.release
                    if all(map((cur, m) -> leftendpoint(cur) == m, last.(rs.vals[]), _mouseposition(ax)))
                        rs.vals[] = []
                    else
                        rs.vals[] = map((o, cur, m) -> o => leftendpoint(cur)..m, fplt.argfuncs, last.(rs.vals[]), _mouseposition(ax))
                    end
                    isrecting[] = false
                    return Consume(true)
                end
            end
        catch e
            @warn "" (e,catch_backtrace())
        end
    end
    on(events(ax).mouseposition, priority=100) do event
        try
            if is_mouseinside(ax) && isrecting[] && ispressed(ax, Mouse.left)
                rs.vals[] = map((o, cur, m) -> o => leftendpoint(cur)..m, fplt.argfuncs, last.(rs.vals[]), _mouseposition(ax))
                return Consume(true) 
            end
        catch e
            @warn "" e
        end
    end
end
