function zoom_lines!(ax1, ax2; strokewidth=1.5, strokecolor=:black, color=(:black, 0))
    pscene = parent(parent(Makie.parent_scene(ax1)))
    @assert parent(parent(Makie.parent_scene(ax2))) === pscene
    obs = lift(ax1.finallimits, ax2.finallimits, ax1.scene.viewport, ax2.scene.viewport, ax1.scene.camera.projectionview, ax2.scene.camera.projectionview, Makie.transform_func(ax1), Makie.transform_func(ax2)) do _...
        lims = [ax1.finallimits[], ax2.finallimits[]]
		axs = lims[1] ⊆ lims[2] ? (ax1, ax2) :
			  lims[2] ⊆ lims[1] ? (ax2, ax1) :
			  nothing
        if isnothing(axs)
			nothing
		else
			vps = to_value.(viewport.(axs))
			fs = if right(vps[1]) < left(vps[2])
	            (topright, bottomright, topline, bottomline)
	        elseif left(vps[1]) > right(vps[2])
	            (topleft, bottomleft, topline, bottomline)
	        elseif bottom(vps[1]) < top(vps[2])
	            (topleft, topright, leftline, rightline)
	        elseif bottom(vps[1]) > top(vps[2])
	            (bottomleft, bottomright, leftline, rightline)
	        end
			line1 = fs[3](fullproject(axs[2], axs[1].finallimits[]))
			line2 = fs[4](fullproject(axs[2], axs[1].finallimits[]))
		end
        (
            rect1=ax2.finallimits[],
            rect2=ax1.finallimits[],
            slines=isnothing(axs) ? Point2{Float32}[] : Point2{Float32}[
				fs[1](vps[1]), argmin(p -> norm(p - fs[1](vps[1])), line1),
                fs[2](vps[1]), argmin(p -> norm(p - fs[2](vps[1])), line2),
            ],
        )
    end

    rectattrs = (; strokewidth, strokecolor, color, xautolimits=false, yautolimits=false)
    poly!(ax1, (@lift $obs.rect1); rectattrs...)
    poly!(ax2, (@lift $obs.rect2); rectattrs...)
    plt = linesegments!(pscene, (@lift $obs.slines), color=strokecolor, linewidth=strokewidth, linestyle=:dot)
    translate!(plt, 0, 0, 1000)
    return nothing
end
