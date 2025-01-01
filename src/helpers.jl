macro define_plotfunc(plotfuncs, Ts)
	plotfuncs = plotfuncs isa Symbol ? [plotfuncs] :
				Base.isexpr(plotfuncs, :tuple) ? plotfuncs.args :
				error()
	Ts = Ts isa Symbol ? [Ts] :
				Base.isexpr(Ts, :tuple) ? Ts.args :
				error()
	exprs = map(plotfuncs) do plotf
		plotf_excl = Symbol(plotf, :!)
		argnames = map(i -> Symbol(:x, i) |> esc, 1:length(Ts))
		args_obs = map((n, T) -> :($n::Observable{<:$T}), argnames, Ts)
		args_any = map((n, T) -> :($n::Union{$T,Observable{<:$T}}), argnames, Ts)
		quote
		    Makie.$plotf(pos::Union{GridPosition, GridSubposition}, $(args_any...); kwargs...) = $plotf(pos, $(map(n -> :(_ensure_observable($n)), argnames)...); kwargs...)
		    Makie.$plotf($(args_any...); kwargs...) = $plotf($(map(n -> :(_ensure_observable($n)), argnames)...); kwargs...)
			
			function Makie.$plotf($(args_obs...); figure=(;), kwargs...)
		        fig = Figure(; figure...)
		        ax, plt = $plotf(fig[1,1], $(argnames...); kwargs...)
		        Makie.FigureAxisPlot(fig, ax, plt)
			end
			
		    function Makie.$plotf(pos::Union{GridPosition, GridSubposition}, $(args_obs...); axis=(;), kwargs...)
		        ax_kwargs = merge($axis_attributes($Plot{$plotf}, $(argnames...); kwargs...), axis)
		        ax = Axis(pos; ax_kwargs...)
		        plt = $plotf_excl(ax, $(argnames...); kwargs...)
		        Makie.AxisPlot(ax, plt)
		    end
		end
	end
	Expr(:block, exprs...)
end

_ensure_observable(x) = Observable(x)
_ensure_observable(x::Observable) = x

function axis_attributes end

axis_attributes(T, args::Vararg{Observable}; kwargs...) = axis_attributes(T, getindex.(args)...; kwargs...)
