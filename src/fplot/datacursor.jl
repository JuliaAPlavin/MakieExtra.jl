@kwdef struct DataCursor <: FPlotAddon
    key = Keyboard.c
    vals::Observable{Vector{Pair}} = Observable([])
    lines = (;)
end

function cursor_vals(dc::DataCursor, fplt::FPlot, i::Int)
    afunc = get(fplt.argfuncs, i, nothing)
    emptyval = [NaN]
    isnothing(afunc) && return emptyval
    @lift let
        vs = @p $(dc.vals) |> filter(((o, v),) -> o == afunc) |> map(last)
        isempty(vs) ? emptyval : vs
    end
end

function add!(ax::Axis, dc::DataCursor, fplt::FPlot, plt::Type{<:Plot}; kwargs...)
    vlines!(ax, cursor_vals(dc, fplt, 1); dc.lines...)
    hlines!(ax, cursor_vals(dc, fplt, 2); dc.lines...)
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
