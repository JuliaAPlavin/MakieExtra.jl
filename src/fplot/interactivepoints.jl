@kwdef struct InteractivePoints <: MakieExtra.FPlotAddon
    data::MyObservables.AbstractNode
    add_key = Keyboard.a
    delete_key = Keyboard.d
    drag_key = Mouse.left
    priority::Int = 100
end

InteractivePoints(data; kwargs...) = InteractivePoints(; data = _to_signal(data), kwargs...)

function add!(ax::Axis, rs::InteractivePoints, fplt::FPlot, plt::Plot; kwargs...)
    dragging_ix = Ref{Any}(nothing)

    onany(events(ax).mousebutton, events(ax).keyboardbutton, priority=rs.priority) do _...
        is_mouseinside(ax) || return
        try
            root = Makie.root(Makie.parent_scene(ax))
            mp = mouseposition_px(root)
            closest_ix = @p let
                Makie.pick_sorted(root, mp, 10)
                filter(_[1] ∈ plt.plots)
                @oget first(__)
                @oget __[2]
            end
            if ispressed(ax, Exclusively(rs.add_key))
				mpos = _mouseposition(ax)
                rs.data[] = @insert last($(rs.data[])) = construct(eltype(rs.data[]), fplt[1] => mpos[1], fplt[2] => mpos[2])
                return Consume()
            elseif ispressed(ax, Exclusively(rs.delete_key))
                if !isnothing(closest_ix)
                    rs.data[] = @delete $(rs.data[])[closest_ix]
                    return Consume()
                end
            elseif ispressed(ax, Exclusively(rs.drag_key))
                if isnothing(dragging_ix[]) && !isnothing(closest_ix)
                    dragging_ix[] = closest_ix
					elt = rs.data[][dragging_ix[]]
					mpos = _mouseposition(ax)
                    rs.data[] = @set $(rs.data[])[dragging_ix[]] = setall(elt, fplt[1] ++ fplt[2], mpos)
                end
                return Consume()
            else
                dragging_ix[] = nothing
            end
        catch ex
            @error "While handling key/mouse event" exc=(ex, catch_backtrace())
            rethrow()
        end
    end

    on(events(ax).mouseposition) do _
        if !is_mouseinside(ax)
            dragging_ix[] = nothing
        end
        if !isnothing(dragging_ix[])
            try
				elt = rs.data[][dragging_ix[]]
				mpos = _mouseposition(ax)
                rs.data[] = @set $(rs.data[])[dragging_ix[]] = setall(elt, fplt[1] ++ fplt[2], mpos)
            catch ex
                @error "While updating dragged point" exc=(ex, catch_backtrace())
                rethrow()
            end
        end
    end
end
