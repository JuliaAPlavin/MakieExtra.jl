
_to_axplot(plotfs::Tuple) = (args...; kwargs...) -> multiplot((axplot(plotfs[1]), plotfs[2:end]...), args...; kwargs...)
_to_axplot(plotf::Function) = axplot(plotf)


struct ToAes
    aes::Symbol
    funcs
end

function axplot_many(plotf, fplt::FPlot; kwargs...)
    fig = Figure()
    axplot_many(fig[1,1], plotf, fplt; kwargs...)
    resize_to_layout!()
    fig
end

function axplot_many(pos::Union{GridPosition,GridSubposition}, plotf, fplt::Union{Observable{<:FPlot},FPlot}; legend=(;), linkxaxes=true, linkyaxes=true)
    gl = GridLayout(pos)
	fplt₀ = to_value(fplt)
	color_isnumeric = hasproperty(fplt₀, :color) && fplt₀.color(first(fplt₀.data)) isa Number
    common_kws = (;)
    if hasproperty(fplt₀, :color) && color_isnumeric
        colorrange = @oget fplt₀.colorrange extrema(fplt₀.color.attrs.limit) extrema(fplt₀.color, fplt₀.data)
        common_kws = (;colorrange)
    end
    if any(f -> f isa ToAes && f.aes == :row, fplt₀.argfuncs)
        ix = findonly(f -> f isa ToAes && f.aes == :row, fplt₀.argfuncs)
        af = fplt₀.argfuncs[ix]
        for (irow, f) in enumerate(af.funcs)
            fplt_cur = @set fplt[ix] = f
            @p fplt.data group_vg(fplt.col) enumerate map() do (igr, gr)
                _to_axplot(plotf)(gl[irow, igr], (@set fplt_cur.data = gr); common_kws...,
                                    axis=(;title=irow == 1 ? "$(shortlabel(fplt.col)) = $(key(gr))" : ""))
            end
            linkxaxes && ix == 1 && linkxaxes!(contents(gl[irow, :])...)
            linkyaxes && ix == 2 && linkyaxes!(contents(gl[irow, :])...)
        end
        linkxaxes && ix != 1 && linkxaxes!(contents(gl[:, :])...)
        linkyaxes && ix != 2 && linkyaxes!(contents(gl[:, :])...)
    else
        if haskey(fplt₀, :col) && haskey(fplt₀, :row)
            colixs = @p fplt.data map(fplt.col) unique Dict(__ .=> 1:length(__))
            rowixs = @p fplt.data map(fplt.row) unique Dict(__ .=> 1:length(__))
            @p fplt.data group_vg(x -> (;col=fplt.col(x), row=fplt.row(x))) map() do gr
                rowlabel = "$(shortlabel(fplt.row)) = $(key(gr).row)"
                collabel = "$(shortlabel(fplt.col)) = $(key(gr).col)"
                ir, ic = rowixs[key(gr).row], colixs[key(gr).col]
                _to_axplot(plotf)(
                    gl[ir, ic],
                    (@set fplt.data = gr); common_kws..., axis=(;title=(ic == 1 ? rowlabel : rich(rowlabel; color=:gray70)) * "\n" * (ir == 1 ? collabel : rich(collabel; color=:gray70))))
            end
            linkxaxes && linkxaxes!(contents(gl[:, :])...)
            linkyaxes && linkyaxes!(contents(gl[:, :])...)
        elseif haskey(fplt, :col)
            @p fplt.data group_vg(fplt.col) enumerate map() do (igr, gr)
                _to_axplot(plotf)(gl[1, igr], (@set fplt.data = gr); common_kws..., axis=(;title="$(shortlabel(fplt.col)) = $(key(gr))"))
            end
            linkxaxes && linkxaxes!(contents(gl[:, :])...)
            linkyaxes && linkyaxes!(contents(gl[:, :])...)
        elseif haskey(fplt, :row)
            @p fplt.data group_vg(fplt.row) enumerate map() do (igr, gr)
                _to_axplot(plotf)(gl[igr, 1], (@set fplt.data = gr); common_kws..., axis=(;title="$(shortlabel(fplt.row)) = $(key(gr))"))
            end
            linkxaxes && linkxaxes!(contents(gl[:, :])...)
            linkyaxes && linkyaxes!(contents(gl[:, :])...)
        end
    end
    autohide_axlabels!(gl[:, :]; hidex=linkxaxes, hidey=linkyaxes)

    if hasproperty(fplt, :color) && get(legend, :color, true) && color_isnumeric
        Label(gl[:,end+1][1,1], shortlabel(fplt.color))
        kws = (;)
        if hasproperty(fplt, :colormap)
            kws = (;kws..., colormap=getval(nothing, :colormap, fplt.colormap))
        end
        Colorbar(gl[:,end][2,1]; colorrange, kws...)
    end
end

should_use_categorical(::Type{<:Integer}) = true
should_use_categorical(::Type{<:Real}) = false