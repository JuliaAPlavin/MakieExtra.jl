_to_axplot(plotfs::Tuple) = (args...; kwargs...) -> multiplot((axplot(plotfs[1]), plotfs[2:end]...), args...; kwargs...)
_to_axplot(plotf::Function) = axplot(plotf)


"""
    ToAes(aes::Symbol, funcs::Tuple)

Marks an `FPlot` arg/kwarg position as the `axplot_many` faceting driver for a
grid axis (`aes ∈ (:row, :col)`). The dimension expands to `length(funcs)`,
each cell substituting the corresponding func at that position. Multiple
`ToAes` markers sharing one axis run as a parallel zip — they must all have
the same length.
"""
struct ToAes
    aes::Symbol
    funcs::Tuple

    function ToAes(aes::Symbol, funcs)
        @assert aes in (:col, :row)
        isempty(funcs) && throw(ArgumentError("ToAes funcs tuple must not be empty"))
        new(aes, Tuple(funcs))
    end
end


# --- Driver types ---

"Faceting driver from `fplt.col`/`fplt.row` kwarg-funcs: groups data by `func` and produces one cell per unique value in first-occurrence order."
struct KwargFacet
    axis::Symbol
    func
end

"""
Faceting driver from one or more `ToAes(axis, …)` markers on the same grid
axis. `positions` mixes argfunc indices (`Int`) and kwargfunc keys (`Symbol`);
`funcs_per_pos` is the parallel-zip table of per-cell functions, one tuple per
position, all with equal length.
"""
struct ToAesZip
    axis::Symbol
    positions::Vector{Union{Int,Symbol}}
    funcs_per_pos::Vector
end

"Per-axis driver: `nothing` (no driver), `KwargFacet`, or `ToAesZip`."
const Driver = Union{Nothing,KwargFacet,ToAesZip}


"""
    detect_driver(fplt₀, axis) :: Driver

Identify the faceting driver for `axis ∈ (:row, :col)` by scanning `fplt₀`'s
kwargfuncs for the literal key and its argfuncs/kwargfuncs for `ToAes(axis, …)`
markers. Throws when a kwarg-facet and a `ToAes` driver co-occur on the same
axis, or when parallel-zip lengths disagree.
"""
function detect_driver(fplt₀::FPlot, axis::Symbol)::Driver
    arg_hits = [(i, f.funcs) for (i, f) in pairs(fplt₀.argfuncs) if f isa ToAes && f.aes == axis]
    kw_hits = [(k, f.funcs) for (k, f) in pairs(fplt₀.kwargfuncs) if k != axis && f isa ToAes && f.aes == axis]
    has_kwarg = haskey(fplt₀, axis)

    if has_kwarg && !(isempty(arg_hits) && isempty(kw_hits))
        throw(ArgumentError("axplot_many: axis $axis has both a kwarg-facet driver ($axis=...) and a ToAes driver"))
    end

    if has_kwarg
        return KwargFacet(axis, fplt₀[axis])
    end

    positions = Union{Int,Symbol}[]
    funcs_per_pos = Any[]
    for (i, fs) in arg_hits
        push!(positions, i); push!(funcs_per_pos, fs)
    end
    for (k, fs) in kw_hits
        push!(positions, k); push!(funcs_per_pos, fs)
    end
    isempty(positions) && return nothing

    n = length(first(funcs_per_pos))
    all(length(fs) == n for fs in funcs_per_pos) ||
        throw(ArgumentError("axplot_many: parallel ToAes on axis $axis have mismatched lengths $(map(length, funcs_per_pos))"))
    return ToAesZip(axis, positions, funcs_per_pos)
end


# --- AxisSpec: per-cell facts for one axis, eagerly precomputed ---

"""
Per-cell facts along one grid axis, precomputed once at construction:
- `n` — number of cells along this axis;
- `subs[i]` — `pos => func` substitutions to apply for cell `i`;
- `filters[i]` — data-filter predicate (or `nothing`) for cell `i`;
- `titles[i]` — raw title contribution (string, before graying).
"""
struct AxisSpec
    n::Int
    subs::Vector{Vector{Pair}}
    filters::Vector
    titles::Vector
end

