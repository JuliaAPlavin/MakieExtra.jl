@kwdef struct BaseMulTicks
    subs = [1, 2, 5]
    base = 10.
end
BaseMulTicks(subs; kwargs...) = BaseMulTicks(; subs, kwargs...)

function Makie.get_tickvalues(t::BaseMulTicks, vmin, vmax)
    vmin < 0 && vmax < 0 && return .-Makie.get_tickvalues(t, -vmax, -vmin)
    @assert vmin > 0 && vmax > 0
    filter!(∈(vmin..vmax), [
        mul * t.base^pow
        for pow in floor(Int, log(t.base, vmin) - 0.1):ceil(Int, log(t.base, vmax) + 0.1)
        for mul in t.subs
    ])
end

Makie.get_tickvalues(t::BaseMulTicks, scale::SymLogLike, vmin, vmax) = filter!(∈((vmin..vmax) ∩ (scale.vmin..scale.vmax)), [
    Makie.get_tickvalues(t, max(vmin, scale.linthresh/3), vmax);
    Makie.get_tickvalues(t, vmin, min(vmax, -scale.linthresh/3));
    0
])


function Makie.get_ticks(ticks, scale::SymLogLike, formatter, vmin, vmax)
    tickvalues = Makie.get_tickvalues(_symlog_ticks(ticks), scale, vmin, vmax)
    (tickvalues, Makie.get_ticklabels(_symlog_formatter(formatter), tickvalues))
end

_symlog_ticks(::Makie.Automatic) = BaseMulTicks([1])
_symlog_ticks(x) = x

_symlog_formatter(::Makie.Automatic) = Base.Broadcast.BroadcastFunction(x -> Makie.showoff_minus([x])[])
_symlog_formatter(x) = x


@kwdef struct EngTicks
    kind::Symbol = :number
    digits::Int = 0
end

EngTicks(kind; kwargs...) = EngTicks(; kind, kwargs...)

Makie.get_ticklabels(t::EngTicks, values) = map(values) do v
    iszero(v) && return string(v)
    pow = log10(abs(v))
    pow3 = @modify(x -> floor(Int, x), $pow / 3)
    suffix = if t.kind == :number
        rich("×10", superscript(string(pow3)))
    elseif t.kind == :symbol
        " " * Dict(
            -15 => "f",
            -12 => "p",
            -9 => "n",
            -6 => "μ",
            -3 => "m",
            0 => "",
            3 => "k",
            6 => "M",
            9 => "G",
            12 => "T",
            15 => "P",
            18 => "E",
        )[pow3]
    end
    rich(f"{v / 10.0^pow3:.{t.digits}f}", suffix)
end
