@kwdef struct DataCursor <: FPlotAddon
    key = Keyboard.c
    vals::Observable{Vector{Pair}} = Observable([])
    lines = (;)
end

function cursor_vals(dc::DataCursor, fplt::FPlot, plt::Type{<:Plot}, i::Int; kwargs...)
    afunc = get(argfuncs_for_xy(plt, fplt; reorder_args=true, kwargs...), i, nothing)
    emptyval = [NaN]
    isnothing(afunc) && return emptyval
    @lift let
        vs = @p $(dc.vals) |> filter(((o, v),) -> o == afunc) |> map(last)
        isempty(vs) ? emptyval : vs
    end
end

function add!(ax::Axis, dc::DataCursor, fplt::FPlot, plt::Type{<:Plot}; kwargs...)
    vlines!(ax, cursor_vals(dc, fplt, plt, 1; kwargs...); dc.lines...)
    hlines!(ax, cursor_vals(dc, fplt, plt, 2; kwargs...); dc.lines...)
    on(events(ax).mouseposition, priority=100) do event
        try
            if is_mouseinside(ax) && ispressed(ax, Exclusively(dc.key))
                dc.vals[] = map(=>, fplt.argfuncs, _mouseposition(ax))
                return Consume(true) 
            end
        catch e
            @warn "" (e,catch_backtrace())
        end
    end
    on(events(ax).keyboardbutton, priority=100) do event
        if event.key == dc.key && event.action == Keyboard.release
            dc.vals[] = []
            return Consume(true)
        end
    end
end
