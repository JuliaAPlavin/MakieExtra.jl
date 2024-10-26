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
    # XXX: do x/yautolimits=false work? are they needed?
    poly!(ax, sel_poly(rs, fplt, plt; kwargs...); rs.poly..., xautolimits=false, yautolimits=false)
    vspan!(ax, sel_span(rs, fplt, plt, 1; kwargs...); rs.poly..., xautolimits=false, yautolimits=false)
    hspan!(ax, sel_span(rs, fplt, plt, 2; kwargs...); rs.poly..., xautolimits=false, yautolimits=false)

    argfuncs = argfuncs_for_xy(plt, fplt; reorder_args=true, kwargs...)
    isrecting = Observable(false)
    on(events(ax).mousebutton, priority=100) do evt
        try
            if evt.button == Mouse.left
                if is_mouseinside(ax) && evt.action == Mouse.press
                    rs.vals[] = map((o, m) -> o => m..m, argfuncs, _mouseposition(ax)[1:length(argfuncs)])
                    isrecting[] = true
                    return Consume(true)
                end
                if is_mouseinside(ax) && isrecting[] && evt.action == Mouse.release
                    if all(map((cur, m) -> leftendpoint(cur) == m, last.(rs.vals[]), _mouseposition(ax)[1:length(argfuncs)]))
                        rs.vals[] = []
                    else
                        rs.vals[] = map((o, cur, m) -> o => leftendpoint(cur)..m, argfuncs, last.(rs.vals[]), _mouseposition(ax)[1:length(argfuncs)])
                    end
                    isrecting[] = false
                    return Consume(true)
                end
            end
        catch e
            @warn "" (e,catch_backtrace())
            return Consume(true)
        end
    end
    on(events(ax).mouseposition, priority=100) do event
        try
            if is_mouseinside(ax) && isrecting[] && ispressed(ax, Mouse.left)
                rs.vals[] = map((o, cur, m) -> o => leftendpoint(cur)..m, argfuncs, last.(rs.vals[]), _mouseposition(ax)[1:length(argfuncs)])
                return Consume(true)
            end
        catch e
            @warn "" (e,catch_backtrace())
            return Consume(true)
        end
    end
end

const SELECTED_PROPNAME = :RectSel_isselected_FJNRQT

is_selected(x::NamedTuple) = get(x, SELECTED_PROPNAME, false)

normalized_selints(rs::RectSelection) = @lift modify(eps -> minmax(eps...), $(rs.vals), @o _[∗][2] |> endpoints)

selected_data(data, rs::RectSelection) = @lift let
    selints = Tuple($(normalized_selints(rs)))
    sdata = filter(data) do r
        all(map(selints) do (o, int)
            o(r) ∈ int
        end)
    end
    isempty(sdata) ? filter(Returns(true), data) : sdata
end

function mark_selected_data(data, rs::RectSelection)
    eltype(data) <: NamedTuple || error("mark_selected is only supported for NamedTuples, got eltype <: $(nameof(eltype(data)))")
    @lift let
        selints = Tuple($(normalized_selints(rs)))
        mdata = mapinsert(data; RectSel_isselected_FJNRQT=function (r)
            all(map(selints) do (o, int)
                o(r) ∈ int
            end)
        end)
        mdata = sort(mdata, by=x -> x.RectSel_isselected_FJNRQT)
        any(x -> x.RectSel_isselected_FJNRQT, mdata) ? mdata : mapinsert(data; RectSel_isselected_FJNRQT=Returns(true))
    end
end
