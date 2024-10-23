module GLMakieExt

using MakieExtra: show_gl_icon_in_dock

function __init__()
    if Sys.isapple()
        try
            show_gl_icon_in_dock(false)
        catch e
            @warn "Failed to hide the GL icon from the dock" (e, catch_backtrace())
        end
    end
end

end
