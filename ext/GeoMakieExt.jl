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
		splice_converted!(plot) do converted
			postprocess_plotargs(axis, typeof(plot), converted...)
		end
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

function Makie.plot!(axis::GeoAxis, plot::Makie.PlotList)
    source = pop!(plot.kw, :source, axis.source)
    transformfunc = lift(GeoMakie.create_transform, axis.dest, source)

    trans = Makie.Transformation(transformfunc; get(plot.kw, :transformation, Attributes())...)
    plot.kw[:transformation] = trans

    reset_limits = to_value(pop!(plot.kw, :reset_limits, true))

    # PlotList reads :converted directly (not through the destructure edge),
    # so splice_converted! alone doesn't help. We splice AND redirect :converted
    # to point to the transformed node, so the PlotList recipe picks up split data.
    if MakieExtra.GEOMAKIE_SPLITWRAP[]
        splice_converted!(plot) do converted
            map(c -> _transform_plotspecs(axis, c), converted)
        end
        plot.attributes.outputs[:converted] = plot.attributes.outputs[:_converted_split]
    end

    Makie.plot!(axis.scene, plot)

    if reset_limits
        Makie.needs_tight_limits(plot) && Makie.tightlimits!(axis)
        if Makie.is_open_or_any_parent(axis.scene)
            Makie.reset_limits!(axis)
        end
    end

    return plot
end

_transform_plotspecs(axis, spec::Makie.PlotSpec) = let
    T = Makie.plottype(spec)
    if T <: Union{Lines, Poly}
        split_args = postprocess_plotargs(axis, T, Makie.convert_arguments(T, spec.args...)...)
        Makie.PlotSpec(T, split_args...; spec.kwargs...)
    else
        spec
    end
end
_transform_plotspecs(_, x) = x

# Splice a processing step between :converted and its downstream consumers in the ComputeGraph.
# Creates :converted → f → :_converted_split, then rewires the destructure edge to read from :_converted_split.
# Must be called before the plot is added to a scene (before any TypedEdge is created).
# Relies on ComputeGraph internals; assertions guard against unexpected Makie changes.
function splice_converted!(f, plot)
    attr = plot.attributes

    @assert haskey(attr.outputs, :converted) "Expected :converted node in plot ComputeGraph"
    converted_node = attr.outputs[:converted]
    conv_edge = converted_node.parent

    # Create split node: :converted → f → :_converted_split
    @assert !haskey(attr.outputs, :_converted_split) "splice_converted! already applied to this plot"
    map!(f, attr, :converted, :_converted_split)
    split_node = attr.outputs[:_converted_split]
    split_edge = split_node.parent

    # Find the destructure edge (produces :polygon, :arg1, etc.)
    other_deps = [e for e in conv_edge.dependents if e !== split_edge]
    @assert length(other_deps) == 1 "Expected exactly 1 other dependent on conversion edge (the destructure edge), got $(length(other_deps))"
    destr_edge = only(other_deps)
    @assert !isassigned(destr_edge.typed_edge) "Destructure edge TypedEdge already created — splice_converted! must be called before the plot is rendered"

    # Rewire: destructure reads from split_node instead of converted_node
    idx = findfirst(n -> n === converted_node, destr_edge.inputs)
    @assert !isnothing(idx) "Destructure edge does not have :converted as input"
    destr_edge.inputs[idx] = split_node

    # Fix dependency chain
    filter!(e -> e !== destr_edge, conv_edge.dependents)
    push!(split_edge.dependents, destr_edge)
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
	segments = [eltype(data)[]]

	# Iterate edges: n-1 for open, n for closed (includes closing edge)
	for i in (closed ? I : I[begin:end-1])
		j = closed ? mod(i + 1, I) : i + 1
		push!(last(segments), data[i])
		if is_wrap(data[i], data[j])
			push!(last(segments), point_at_wrap(data[i], data[j]; rng))
			push!(segments, [point_at_wrap(data[j], data[i]; rng)])
		end
	end

	if closed
		# Merge: last segment (after final wrap) connects to first (before first wrap)
		length(segments) > 1 && prepend!(segments[1], pop!(segments))
	else
		push!(last(segments), data[end])
	end

	length(segments) == 1 && return [data]
	return segments
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
