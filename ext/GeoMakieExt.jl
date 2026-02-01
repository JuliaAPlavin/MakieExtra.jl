module GeoMakieExt

using GeoMakie: GeoMakie, GeoAxis
using MakieExtra
using MakieExtra: @p
using MakieExtra.GeometryBasics
using MakieExtra.IntervalSets
using MakieExtra.IntervalSets: width


# XXX: copied verbatim from GeoMakie, with one addition (see comment)
# should upstream somehow
function Makie.plot!(axis::GeoAxis, plot::Union{Lines,Poly})
    # deal with setting the transform_func correctly
    source = pop!(plot.kw, :source, axis.source)
    transformfunc = lift(GeoMakie.create_transform, axis.dest, source)

    trans = Makie.Transformation(transformfunc; get(plot.kw, :transformation, Attributes())...)
    plot.kw[:transformation] = trans

    # remove the reset_limits kwarg if there is one, this determines whether to automatically reset limits
    # on plot insertion
    reset_limits = to_value(pop!(plot.kw, :reset_limits, true))

	# XXX the only change from GeoMakie, this added:
    if MakieExtra.GEOMAKIE_SPLITWRAP[]
		map!(plot, :converted, :converted) do converted
			only(postprocess_plotargs(axis, typeof(plot), converted))
		end
	    # plot.converted = @lift only(postprocess_plotargs(axis, typeof(plot), $(plot.converted)...))
    end

    # actually plot
    Makie.plot!(axis.scene, plot)

    # reset limits ONLY IF the user has not said otherwise
    if reset_limits
        # some area-like plots basically always look better if they cover the whole plot area.
        # adjust the limit margins in those cases automatically.
        Makie.needs_tight_limits(plot) && Makie.tightlimits!(axis)

        if Makie.is_open_or_any_parent(axis.scene)
            Makie.reset_limits!(axis)
        end
    end

    return plot
end

# XXX: should depend on source and dest projections
_geoaxis_lonrange(ax::GeoAxis) = 0 ± π


postprocess_plotargs(ax::GeoAxis, T::Type{<:AbstractPlot}, convargs...) = @p let
	_split(ax, T, convargs...)
	convert_arguments(T, __...)
end


_split(ax::GeoAxis, T::Type{<:AbstractPlot}, args...) = ((@debug "no _split defined, keeping args as-is" ax T args); args)

_split(ax::GeoAxis, ::Type{<:Poly}, p::Union{Polygon,Rect,Circle}) = @p let
	coordinates(p)
	split_curve(rng=_geoaxis_lonrange(ax), closed=true)
	map(Polygon)
	MultiPolygon
	(__,)
end
_split(ax::GeoAxis, T::Type{<:Poly}, ps::AbstractVector{<:Union{Polygon,Rect,Circle}}) = (
	map(ps) do p
		only(_split(ax, T, p))
	end,
)

_split(ax::GeoAxis, ::Type{<:Lines}, ps::AbstractVector{<:Point2}) = @p let
	ps
	split_curve(rng=_geoaxis_lonrange(ax), closed=false)
	map(LineString)
	MultiLineString
	(__,)
end


function split_curve(data::AbstractVector{<:Point2}; rng::Interval, closed::Bool)
    ε = √eps(eltype(eltype(data)))
    is_wrap(a, b) = let
		Δ = mod(first(a), rng) - mod(first(b), rng)
		abs(mod(Δ, 0±width(rng)/2)) < abs(Δ) * (1 - ε) - ε
	end

	I = eachindex(data)
	if closed
		ixs = findall(i -> is_wrap(data[i], data[mod(i + 1, I)]), I)
		isempty(ixs) && return [data]
		parts = map(ixs .+ 1, circshift(ixs, -1)) do a, b
			wrap_part(data, a, b; rng)
		end
	else
		ixs = findall(i -> is_wrap(data[i], data[i + 1]), I[begin:end-1])
		isempty(ixs) && return [data]
		start_ixs = [firstindex(data); ixs .+ 1]
		end_ixs = [ixs; lastindex(data)]
		map(start_ixs, end_ixs) do a, b
			wrap_part(data, a, b; rng)
		end
	end
end

function wrap_part(data, a::Int, b::Int; rng::Interval)
	I = eachindex(data)
	a, b = mod.((a-1, b+1), Ref(I))
	part = a < b ? data[a:b] : @views [data[a:end]; data[begin:b]]
	part[1] = point_at_wrap(part[2], part[1]; rng)
	part[end] = point_at_wrap(part[end-1], part[end]; rng)
	return part
end

function point_at_wrap(a::T, b::T; rng::Interval) where {T<:Point2}
    ε = √eps(eltype(T))
	zerorng = 0 ± width(rng)/2
	frac = abs(mod(a[1] - minimum(rng), zerorng)) / abs(mod(a[1] - b[1], zerorng)) - ε
	T(
		a[1] + frac*mod(b[1] - a[1], zerorng),
		a[2] + frac*(b[2]-a[2])
	)
end

end
