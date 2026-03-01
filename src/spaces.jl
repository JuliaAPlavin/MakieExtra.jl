# --- Coordinate space mixing API ---

struct CoordSpace
    name::Symbol
end

struct InSpace{T<:Real}
    val::T
    space::CoordSpace
end

# Arithmetic: tagging
Base.:*(val::Real, s::CoordSpace) = InSpace(val, s)
Base.:*(s::CoordSpace, val::Real) = InSpace(val, s)

# Arithmetic: scaling InSpace
Base.:*(a::Real, x::InSpace) = InSpace(a * x.val, x.space)
Base.:*(x::InSpace, a::Real) = InSpace(x.val * a, x.space)

# Arithmetic: negation
Base.:-(x::InSpace) = InSpace(-x.val, x.space)
Base.:+(x::InSpace) = x

# Arithmetic: same-space only
function Base.:+(a::InSpace, b::InSpace)
    a.space == b.space || throw(ArgumentError("Cannot add InSpace values in different spaces: $(a.space) and $(b.space)"))
    InSpace(a.val + b.val, a.space)
end
Base.:-(a::InSpace, b::InSpace) = a + (-b)

# Arithmetic: Real + InSpace (bare Real treated as data-space)
Base.:+(a::Real, b::InSpace) = InSpace(a, CoordSpace(:data)) + b
Base.:+(a::InSpace, b::Real) = a + InSpace(b, CoordSpace(:data))
Base.:-(a::Real, b::InSpace) = InSpace(a, CoordSpace(:data)) + (-b)
Base.:-(a::InSpace, b::Real) = a + InSpace(-b, CoordSpace(:data))

# Display
Base.show(io::IO, s::CoordSpace) = print(io, s.name)
Base.show(io::IO, x::InSpace) = print(io, x.val, x.space)

Base.:(==)(a::CoordSpace, b::CoordSpace) = a.name == b.name
Base.:(==)(a::InSpace, b::InSpace) = a.val == b.val && a.space == b.space


# --- Composable constants (not exported, user imports explicitly) ---

module Spaces
    using ..MakieExtra: CoordSpace
    const data = CoordSpace(:data)
    const rel = CoordSpace(:relative)
    const px = CoordSpace(:pixel)
    export data, rel, px
end


# --- spacemix function ---

# Normalize any coord spec to a (value, space_symbol) pair
_to_term(nt::NamedTuple{names}) where names = (only(values(nt)), only(names))
_to_term(x::InSpace) = (x.val, x.space.name)
_to_term(x::Real) = (x, :data)

# Convert a single value from one space to another (pure function, no Observable)
function _convert_single_val(scene, tf, val, from::Symbol, which::Int, to::Symbol)
    from == to && return Float64(val)
    tf_cur = @set tf[3-which] = identity
    dummy = ntuple(i -> i == which ? Float64(val) : 0.0, 2)
    if from == :data
        dummy = map(|>, dummy, tf_cur)
    end
    new = Makie.project(scene.camera, from, to, Point2(dummy))
    if to == :data
        new = Point2(map(|>, new, Accessors.inverse.(tf_cur)))
    end
    Float64(new[which])
end

# Main entry point: 2-arg form (each arg is one axis spec)
function spacemix(ax::Axis, x, y; target::Symbol=:data)
    xval, xspace = _to_term(x)
    yval, yspace = _to_term(y)
    scene = Makie.get_scene(ax)
    lift(scene.camera.projectionview, Makie.plots(ax)[1].model,
         Makie.transform_func(ax), scene.viewport) do _, _, tf, _
        Point2(_convert_single_val(scene, tf, xval, xspace, 1, target),
               _convert_single_val(scene, tf, yval, yspace, 2, target))
    end
end

# 1-arg NamedTuple: field1→x, field2→y
function spacemix(ax::Axis, nt::NamedTuple; target::Symbol=:data)
    ks = keys(nt)
    vs = values(nt)
    spacemix(ax, InSpace(vs[1], CoordSpace(ks[1])),
                 InSpace(vs[2], CoordSpace(ks[2])); target)
end

# Convenience: use current_axis()
spacemix(x, y; kw...) = spacemix(current_axis(), x, y; kw...)
spacemix(t::Union{Tuple,NamedTuple}; kw...) = spacemix(current_axis(), t; kw...)
