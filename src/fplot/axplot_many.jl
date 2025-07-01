
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

function axplot_many(pos::Union{GridPosition,GridSubposition}, plotf, fplt::FPlot; legend=(;))
    gl = GridLayout(pos)
    if hasproperty(fplt, :color)
        colorrange = @p fplt.data extrema(fplt.color)
        common_kws = (;colorrange)
    end
    common_kws = (;)
    if any(f -> f isa ToAes && f.aes == :row, fplt.argfuncs)
        ix = findonly(f -> f isa ToAes && f.aes == :row, fplt.argfuncs)
        af = fplt.argfuncs[ix]
        for (irow, f) in enumerate(af.funcs)
            fplt_cur = @set fplt[ix] = f
            @p fplt.data group_vg(fplt.col) enumerate map() do (igr, gr)
                _to_axplot(plotf)(gl[irow, igr], (@set fplt_cur.data = gr); common_kws...,
                                    axis=(;title=irow == 1 ? "$(MakieExtra.shortlabel(fplt.col)) = $(key(gr))" : ""))
            end
            ix == 1 && linkxaxes!(contents(gl[irow, :])...)
            ix == 2 && linkyaxes!(contents(gl[irow, :])...)
        end
        ix != 1 && linkxaxes!(contents(gl[:, :])...)
        ix != 2 && linkyaxes!(contents(gl[:, :])...)
    else
        if haskey(fplt, :col) && haskey(fplt, :row)
            colixs = @p fplt.data map(fplt.col) unique Dict(__ .=> 1:length(__))
            rowixs = @p fplt.data map(fplt.row) unique Dict(__ .=> 1:length(__))
            @p fplt.data group_vg(x -> (;col=fplt.col(x), row=fplt.row(x))) map() do gr
                rowlabel = "$(MakieExtra.shortlabel(fplt.row)) = $(key(gr).row)"
                collabel = "$(MakieExtra.shortlabel(fplt.col)) = $(key(gr).col)"
                ir, ic = rowixs[key(gr).row], colixs[key(gr).col]
                _to_axplot(plotf)(
                    gl[ir, ic],
                    (@set fplt.data = gr); common_kws..., axis=(;title=(ic == 1 ? rowlabel : rich(rowlabel; color=:gray70)) * "\n" * (ir == 1 ? collabel : rich(collabel; color=:gray70))))
            end
            linkxaxes!(contents(gl[:, :])...)
            linkyaxes!(contents(gl[:, :])...)
        elseif haskey(fplt, :col)
            @p fplt.data group_vg(fplt.col) enumerate map() do (igr, gr)
                _to_axplot(plotf)(gl[1, igr], (@set fplt.data = gr); common_kws..., axis=(;title="$(MakieExtra.shortlabel(fplt.col)) = $(key(gr))"))
            end
            linkxaxes!(contents(gl[:, :])...)
            linkyaxes!(contents(gl[:, :])...)
        elseif haskey(fplt, :row)
            @p fplt.data group_vg(fplt.row) enumerate map() do (igr, gr)
                _to_axplot(plotf)(gl[igr, 1], (@set fplt.data = gr); common_kws..., axis=(;title="$(MakieExtra.shortlabel(fplt.row)) = $(key(gr))"))
            end
            linkxaxes!(contents(gl[:, :])...)
            linkyaxes!(contents(gl[:, :])...)
        end
    end
    autohide_axlabels!(gl[:, :])

    if hasproperty(fplt, :color) && get(legend, :color, true)
        Label(gl[:,end+1][1,1], MakieExtra.shortlabel(fplt.color))
        kws = (;)
        if hasproperty(fplt, :colormap)
            kws = (;kws..., colormap=MakieExtra.getval(nothing, :colormap, fplt.colormap))
        end
        Colorbar(gl[:,end][2,1]; colorrange, kws...)
    end
end

should_use_categorical(::Type{<:Integer}) = true
should_use_categorical(::Type{<:Real}) = false