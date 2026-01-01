struct SinglePosSpec
    func::Function
end

Base.:|(a::SinglePosSpec, b::SinglePosSpec) =
    SinglePosSpec() do pos
        a.func(pos[1,1])
        b.func(pos[1,2])
    end

Base.:/(a::SinglePosSpec, b::SinglePosSpec) =
    SinglePosSpec() do pos
        a.func(pos[1,1])
        b.func(pos[2,1])
    end

Makie.plot(pos, spec::SinglePosSpec) = spec.func(pos)
Makie.plot(pos, spec::Matrix{<:Union{Nothing, SinglePosSpec}}) =
    for (ix, sspec) in zip(CartesianIndices(spec), spec)
        isnothing(sspec) || plot(pos[ix], sspec)
    end
function Makie.plot(spec::Union{SinglePosSpec,Matrix{<:Union{Nothing, SinglePosSpec}}}; figure=(;))
	fig = Figure(;figure...)
	ax, plt = plot(fig[1,1], spec)
	Makie.FigureAxisPlot(fig, ax, plt)
end

macro plt(expr)
    @assert Base.isexpr(expr, :call) "Expected a function call, got: $expr"
    func = expr.args[1] |> esc
    args = expr.args[2:end] .|> esc
    :($SinglePosSpec(pos -> $func(pos, $(args...))))
end
