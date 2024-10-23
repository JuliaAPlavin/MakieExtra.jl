function zoom_lines!(ax1, ax2; strokewidth=1.5, strokecolor=:black, color=(:black, 0))
    pscene = parent(parent(Makie.parent_scene(ax1)))
    @assert parent(parent(Makie.parent_scene(ax2))) === pscene
    obs = lift(ax1.finallimits, ax2.finallimits, ax1.scene.viewport, ax2.scene.viewport, ax1.scene.camera.projectionview, ax2.scene.camera.projectionview, Makie.transform_func(ax1), Makie.transform_func(ax2)) do _...
        lims = [ax1.finallimits[], ax2.finallimits[]]
        axs = lims[1] ⊆ lims[2] ? (ax1, ax2) :
              lims[2] ⊆ lims[1] ? (ax2, ax1) :
              nothing
        slines = if isnothing(axs)
            nothing
        else
            r1 = fullproject(axs[1], axs[1].finallimits[])
            r2 = fullproject(axs[2], axs[1].finallimits[])
            cornsets = [
                ((corner(r1, (1,1)), corner(r2, (-1,1))), (corner(r1, (1,-1)), corner(r2, (-1,-1)))),
                ((corner(r1, (1,-1)), corner(r2, (1,1))), (corner(r1, (-1,-1)), corner(r2, (-1,1)))),
                ((corner(r1, (-1,-1)), corner(r2, (1,-1))), (corner(r1, (-1,1)), corner(r2, (1,1)))),
                ((corner(r1, (-1,1)), corner(r2, (-1,-1))), (corner(r1, (1,1)), corner(r2, (1,-1)))),
            ]
            argmin(cornsets) do ((a1, a2), (b1, b2))
                min(norm(a1-a2), norm(b1-b2))
            end
        end
        (
            rect1=ax2.finallimits[],
            rect2=ax1.finallimits[],
            slines=isnothing(slines) ? Point2{Float32}[] : Point2{Float32}[slines[1]..., slines[2]...],
        )
    end

    rectattrs = (; strokewidth, strokecolor, color, xautolimits=false, yautolimits=false)
    poly!(ax1, (@lift $obs.rect1); rectattrs...)
    poly!(ax2, (@lift $obs.rect2); rectattrs...)
    plt = linesegments!(pscene, (@lift $obs.slines), color=strokecolor, linewidth=strokewidth, linestyle=:dot)
    translate!(plt, 0, 0, 1000)
    return nothing
end
