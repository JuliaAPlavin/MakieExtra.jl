@define_plotfunc (scatter, lines, scatterlines, band, stairs, stem, barplot) Function 

for plotf in (:scatter, :lines, :scatterlines, :band, :errorbars, :rangebars, :stairs, :stem, :barplot)
	plotf_excl = Symbol(plotf, :!)

	@eval function Makie.$plotf_excl(ax, f::Union{Function,Observable{<:Function}}; kwargs...)
		interval = lift(xint, ax.finallimits)
		$plotf_excl(ax, interval, f; kwargs...)
	end
end

default_axis_attributes(_, ::Function) = (;)

xint(rect::Makie.Rect) = minimum(rect)[1]..maximum(rect)[1]

function Makie.convert_arguments(P::Type{<:Band}, i::AbstractInterval, f::Function)
    x, y = Makie.PlotUtils.adapted_grid(x -> Makie.mean(f(x)), endpoints(i))
    return convert_arguments(P, x, f.(x))
end
