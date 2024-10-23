@define_plotfunc (
	scatter, lines, scatterlines,
	stairs, stem,
	errorbars, rangebars, band,
	barplot,
	linesglow, bandstroke) Function

for plotf in (
		:scatter, :lines, :scatterlines,
		:stairs, :stem,
		:errorbars, :rangebars, :band,
		:barplot,
		:linesglow, :bandstroke)
	plotf_excl = Symbol(plotf, :!)

	fullname_excl = isdefined(Makie, plotf) ? :(Makie.$plotf_excl) : :($(@__MODULE__).$plotf_excl)
	@eval function $fullname_excl(ax::Axis, f::Union{Function,Observable{<:Function}}; kwargs...)
		interval = lift(xint, ax.finallimits)
		$plotf_excl(ax, interval, f; merge((; xautolimits=false), kwargs)...)
	end
end

default_axis_attributes(_ignore, ::Function; kwargs...) = (;)

xint(rect::Makie.Rect) = minimum(rect)[1]..maximum(rect)[1]
yint(rect::Makie.Rect) = minimum(rect)[2]..maximum(rect)[2]
