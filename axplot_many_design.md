# `axplot_many` — full semantics

## Context

`axplot_many` ([src/fplot/axplot_many.jl](/Users/aplavin/.julia/dev/MakieExtra/src/fplot/axplot_many.jl)) builds a grid of `axplot`-style subplots from a single `FPlot`. The function has grown organically and currently has uneven coverage across the dimensions of behavior it touches — some faceting modes work, others don't; observable input is partially wired but broken in the body; color-attribute propagation was just unified; `ToAes` only handles `:row`; titles, linking, and label-hiding follow ad-hoc rules per branch; the no-faceting case produces an empty grid; the return value is unspecified for the positional form.

This spec re-derives the full semantics top-to-bottom so the function has one consistent model, then defines tests that pin each rule down.

The implementation is **out of scope** for this document — scope here is *what* `axplot_many` should do, not *how* the body should be restructured to do it.

## Conceptual model

`axplot_many` produces a 2-D grid of subplots from one `FPlot`. The grid has two axes — **row** and **col** — and each axis can have at most one **driver** describing how that dimension expands.

A driver is one of:

- **kwarg-facet** — the `FPlot` has a `col` (or `row`) kwargfunc set to a function `f`. The data is grouped by `f` (via `group_vg`); each group becomes one column (or row).
- **argfunc-ToAes** — one of the `FPlot`'s positional argfuncs is `ToAes(:col, funcs)` (or `:row`). The dimension expands to `length(funcs)`; each cell substitutes the corresponding func at that argfunc position.
- **kwargfunc-ToAes** — one of the `FPlot`'s `kwargfuncs` (e.g. `color`) is `ToAes(:col, funcs)` (or `:row`). The dimension expands to `length(funcs)`; each cell substitutes the corresponding func at that kwarg position.

Each grid axis (row, col) has at most **one** driver. Specifying two drivers for the same axis is an **error** (e.g. both `col=…` kwarg and `ToAes(:col, …)` somewhere).

**Multiple ToAes for the same axis** (e.g. `ToAes(:row, (f1,f2))` at one argfunc position **and** `color=ToAes(:row, (sqrt,log))`) are allowed and interpreted as **parallel/zip**: row 1 substitutes `f1` and `sqrt`, row 2 substitutes `f2` and `log`. All `ToAes` tuples on the same axis must have the same length; length mismatch → **error**.

Both 0/1/2 axes can have drivers. The 0-driver case (no `:col`, no `:row`, no `ToAes`) renders a single 1×1 cell with the underlying `axplot(plotf)(fplt)` and any color legend.

## API

```julia
axplot_many(plotf, fplt; legend=(;), linkxaxes=true, linkyaxes=true)
axplot_many(pos, plotf, fplt; legend=(;), linkxaxes=true, linkyaxes=true)
```

- `plotf` — a plot function (`scatter`, `lines`, …) or a tuple-form for `multiplot` (e.g. `(scatter, lines)`).
- `fplt` — `FPlot`, `Observable{<:FPlot}`, or `MyObservables.AbstractNode{<:FPlot}`.
- `pos` — `GridPosition` or `GridSubposition` to embed into.
- `legend`, `linkxaxes`, `linkyaxes` — see below.

**No other kwargs accepted.** All per-subplot/axis customization (markersize, scales, axis attrs, etc.) flows through `FPlot` itself. This is a deliberate departure from `axplot`'s permissive API: `axplot_many` is narrow on purpose, since `FPlot` is already the canonical place to put per-plot attributes and `axplot_many` shouldn't introduce a second path.

## Faceting

### Driver detection

For each grid axis (`:col`, `:row`):

1. Check kwargfuncs for the literal key (`:col` or `:row`).
2. Scan `argfuncs` for `ToAes(axis, ...)`.
3. Scan `kwargfuncs` (other than the `:col`/`:row` keys) for `ToAes(axis, ...)`.

Drivers from steps 2 & 3 may co-occur (parallel/zip across multiple argfunc/kwargfunc positions). Step 1 must not co-occur with steps 2/3 for the same axis.

### Group ordering

