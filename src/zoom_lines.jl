function zoom_lines!(ax1, ax2; strokewidth=1.5, strokecolor=:black, color=(:black, 0))
	pscene = parent(parent(Makie.parent_scene(ax1)))
	@assert parent(parent(Makie.parent_scene(ax2))) === pscene
	obs = @lift let
		lims = [$(ax1.finallimits), $(ax2.finallimits)]
		vps = [$(ax1.scene.viewport), $(ax2.scene.viewport)]
		axs = lims[1] ⊆ lims[2] ? (
			(vp=vps[1], lim=lims[1]),
			(vp=vps[2], lim=lims[2]),
		) : lims[2] ⊆ lims[1] ? (
			(vp=vps[2], lim=lims[2]),
			(vp=vps[1], lim=lims[1]),
		) : nothing
		fs = isnothing(axs) ? nothing : if right(axs[1].vp) < left(axs[2].vp)
			(topright, bottomright, topleft, bottomleft)
		elseif left(axs[1].vp) > right(axs[2].vp)
			(topleft, bottomleft, topright, bottomright)
		elseif bottom(axs[1].vp) < top(axs[2].vp)
			(topleft, topright, bottomleft, bottomright)
		elseif bottom(axs[1].vp) > top(axs[2].vp)
			(bottomleft, bottomright, topleft, topright)
		end
		(
			rect1=$(ax2.finallimits),
			rect2=$(ax1.finallimits),
			slines=isnothing(axs) || isnothing(fs) ? Point2{Float32}[] : [
				fs[1](axs[1].vp), shift_range(fs[3](axs[1].lim), axs[2].lim => axs[2].vp),
				fs[2](axs[1].vp), shift_range(fs[4](axs[1].lim), axs[2].lim => axs[2].vp),
			],
		)
	end

	rectattrs = (; strokewidth, strokecolor, color, xautolimits=false, yautolimits=false)
	poly!(ax1, (@lift $obs.rect1); rectattrs...)
	poly!(ax2, (@lift $obs.rect2); rectattrs...)
	linesegments!(pscene, (@lift $obs.slines), color=strokecolor, linewidth=strokewidth)
end
