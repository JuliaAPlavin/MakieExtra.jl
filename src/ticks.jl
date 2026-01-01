@kwdef struct BaseMulTicks
    subs = nothing
    base = 10.
    k_min::Int = 7
end
BaseMulTicks(subs; kwargs...) = BaseMulTicks(; subs, kwargs...)

function Makie.get_tickvalues(t::BaseMulTicks, vmin, vmax)
    vmin < vmax || return []
    vmin < 0 && vmax ≤ 0 && return .-Makie.get_tickvalues(t, -vmax, -vmin)
    @assert vmin ≥ 0 && vmax ≥ 0
    if !isnothing(t.subs)
        @p [
            mul * t.base^pow
            for pow in floor(Int, log(t.base, vmin) - 0.1):ceil(Int, log(t.base, vmax) + 0.1)
            for mul in t.subs
        ] filter!(∈(vmin..vmax)) map(round(_, sigdigits=4)) map(isinteger(_) ? Int(_) : _)
    else
        for subs in [[1], [1,3], [1,2,5], [1,2,3,5], 1:9]
            ticks = Makie.get_tickvalues((@set t.subs = subs), vmin, vmax)
            length(ticks) ≥ t.k_min && return ticks
        end
        return Makie.get_tickvalues(WilkinsonTicks(5), vmin, vmax)
    end
end

function Makie.get_tickvalues(t::BaseMulTicks, scale::SymLogLike, vmin, vmax; go_to_previous_base_power=false)
    if !isnothing(t.subs)
        n_linticks = max(1.1, ceil(length(t.subs) * (@oget scale.linscale 0.0)))
        mintick = @p let
            min(scale.linthresh / n_linticks, max(abs(vmax), abs(vmin)))
            go_to_previous_base_power ? @modify(l -> floor(l - 0.01) - 0.01, log(t.base, $__)) : __
            max(vmin, __)
        end
        ticks = filter!(∈((vmin..vmax) ∩ (scale.vmin..scale.vmax)), Real[
            reverse(Makie.get_tickvalues(t, vmin, -mintick));
            0;
            Makie.get_tickvalues(t, mintick, vmax);
        ])
        if length(ticks) ≥ 2
            ticks
        else
            if !go_to_previous_base_power
                Makie.get_tickvalues(t, scale, vmin, vmax; go_to_previous_base_power=true)
            else
                Makie.get_tickvalues(WilkinsonTicks(5), vmin, vmax)
            end
        end
    else
        for subs in [[1], [1,3], [1,2,5], [1,2,3,5], 1:9]
            ticks = Makie.get_tickvalues((@set t.subs = subs), scale, vmin, vmax; go_to_previous_base_power)
            length(ticks) ≥ t.k_min && return ticks
        end
        return ticks
    end
end

Makie.get_minor_tickvalues(t::BaseMulTicks, scale, tickvals, vmin, vmax) = Makie.get_tickvalues(t, scale, vmin, vmax)
Makie.get_minor_tickvalues(t::BaseMulTicks, scale::SymLogLike, tickvals, vmin, vmax) = Makie.get_tickvalues(t, scale, vmin, vmax; go_to_previous_base_power=true)

function Makie.get_ticks(ticks, scale::SymLogLike, formatter, vmin, vmax)
    tickvalues = Makie.get_tickvalues(_symlog_ticks(ticks), scale, vmin, vmax)
    (tickvalues, Makie.get_ticklabels(_symlog_formatter(formatter), tickvalues))
end

_symlog_ticks(::Makie.Automatic) = BaseMulTicks()
_symlog_ticks(x) = x

_symlog_formatter(::Makie.Automatic) = Base.Broadcast.BroadcastFunction(x -> Makie.showoff_minus([x])[])
_symlog_formatter(x) = x


"""    EngTicks(kind=:number; suffix="", digits=0, space=true)

Tick formatter that uses the engineering notation: like the scientific notation, but the exponent is always a multiple of 3.
E.g., `10000` becomes `10×10³` when `kind=:number` and `10k` when `kind=:symbol`.

## Arguments
- `kind`: The kind of engineering notation to use. Can be `:number` or `:symbol`
- `suffix`: A string to append to the tick labels, e.g. `suffix="m"` could result in labels like "10 km"
- `digits`: The number of decimal places to display (experimental, may be removed if there are no usecases)
- `space`: Whether to include a space between the number and the suffix
"""
@kwdef struct EngTicks
    kind::Symbol = :number
    suffix::String = ""
    digits::Int = 0
    space::Bool = true
end

EngTicks(kind; kwargs...) = EngTicks(; kind, kwargs...)

Makie.get_ticklabels(t::EngTicks, values) = map(values) do v
    iszero(v) && return string(v)
    pow = log10(abs(v))
    pow3 = @modify(x -> floor(Int, x), $pow / 3)
    suffix = if pow3 == 0
        ""
    elseif t.kind == :number
        rich("×10", superscript(string(pow3)))
    elseif t.kind == :symbol
        si_symbol = Dict(
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
        (t.space ? " " : "") * si_symbol
    else
        error("Unknown EngTicks kind: $(t.kind)")
    end
    rich(f"{v / 10.0^pow3:.{t.digits}f}", suffix, t.suffix)
end


@kwdef struct PercentFormatter
    digits::Int = 0
    sign::Bool = false
end

Makie.get_ticklabels(t::PercentFormatter, values) = map(values) do v
    t.sign ? f"{v * 100:+.{t.digits}f}%" : f"{v * 100:.{t.digits}f}%"
end