Use `group_vg` everywhere — it preserves first-occurrence order. Drop the `unique` + `Dict` helper currently used in the `col`+`row` branch; one rule for all combinations.

### Grid shape

- `kwarg-facet` driver → number of unique values of `f(x)` for `x` in `fplt.data`.
- `argfunc-ToAes` / `kwargfunc-ToAes` driver → `length(funcs)`.
- Combined drivers (one per axis) → product of the two sizes.

### Per-cell content

Each cell receives an `FPlot` derived from the original by:

- Restricting `data` to the slice belonging to this cell (filtered by the kwarg-facet driver(s)).
- Substituting the per-cell func at every `ToAes` position participating in this cell's axes.
- Stripping the consumed driver kwargs (`col`/`row`) and unwrapping consumed `ToAes` to plain funcs.

The cell is then plotted via `_to_axplot(plotf)(cellpos, cell_fplt; axis=(;title=…))`. No other kwargs are forwarded.

### Fully-populated grids

Every cell of the grid receives an `Axis` and a plot. For kwarg-facet × kwarg-facet faceting, combinations whose data slice is currently empty are still rendered — as an empty `Axis` that shares the global linked range and color attributes. This keeps the layout consistent in the static case and lets `Observable` updates populate previously-empty `(row, col)` combinations reactively. Set sizes are still derived once from the captured key sets — out-of-bound `(row, col)` keys remain silently dropped per §"Observables". ToAes-driven dimensions are never ragged either.

## Titles

Each cell composes its title from up to two *axis contributions* (one for the row axis, one for the col axis):

| Driver type | Contribution |
|---|---|
| no driver on this axis | `""` |
| kwarg-facet (`col=f`) | `"shortlabel(f) = value"` |
| argfunc-ToAes | `""` (axis label already shows it — see Linking) |
| kwargfunc-ToAes (`color=ToAes(...)`, etc.) | `"name: shortlabel(func)"` (e.g. `"color: sqrt"`) |

Per-cell title = `row_contribution * "\n" * col_contribution`, with empty contributions / separators collapsed.

**Repeats are grayed.** Across columns, the row contribution is rendered normally on the first column and `rich(…; color=:gray70)` on others; symmetrically across rows for the col contribution. This matches the existing `col`+`row` kwarg-facet behavior and unifies the (`argToAes`+kwarg) branch which currently emits `""` on non-leading cells.

When **both** parallel-zip ToAes contribute on the same axis, the `name: shortlabel(func)` parts are joined with `", "` (e.g. `"color: sqrt, x: _.a"`).

The auto-title overrides any `title` set in `FPlot.axis` whenever at least one driver is active. In the no-driver (1×1) case, no auto-title is generated and FPlot's `axis.title` is used as-is. (FPlot's other axis attrs always apply per cell; only `title` is replaced when an auto-title exists.)

## Linking and label hiding

`linkxaxes::Bool` and `linkyaxes::Bool` (default `true`).

For a given physical axis (X = argfunc index 1, Y = index 2):

- If `argfunc-ToAes(:row, …)` lives at this index → the axis varies across rows → **link only within each row** (across cols).
- If `argfunc-ToAes(:col, …)` lives at this index → varies across cols → **link only within each col** (across rows).
- Otherwise → **link across the entire grid**.

`linkxaxes=false` (resp. `linkyaxes=false`) suppresses the corresponding linking entirely.

`autohide_axlabels!` follows the same rule: hide a label only along the dimension where the axis is *uniform* (linked across that dimension). When X varies per row, every row needs its own X label → don't hide along the row dimension. When X is uniform → hide all but the bottom row (current behavior).

`kwargfunc-ToAes` does not affect linking — it doesn't change which physical axes vary.

## Color attributes (already settled)

All color-related FPlot attributes — `colorrange`, `colorscale`, `colormap`, `lowclip`, `highclip`, `nan_color` — are propagated uniformly to every subplot and to the shared `Colorbar`. Extraction policy:

- `colorrange`: `@oget fplt.colorrange  >  fplt.color.attrs.limit  >  extrema(fplt.color, fplt.data)`.
- `colorscale`: `@oget fplt.colorscale  >  fplt.color.attrs.scale`. `Ref` unwrapped.
- `colormap`, `lowclip`, `highclip`, `nan_color`: from `fplt.<key>` if present, `Ref` unwrapped.

