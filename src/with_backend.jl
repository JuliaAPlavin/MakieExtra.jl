"""
    render_plot(plot!::Function, backend, size)

For a function `plot!(gridpos)` which plots something at the given figure
GridPosition (typically `fig[i, j]` for a `Figure` named `fig`),
perform the plot using the given Makie backend and return an image
(matrix of colors) with the given size.

# Example:

```julia
render_plot(GLMakie, (500, 500)) do gridpos
    ax = Axis3(gridpos)
    meshscatter!(ax, 0, 0, 0)
end
```
"""
function render_plot(plot!, backend, size)
    fig = Figure(; size, figure_padding = 0)
    plot!(fig[1, 1])
    return rotr90(Makie.colorbuffer(fig ; backend))
end

"""
    with_backend(plot!::Function, gridpos, backend ; scalefactor = 5, refit_observable = nothing, kwargs...)

For a function `plot!(gridpos)` which plots something at the given figure
GridPosition (typically `fig[i, j]` for a `Figure` named `fig`),
performe the plot using the given Makie backend at the gridpos.

This is mainly intended to have 3D plots (rendered with GLMakie) as image
in PDF (generated with CairoMakie).

Return the image axis and an observable that can be updated to regenerate
the image to fit to the current layout.

Since switching backend is slow,
the image is not resized automatically.
The size of the image fit the current boundingbox of the given `gridpos`,
multiplied by `scalefactor` (default 5 to ensure a crisp image).

# Example:

Create a figure mixing two different backends.

```julia
using CairoMakie
using GLMakie
using GeometryBasics
using MakieExtra

CairoMakie.activate!()

fig = Figure()

Label(fig[1, 1, Top()], "Cairo backend")
ax_cairo = LScene(fig[1, 1])
mesh!(ax_cairo, s)
mesh!(ax_cairo, c)

Label(fig[1, 2, Top()], "GL backend")
with_backend(fig[1, 2], GLMakie) do figpos
    ax_gl = LScene(figpos)
    mesh!(ax_gl, s)
    mesh!(ax_gl, c)
end
fig

save("backend_demo.pdf", fig)
```

Resizing the image after the layout changed.
```julia
fig = Figure()

# The image fill the full space available
ax_gl, refit = with_backend(fig[1, 1], GLMakie) do gridpos
    ax = LScene(gridpos)
    meshscatter!(ax, 0, 0, 0)
end

ax = Axis(fig[1, 2])  # Now the image is awkward as the layout changed
notify(refit)  # The image is generated again based on the current layout
```
"""
function with_backend(plot!, gridpos, backend ;
        scalefactor = 5,
        alignmode = Outside(),
        kwargs...)

    isnothing(backend) && return plot!(gridpos)

    # Extra layout to infer the bounding box
    layout = GridLayout(gridpos)
    bbox = layout.layoutobservables.computedbbox

    img = Observable(render_plot(plot!, backend, bbox[].widths * scalefactor))

    refit_observable = Observable(false)
    on(refit_observable) do _
        img[] = render_plot(plot!, backend, bbox[].widths * scalefactor)
    end

    ax = Axis(layout[1, 1] ; aspect = DataAspect(), alignmode, kwargs...)
    hidedecorations!(ax)
    hidespines!(ax)
    image!(ax, img)
    translate!(ax.scene, 0, 0, -1)
    return ax, refit_observable
end

