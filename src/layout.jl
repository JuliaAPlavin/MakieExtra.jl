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

macro plt(expr)
    @assert Base.isexpr(expr, :call) "Expected a function call, got: $expr"
    func = expr.args[1] |> esc
    args = expr.args[2:end] .|> esc
    :($SinglePosSpec(pos -> $func(pos, $(args...))))
end

Base.getindex(pos::Union{GridPosition, GridSubposition}, ix::CartesianIndex{2}) = pos[ix[1], ix[2]]