"Build the `AxisSpec` for one grid axis given its `Driver` and the source `FPlot`."
build_axis_spec(::Nothing, ::FPlot) = AxisSpec(1, [Pair[]], [nothing], [""])

function build_axis_spec(d::KwargFacet, fplt₀::FPlot)
    groups = group_vg(d.func, fplt₀.data)
    keys_ = map(DataManipulation.key, groups)
    n = length(keys_)
    f = d.func
    label = shortlabel(f)
    titles = ["$label = $k" for k in keys_]
    filters = [let kk=k; x -> f(x) == kk end for k in keys_]
    AxisSpec(n, [Pair[] for _ in 1:n], filters, titles)
end

function build_axis_spec(d::ToAesZip, ::FPlot)
    n = length(first(d.funcs_per_pos))
    subs = [Pair[pos => fs[i] for (pos, fs) in zip(d.positions, d.funcs_per_pos)] for i in 1:n]
    titles = [
        join(
            ["$pos: $(shortlabel(fs[i]))" for (pos, fs) in zip(d.positions, d.funcs_per_pos) if pos isa Symbol],
            ", ",
        )
        for i in 1:n
    ]
    AxisSpec(n, subs, fill(nothing, n), titles)
end


# --- Cell construction ---

"""
Derive a single cell's `FPlot` from `fplt`: substitute each `pos => func` from
`subs`, drop the consumed `:col`/`:row` faceting kwargs, and (when `pred !==
nothing`) restrict `data` to the filtered slice.
"""
function apply_cell_transform(fplt::FPlot, subs::Vector{Pair}, pred)
    g = fplt
    for (pos, f) in subs
        g = @set g[pos] = f
    end
    haskey(g, :col) && (g = @delete g[:col])
    haskey(g, :row) && (g = @delete g[:row])
    if !isnothing(pred)
        g = @set g.data = filter(pred, g.data)
    end
    return g
end

"""
Build the per-cell `FPlot`. Static input applies the transform eagerly;
`Observable`/`AbstractNode` input is lifted so the cell's structure (`subs`,
`pred`) stays frozen at construction while `data` and other attrs flow through
reactively.
"""
build_cell_fplt(fplt::FPlot, subs, pred) = apply_cell_transform(fplt, subs, pred)
build_cell_fplt(fplt::Union{Observable,MyObservables.AbstractNode}, subs, pred) =
    MyObservables.lift(FPlot, f -> apply_cell_transform(f, subs, pred), fplt)


"Combine row/col data-filter predicates with logical AND; `nothing` means no filter on that side."
combine_preds(::Nothing, ::Nothing) = nothing
combine_preds(p, ::Nothing) = p
combine_preds(::Nothing, p) = p
combine_preds(rp, cp) = x -> rp(x) && cp(x)


# --- Title composition ---

"""
    compose_title(rtitle, ctitle, irow, icol, nrows, ncols)

Compose a cell's title from its row and column contributions. Repeats are
grayed via `rich(s; color=:gray70)`: the row contribution is grayed past the
first column (when `ncols > 1`); the col contribution is grayed past the
first row (when `nrows > 1`).
"""
function compose_title(rtitle, ctitle, irow::Int, icol::Int, nrows::Int, ncols::Int)
    rt = (icol > 1 && ncols > 1 && rtitle != "") ? rich(rtitle; color=:gray70) : rtitle
    ct = (irow > 1 && nrows > 1 && ctitle != "") ? rich(ctitle; color=:gray70) : ctitle
    join_title(rt, ct)
end

"Join non-empty title parts with `\"\\n\"`. Plain `String` if all parts are strings, otherwise a `rich(...)` interleaving them."
function join_title(parts...)
    nonempty = filter(p -> !(p isa AbstractString && isempty(p)), collect(parts))
    isempty(nonempty) && return ""
    length(nonempty) == 1 && return only(nonempty)
    if all(p -> p isa AbstractString, nonempty)
        return join(nonempty, "\n")
    else
        pieces = Any[]
        for (i, p) in enumerate(nonempty)
            i > 1 && push!(pieces, "\n")
            push!(pieces, p)
        end
        return rich(pieces...)
    end
end


# --- Color attributes ---

