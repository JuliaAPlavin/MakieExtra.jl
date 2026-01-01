module GLMakieExt

using MakieExtra: show_gl_icon_in_dock
import MakieExtra: primary_resolution
import GLMakie


function __init__()
    if Sys.isapple()
        try
            show_gl_icon_in_dock(false)
        catch e
            @warn "Failed to hide the GL icon from the dock" (e, catch_backtrace())
        end
    end
end


function primary_resolution()
    monitor = GLMakie.GLFW.GetPrimaryMonitor()
    videomode = GLMakie.MonitorProperties(monitor).videomode
    return (videomode.width, videomode.height)
end

end
