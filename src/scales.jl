@kwdef struct SymLog{FS,FL} <: Function
    linthresh::Float64
    base::Float64 = 10.
    linscale::Float64 = 1.
    vmin::Float64 = -Inf
    vmax::Float64 = Inf

    _linscale_adj::Float64 = linscale / (1 - base^-1)
    _fsmall::FS = @o _ * _linscale_adj
    _flarge::FL = @o linthresh * (_linscale_adj + log(base, _ / linthresh))
end

SymLog(linthresh; kwargs...) = SymLog(; linthresh=Float64(linthresh), map(Float64, values(kwargs))...)

function (s::SymLog)(x)
    x = clamp(x, s.vmin, s.vmax)
    if abs(x) < s.linthresh
        return s._fsmall(x)
    else
        return sign(x) * s._flarge(abs(x))
    end
end

InverseFunctions.inverse(s::SymLog) = function(y)
    x = inverse(s._fsmall)(y)
    if abs(x) < s.linthresh
        return x
    else
        return sign(y) * inverse(s._flarge)(abs(y))
    end
end
Makie.inverse_transform(s::SymLog) = inverse(s)


@kwdef struct AsinhScale{F} <: Function
    linthresh::Float64
    vmin::Float64 = -Inf
    vmax::Float64 = Inf

    _a::Float64 = 0.5 * linthresh
    _f::F = @o _a * asinh(_/_a)
end

AsinhScale(linthresh; kwargs...) = AsinhScale(; linthresh=Float64(linthresh), map(Float64, values(kwargs))...)

(s::AsinhScale)(x) = s._f(clamp(x, s.vmin, s.vmax))

InverseFunctions.inverse(s::AsinhScale) = inverse(s._f)
Makie.inverse_transform(s::AsinhScale) = inverse(s)


const SymLogLike = Union{SymLog,AsinhScale}

Makie.defaultlimits(s::SymLogLike) = clamp.((-3, 3), s.vmin, s.vmax)
Makie.defined_interval(::SymLogLike) = -Inf..Inf