"Is `c` a value `axplot_many` should attempt to call on a data point to decide if color is numeric? Excludes `AsCategorical`/`ToAes`/`Ref` wrappers."
is_color_callable(c) = !(c isa Union{AsCategorical,ToAes,Ref})

"""
    color_state(fplt₀) -> (; isnumeric, common_kws)

Decide whether `fplt₀.color` produces a numeric value, and if so collect the
shared color attributes (`colorrange`, `colorscale`, `colormap`, `lowclip`,
`highclip`, `nan_color`) — `Ref`-unwrapped — to forward uniformly to every
subplot and the shared `Colorbar`.
"""
function color_state(fplt₀::FPlot)
    if !hasproperty(fplt₀, :color)
        return (isnumeric=false, common_kws=(;))
    end
    c = fplt₀.color
    isnumeric =
        is_color_callable(c) &&
        !isempty(fplt₀.data) &&
        applicable(c, first(fplt₀.data)) &&
        c(first(fplt₀.data)) isa Number
    if !isnumeric
        return (isnumeric=false, common_kws=(;))
    end
    common = (;)
    cr = @oget fplt₀.colorrange extrema(fplt₀.color.attrs.limit) extrema(fplt₀.color, fplt₀.data)
    common = @insert common.colorrange = cr
    cs = @oget fplt₀.colorscale fplt₀.color.attrs.scale
    isnothing(cs) || (common = @insert common.colorscale = (cs isa Ref ? cs[] : cs))
    for k in (:colormap, :lowclip, :highclip, :nan_color)
        hasproperty(fplt₀, k) || continue
        v = getproperty(fplt₀, k)
        common = @insert common[k] = (v isa Ref ? v[] : v)
    end
    return (isnumeric=true, common_kws=common)
end


# --- Linking + label hiding ---

"Variation along physical axis `idx` (1 = X, 2 = Y): `:none`, `:row`, or `:col` — read off whether `argfuncs[idx]` is a `ToAes` and which axis it drives."
function arg_var_at(fplt₀::FPlot, idx::Int)
    idx > length(fplt₀.argfuncs) && return :none
    f = fplt₀.argfuncs[idx]
    f isa ToAes ? f.aes : :none
end

"Apply `linkfn` (`linkxaxes!` / `linkyaxes!`) to a slice of axes; no-op on slices with fewer than 2 axes."
function maybe_link!(linkfn, axs)
    axs2 = filter(!isnothing, axs)
    length(axs2) >= 2 && linkfn(axs2...)
end

"""
Link X and Y axes per the variation pattern: per-row when a `ToAes(:row, …)`
drives that physical axis, per-col for `:col`, otherwise across the whole
grid. `linkxaxes=false` / `linkyaxes=false` suppresses the corresponding side.
"""
function apply_linking!(axes_mat, x_var, y_var; linkxaxes::Bool, linkyaxes::Bool)
    nrows, ncols = size(axes_mat)
    if linkxaxes
        if x_var === :row
            for r in 1:nrows
                maybe_link!(linkxaxes!, axes_mat[r, :])
            end
        elseif x_var === :col
            for c in 1:ncols
                maybe_link!(linkxaxes!, axes_mat[:, c])
            end
        else
            maybe_link!(linkxaxes!, vec(axes_mat))
        end
    end
    if linkyaxes
        if y_var === :row
            for r in 1:nrows
                maybe_link!(linkyaxes!, axes_mat[r, :])
            end
        elseif y_var === :col
            for c in 1:ncols
                maybe_link!(linkyaxes!, axes_mat[:, c])
            end
        else
            maybe_link!(linkyaxes!, vec(axes_mat))
        end
    end
end


# --- Plot result destructuring ---

"Extract the `Axis` from a `_to_axplot` cell result (an `AxisPlot` directly, or the first element of a `multiplot` tuple)."
extract_axis(r) = r.axis
extract_axis(r::Tuple) = extract_axis(r[1])


# --- Public API ---

