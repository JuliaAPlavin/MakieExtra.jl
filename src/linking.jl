function link_legend!(axes)
	plts = @getall axes |> RecursiveOfType(Plot) |> If(p -> hasproperty(p, :label))
	palette = @p axes map(_.scene.theme.palette) uniqueonly
	current_attrvals = flatmap(plts) do plt
		map(plt.cycle[]) do key
			(; label=plt.label[], key, value=getproperty(plt, key))
		end
	end
	current_attrvals_perlabel = @p current_attrvals group_vg((;_.label, _.key)) map((;key(_)..., first(_).value))
	target_attrvals = @p current_attrvals_perlabel mapset(value=_.value[]) group_vg((;_.key)) flatmap() do gr
		curpalette = getproperty(palette, key(gr).key)[]
		seenvals = Set()
		map(gr) do r
			if r.value ∈ seenvals
				newval = filterfirst(∉(seenvals), curpalette)
				@set r.value = newval
			else
				push!(seenvals, r.value)
				r
			end
		end
	end
	for plt in plts
		for key in plt.cycle[]
			val = @p target_attrvals filter(_.label == plt.label[] && _.key == key) (@oget first(__).value)
			isnothing(val) && continue
			getproperty(plt, key)[] = val
		end
	end
end

function link_colormap!(plots)
	plt_with_colorrange = @oget filterfirst(p -> p.colorrange[] != Makie.Automatic(), $plots) nothing
	if !isnothing(plt_with_colorrange)
		# found a plot with explicit colorrange, will use it as the reference to set attributes on the others
		otherplots = filter(p -> p !== plt_with_colorrange, plots)
		@assert length(otherplots) == length(plots) - 1
		for key in [:colormap, :colorscale, :colorrange]
			on(getproperty(plt_with_colorrange, key); update=true) do val
				for p in otherplots
					getproperty(p, key)[] = val
				end
			end
		end
	else
		# no plot with explicit colorrange, will use calculated colors
		colormap = @p plots map(_.colormap[]) filterfirst(!isnothing)
		colorscale = @p plots map(_.calculated_colors[].scale[]) filter(_ != identity) (@oget first(__) identity)
		colorrange = @p plots map(_.calculated_colors[].colorrange[]) flatten extrema
		for p in plots
			p.colormap[] = colormap
			p.colorscale[] = colorscale
			p.colorrange[] = colorrange
		end
	end
end
