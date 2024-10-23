@kwdef struct SymLog{FS,FL} <: Function
    linthresh::Float32
    base::Float32 = 10f0
    linscale::Float32 = 1f0
    vmin::Float32 = -Inf32
    vmax::Float32 = Inf32

    _linscale_adj::Float32 = linscale / (1 - base^-1)
    _fsmall::FS = @o _ * _linscale_adj
    _flarge::FL = @o linthresh * (_linscale_adj + log(base, _ / linthresh))
end

SymLog(linthresh; kwargs...) = SymLog(; linthresh=Float32(linthresh), map(Float32, values(kwargs))...)

function (s::SymLog)(x)
    x = clamp(x, s.vmin, s.vmax)
    if abs(x) < s.linthresh
        return s._fsmall(x)
    else
        return sign(x) * s._flarge(abs(x))
    end
end

Makie.inverse_transform(s::SymLog) = function(y)
    x = inverse(s._fsmall)(y)
    if abs(x) < s.linthresh
        return x
    else
        return sign(y) * inverse(s._flarge)(abs(y))
    end
end


@kwdef struct AsinhScale{F} <: Function
    linthresh::Float32
    vmin::Float32 = -Inf32
    vmax::Float32 = Inf32

    _a::Float32 = 0.5f0 * linthresh
    _f::F = @o _a * setinverse(asinh, sinh)(_/_a)
end

AsinhScale(linthresh; kwargs...) = AsinhScale(; linthresh=Float32(linthresh), map(Float32, values(kwargs))...)

(s::AsinhScale)(x) = s._f(clamp(x, s.vmin, s.vmax))

Makie.inverse_transform(s::AsinhScale) = inverse(s._f)


const SymLogLike = Union{SymLog,AsinhScale}

Makie.defaultlimits(s::SymLogLike) = clamp.((-3, 3), s.vmin, s.vmax)
Makie.defined_interval(::SymLogLike) = -Inf..Inf
