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