"""
    axplot_many(plotf, fplt; legend=(;), linkxaxes=true, linkyaxes=true)
    axplot_many(pos,  plotf, fplt; legend=(;), linkxaxes=true, linkyaxes=true)

Build a 2-D grid of `axplot`-style subplots from one `FPlot` (or
`Observable`/`AbstractNode` thereof). Each grid axis (`row`, `col`) is driven
by either a kwarg-facet (`fplt.col` / `fplt.row`) or one or more `ToAes(:row,
…)` / `ToAes(:col, …)` markers among `fplt`'s argfuncs/kwargfuncs (multiple
markers on the same axis run as a parallel zip). Each cell receives an
auto-generated title; the matching label-hiding and axis-linking follow which
physical axes vary across the grid. `legend=(;color=false)` suppresses the
shared `Colorbar`.

Returns `(; figure, gl, axes, plots, colorbar)`. The top-level form opens its
own `Figure`; the positional form embeds into `pos` and reports
`figure=nothing`.

See `axplot_many_design.md` for the full semantics.
"""
function axplot_many(plotf, fplt::Union{FPlot,Observable{<:FPlot},MyObservables.AbstractNode{<:FPlot}};
                    legend=(;), linkxaxes::Bool=true, linkyaxes::Bool=true)
    fig = Figure()
    inner = _axplot_many_inner(fig[1, 1], plotf, fplt; legend, linkxaxes, linkyaxes)
    resize_to_layout!(fig)
    return (; figure=fig, inner...)
end

function axplot_many(pos::Union{GridPosition,GridSubposition}, plotf,
                    fplt::Union{FPlot,Observable{<:FPlot},MyObservables.AbstractNode{<:FPlot}};
                    legend=(;), linkxaxes::Bool=true, linkyaxes::Bool=true)
    inner = _axplot_many_inner(pos, plotf, fplt; legend, linkxaxes, linkyaxes)
    return (; figure=nothing, inner...)
end


"Inner method shared by both `axplot_many` overloads: builds the `GridLayout`, renders every cell, links axes, hides redundant labels, and emits the shared `Colorbar` when applicable."
function _axplot_many_inner(pos, plotf, fplt; legend, linkxaxes, linkyaxes)
    fplt₀ = to_value(fplt)
    gl = GridLayout(pos)

    row_drv = detect_driver(fplt₀, :row)
    col_drv = detect_driver(fplt₀, :col)

    row_spec = build_axis_spec(row_drv, fplt₀)
    col_spec = build_axis_spec(col_drv, fplt₀)
    nrows, ncols = row_spec.n, col_spec.n

    cs = color_state(fplt₀)

    axes_mat = Matrix{Axis}(undef, nrows, ncols)
    plots_mat = Matrix{Any}(undef, nrows, ncols)

    for irow in 1:nrows, icol in 1:ncols
        subs = vcat(row_spec.subs[irow], col_spec.subs[icol])
        pred = combine_preds(row_spec.filters[irow], col_spec.filters[icol])

        # Every cell is rendered, even when the data filter currently yields no points.
        # Keeps the layout consistent and lets Observable updates populate cells whose
        # initial (row, col) combination had no data.
        cell_fplt = build_cell_fplt(fplt, subs, pred)

        auto_axis = (;
            title=compose_title(row_spec.titles[irow], col_spec.titles[icol], irow, icol, nrows, ncols),
        )

        res = _to_axplot(plotf)(gl[irow, icol], cell_fplt; cs.common_kws..., axis=auto_axis)
        axes_mat[irow, icol] = extract_axis(res)
        plots_mat[irow, icol] = res
    end

    x_var = arg_var_at(fplt₀, 1)
    y_var = arg_var_at(fplt₀, 2)
    apply_linking!(axes_mat, x_var, y_var; linkxaxes, linkyaxes)

    hidex = linkxaxes && x_var !== :row
    hidey = linkyaxes && y_var !== :col
    autohide_axlabels!(gl[:, :]; hidex, hidey)

    cb = nothing
    if cs.isnumeric && get(legend, :color, true)
        Label(gl[:, end+1][1, 1], shortlabel(fplt₀.color))
        cb_kws = (;)
        for (k, v) in pairs(cs.common_kws)
            if k === :colorscale
                cb_kws = @insert cb_kws.scale = v
            elseif k in (:colormap, :colorrange, :lowclip, :highclip)
                cb_kws = @insert cb_kws[k] = v
            end
        end
        cb = Colorbar(gl[:, end][2, 1]; cb_kws...)
    end

    return (; gl, axes=axes_mat, plots=plots_mat, colorbar=cb)
end