For the `Colorbar`, `colorscale` is renamed to `scale`, and `nan_color` is dropped (Colorbar doesn't accept it). All other attrs forwarded.

This is already implemented in the current code; the spec captures it for completeness.

## Color legend (Colorbar)

**Minimal scope** — only the case currently supported, formalized:

- Shown only when **all** of: `hasproperty(fplt, :color)`, `color_isnumeric == true`, `get(legend, :color, true) == true`, **and** there is no `ToAes` on `:color` (color is shared across the whole grid).
- Layout: `Label(gl[:,end+1][1,1], shortlabel(fplt.color))` + `Colorbar(gl[:,end][2,1]; cb_kws...)`.
- Categorical color → no legend produced. Per-cell axplot may still produce its own.
- `color = ToAes(...)` → no shared legend produced. (Per-row/col Colorbars and a categorical legend are deferred.)

The `legend` kwarg shape stays as a NamedTuple gated by `:color` for now (`legend=(;color=true)`), leaving room to grow.

`color_isnumeric` is determined by checking `fplt₀.color(first(fplt₀.data)) isa Number` *only* when `fplt₀.color` is callable on a single data point. When `color` is `AsCategorical(...)`, `Ref(...)`, or a non-function value, it is treated as non-numeric.

## Observables

`fplt::Observable{<:FPlot}` (or `MyObservables.AbstractNode{<:FPlot}`) is supported, with structure frozen at construction:

- **Layout** — number of rows/cols, set of group keys, `ToAes` lengths — is determined once from `to_value(fplt)` at the `axplot_many` call.
- **Per-cell content** is reactive: each cell receives a lifted `FPlot` whose `data` is the per-group filtered slice of `fplt[].data` and whose argfuncs/kwargfuncs reflect the current value. The underlying `axplot` already updates labels/limits/data reactively from there.
- **Out-of-bound updates** (group keys appearing/disappearing in data, `ToAes` lengths changing, `color` flipping numeric↔categorical, color attrs not present at construction appearing later) are **silently ignored** — the layout and the cell-to-group mapping stay frozen. New group keys' data simply doesn't appear in any cell; missing group keys' cells become empty.

`fplt.color` and the related color attrs being themselves `Observable`/`AbstractNode` (per-attribute reactivity inside a non-Observable FPlot) is **not** in scope here — the spec assumes the FPlot value as a whole is the unit of update.

## Return value

```julia
NamedTuple{(:figure, :gl, :axes, :plots, :colorbar)}
```

- Top-level form: `figure` is the new `Figure`. Positional form: `figure = nothing`.
- `gl::GridLayout` — the layout `axplot_many` built into `pos`.
- `axes::Matrix{Axis}` — `[row, col]` indexed; every cell is an `Axis` (possibly with empty data).
- `plots::Matrix` — same shape as `axes`. Each entry is whatever `_to_axplot(plotf)` returned (a Plot or a tuple of plots from `multiplot`).
- `colorbar::Union{Colorbar,Nothing}` — the shared colorbar if produced, else `nothing`.

## Edge cases

- **Empty `fplt.data`** — kwarg-facet drivers expand to 0 groups → empty grid (no cells). `ToAes` drivers still expand to `length(funcs)` cells (data-independent), and those cells render with empty data (the underlying plot may show empty axes). No error from `axplot_many` itself.
- **`fplt.data === nothing`** — error propagates from underlying `convert_arguments`; `axplot_many` doesn't pre-check.
- **No drivers** — render a single 1×1 cell as `_to_axplot(plotf)(gl[1,1], fplt)`. Shared color legend still applies. No facet title (an FPlot-supplied `axis.title` is honored as-is in this case).
- **Single-element `ToAes` funcs tuple** — degenerate; produces 1 row/col. Title contribution follows the rules above (empty for argfunc, `"name: shortlabel(func)"` for kwargfunc).
- **Empty `ToAes` funcs tuple** — error at construction (validate in `ToAes` or in `axplot_many` driver detection).
- **ToAes-on-color in a faceted grid** — color varies across the row/col dimension; shared `Colorbar` is suppressed. Subplots still render.
- **`color` is `AsCategorical(...)` or `Ref(...)`** — `color_isnumeric` is `false`; no shared `Colorbar`.

## Test plan

Tests live in a **new file** `test/axplot_many.jl` (alongside `test/fplot.jl`), as `@testitem` blocks discovered by `TestItemRunner`. Use `CairoMakie` for rendering checks and small integer/string data so groups are predictable.

For each test, "render the figure end-to-end" means at least `Makie.colorbuffer(fig; backend=CairoMakie)` to catch any crash.

### 1. Driver detection / structural shape

- (1.1) No drivers → 1×1 grid; `axes` is `1×1`; `colorbar === nothing` when no color, otherwise a `Colorbar`.
- (1.2) `col=f` only → 1 row, N cols where N = unique values of `f(data)`; group order = first-occurrence.
- (1.3) `row=f` only → mirror of (1.2).
- (1.4) Both `col=f` and `row=g` → M×N grid; every cell is an `Axis` (combos without data render as empty axes).
- (1.5) `ToAes(:col, funcs)` in argfuncs, no kwarg-facet → 1 row, `length(funcs)` cols.
- (1.6) `ToAes(:row, funcs)` in argfuncs, no kwarg-facet → mirror of (1.5).
- (1.7) `ToAes(:col, funcs)` × `row=f` → `length(funcs)` × N grid.
- (1.8) `kwargfunc-ToAes` (e.g. `color=ToAes(:row, (sqrt, log10))`) → `length(funcs)` rows.
- (1.9) Parallel zip: `argfunc-ToAes(:row, (f1,f2))` + `color=ToAes(:row, (c1,c2))` → 2 rows, paired correctly (assert by checking each row's plotted color attr).
- (1.10) Length-mismatch parallel zip → throws.
- (1.11) Same-axis double driver (`col=f` + `ToAes(:col, ...)`) → throws.
- (1.12) Empty `ToAes((:row, ()))` → throws.

### 2. Titles

- (2.1) `col=f` only → `title == "shortlabel(f) = value"` per col, no newline. No graying needed.
- (2.2) `row=g` only → mirror.
- (2.3) `col=f` + `row=g` → composed title; first row/col normal, others grayed; assert `rich`/`color=:gray70` markers.
- (2.4) `argfunc-ToAes(:row, ...)` only → `title == ""` per cell; xlabel/ylabel reflect per-row func.
- (2.5) `kwargfunc-ToAes(:row, (sqrt, log))` only → `title == "color: sqrt"` / `"color: log"` per row.
- (2.6) `argfunc-ToAes(:row, ...)` + `col=f` → col-contribution titled normally on first row, gray70 on others; row-contribution empty (so title is just the col contribution, possibly grayed).
- (2.7) Parallel-zip kwargfunc-ToAes (two kwargs varying) → title joins with `", "`.
- (2.8) An `axis=(;title="X")` set inside `FPlot` is **overridden** by the auto-title.

### 3. Linking + label hiding

- (3.1) `col=f`, `linkxaxes=true`, `linkyaxes=true` → all axes' `xaxislinks` and `yaxislinks` cover the whole grid; X labels visible only on bottom row, Y labels only on left col.
- (3.2) `argfunc-ToAes(:row, (f1, f2))` at argfunc index 1 → X linked **per row** only; X labels visible on bottom of every row (not hidden across rows); Y linked across full grid.
- (3.3) `argfunc-ToAes(:col, (f1, f2))` at argfunc index 2 → Y linked **per col** only; Y labels visible on left of every col.
- (3.4) Parallel-zip: `argfunc-ToAes(:row, ...)` at index 1 AND argfunc index 2 → both X and Y linked per-row; both labels visible on every row.
- (3.5) `linkxaxes=false` with otherwise-linkable grid → no X-axis linking; `autohide_axlabels!` doesn't hide X labels.
- (3.6) `kwargfunc-ToAes(:row, ...)` only (no argfunc-ToAes) → linking is grid-wide for both X and Y (kwargfunc-ToAes doesn't change which physical axes vary).

### 4. Color (verify regressions only — already implemented)

- (4.1) Numeric color via plain function → shared `Colorbar` with computed `colorrange`.
- (4.2) `color = AxFunc(f, scale=log10, limit=1..100)` → subplots and Colorbar both use `log10` scale and `(1, 100)` range.
- (4.3) `lowclip`, `highclip`, `nan_color` set on `FPlot` → propagate to subplots; `lowclip`/`highclip` reach `Colorbar`; `nan_color` does not (filtered out).
- (4.4) `colorscale=Ref(log10)` works equivalently to `colorscale=log10`.
- (4.5) `legend=(;color=false)` → no `Label`+`Colorbar`.
- (4.6) Categorical color (`AsCategorical(f)`) → no shared legend; subplots render.
- (4.7) `color=ToAes(:row, (sqrt, log))` → no shared `Colorbar` (deferred); subplots render and each row's plot uses the right color function.

### 5. Observables

- (5.1) `fplt::Observable{<:FPlot}` with `col=f` faceting; mutate `fplt[].data` (same group keys, different values) → cells update; group structure frozen, no new cells appear.
- (5.2) Mutate `fplt[].data` to introduce a new group key not in the initial set → that key's data is silently dropped from rendering; existing cells unaffected.
- (5.3) Mutate `fplt[].data` so an initial group key now has empty data → that cell goes empty; no error.
- (5.4) `fplt[]` swapped to a value where a `ToAes` length changed → silently ignored (cells frozen to initial layout).
- (5.5) Color limits computed reactively when initial color attrs allow it (mirrors existing `axfunc` test pattern with `Observable{Any}` for `scale`).
- (5.6) `kwarg×kwarg` with an initially-empty `(row, col)` combo: the cell exists as an `Axis` from construction; mutating `fplt[]` to fill that combo populates the cell reactively without changing the layout.

### 6. Return value

- (6.1) Top-level call: result has `:figure, :gl, :axes, :plots, :colorbar` keys; `figure isa Figure`.
- (6.2) Positional call: `figure === nothing`; `gl isa GridLayout`.
- (6.3) `axes` is a `Matrix{Axis}`; every entry is an `Axis` for non-empty grids (no `nothing` slots).
- (6.4) `plots` matrix has same shape as `axes`; every entry is non-`nothing`.
- (6.5) `colorbar isa Colorbar` when produced; `=== nothing` otherwise.

### 7. Smoke

- (7.1) `multiplot`-style `plotf=(scatter, lines)` works through `axplot_many`.
- (7.2) Top-level form `axplot_many(plotf, fplt)` returns a Figure-bearing NamedTuple, no errors.
- (7.3) `axplot_many` rejects unknown kwargs (e.g. `markersize=10`).

## Files

- [src/fplot/axplot_many.jl](/Users/aplavin/.julia/dev/MakieExtra/src/fplot/axplot_many.jl) — implementation lives here.
- `test/axplot_many.jl` — **new file** for all tests added as `@testitem` blocks. (Existing `test/fplot.jl` is left untouched.)
- Reused utilities: `group_vg` (DataManipulation), `@oget` (AccessorsExtra), `getval` ([src/fplot/makieconvert.jl:50-59](/Users/aplavin/.julia/dev/MakieExtra/src/fplot/makieconvert.jl#L50-L59)), `extra_plot_kwargs` ([src/fplot/axfuncs.jl:26-35](/Users/aplavin/.julia/dev/MakieExtra/src/fplot/axfuncs.jl#L26-L35)), `autohide_axlabels!` ([src/MakieExtra.jl:257-290](/Users/aplavin/.julia/dev/MakieExtra/src/MakieExtra.jl#L257-L290)), `shortlabel` ([src/fplot/axfuncs.jl:18-24](/Users/aplavin/.julia/dev/MakieExtra/src/fplot/axfuncs.jl#L18-L24)).

`axplot_many` is **not** currently exported from `MakieExtra`. The spec doesn't change that — exporting can be a separate decision.
