macro define_plotfunc(plotfuncs, Ts)
    plotfuncs = plotfuncs isa Symbol ? [plotfuncs] :
                Base.isexpr(plotfuncs, :tuple) ? plotfuncs.args :
                error()

    Ts = Base.isexpr(Ts, :tuple) ? Ts.args : [Ts]
    Ts = esc.(Ts)

    exprs = map(plotfuncs) do plotf
        plotf_excl = Symbol(plotf, :!)
		plottype = :($Plot{$plotf})
        argnames = map(i -> Symbol(:x, i) |> esc, 1:length(Ts))
        args_obs = map((n, T) -> :($n::Observable{<:$T}), argnames, Ts)
        args_any = map((n, T) -> :($n::Union{$T,Observable{<:$T}}), argnames, Ts)
        quote
            Makie.$plotf(pos::Union{GridPosition, GridSubposition}, $(args_any...); kwargs...) = $plotf(pos, $(map(n -> :(_ensure_observable($n)), argnames)...); kwargs...)
            
            function Makie.$plotf($(args_any...); figure=(;), kwargs...)
                fig = Figure(; figure...)
                ax, plt = $plotf(fig[1,1], $(argnames...); kwargs...)
                Makie.FigureAxisPlot(fig, ax, plt)
            end
            
            function Makie.$plotf(pos::Union{GridPosition, GridSubposition}, $(args_obs...); axis=(;), kwargs...)
                ax_kwargs = merge($default_axis_attributes($plottype, $(argnames...); kwargs...), axis)
                ax = Axis(pos; ax_kwargs...)
                plt = $plotf_excl(ax, $(argnames...); kwargs...)
                Makie.AxisPlot(ax, plt)
            end

            Makie.$plotf_excl($(args_any...); kwargs...) = $plotf_excl(current_axis(), $(argnames...); kwargs...)
        end
    end
    Expr(:block, exprs...)
end


macro define_plotfunc_conv(plotfuncs, Ts)
    plotfuncs = plotfuncs isa Symbol ? [plotfuncs] :
                Base.isexpr(plotfuncs, :tuple) ? plotfuncs.args :
                error()

    Ts = Base.isexpr(Ts, :tuple) ? Ts.args : [Ts]
    Ts = esc.(Ts)

    exprs = map(plotfuncs) do plotf
        plotf_excl = Symbol(plotf, :!)
		plottype = :($Plot{$plotf})
        argnames = map(i -> Symbol(:x, i) |> esc, 1:length(Ts))
        args_any = map((n, T) -> :($n::Union{$T,Observable{<:$T}}), argnames, Ts)
		@assert length(argnames) == 1
		argname = only(argnames)
        axis = esc(:axis)  # otherwise it gensyms
        quote
            function Makie.$plotf(pos::Union{GridPosition, GridSubposition}, $(args_any...); axis=(;), kwargs...)
				used_attrs = used_attributes($plottype, Makie.to_value($argname))
                $axis = merge($default_axis_attributes($plottype, $(argnames...); kwargs...), $axis)
				$plotf(
					pos,
					_lift(
						x -> _convert_arguments_singlestep($plottype, x; _select_kwargs(kwargs, used_attrs)...) |> only,
						$argname);
					axis, _unselect_kwargs(kwargs, used_attrs)...
				)
			end

            function Makie.$plotf($(args_any...); axis=(;), kwargs...)
				used_attrs = used_attributes($plottype, Makie.to_value($argname))
                $axis = merge($default_axis_attributes($plottype, $(argnames...); kwargs...), $axis)
				$plotf(
					_lift(
						x -> _convert_arguments_singlestep($plottype, x; _select_kwargs(kwargs, used_attrs)...) |> only,
						$argname);
					axis, _unselect_kwargs(kwargs, used_attrs)...
				)
			end

            Makie.$plotf_excl($(args_any...); kwargs...) = $plotf_excl(current_axis(), $(argnames...); kwargs...)
            
            function Makie.$plotf_excl(ax::Makie.Block, $(args_any...); kwargs...)
				used_attrs = used_attributes($plottype, Makie.to_value($argname))
                $plotf_excl(ax, 
                    _lift(
                        x -> _convert_arguments_singlestep($plottype, x; _select_kwargs(kwargs, used_attrs)...) |> only,
                        $argname
                    ); _unselect_kwargs(kwargs, used_attrs)...)
            end

			Makie.convert_arguments(ct::Type{<:$plottype}, $(args_any...); kwargs...) =
				convert_arguments(ct, _convert_arguments_singlestep(ct, $(argnames...); kwargs...)...)
        end
    end
    Expr(:block, exprs...)
end


_lift(f, x::Observable) = lift(f, x)
_lift(f, x) = f(x)

_ensure_observable(x) = Observable(x)
_ensure_observable(x::Observable) = x

_select_kwargs(kwargs, ks) = kwargs[convert(Vector{Symbol}, intersect(keys(kwargs), ks))]
_unselect_kwargs(kwargs, ks) = kwargs[convert(Vector{Symbol}, setdiff(keys(kwargs), ks))]


function default_axis_attributes end
default_axis_attributes(T, args::Vararg{Observable}; kwargs...) = default_axis_attributes(T, getindex.(args)...; kwargs...)

function _convert_arguments_singlestep end
