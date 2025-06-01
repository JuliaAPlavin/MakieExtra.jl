"""    bandstroke(x, lowerupper; kwargs...)

Like `band()`, but strokes the band with lines on the lower and upper sides.
Propagates all supported line attributes from the call, adds `strokewidth` and `strokecolor` attributes to override them when needed.
"""
@recipe BandStroke begin
    strokewidth = 1
    strokecolor = nothing
    Makie.MakieCore.documented_attributes(Makie.Band)...
end

# explicitly define same convert_arguments methods as Band does
# catch-all convert_arguments(::Type{<:BandStroke}, args...) would cause many ambiguities
# for m in Makie.methodswith(Type{<:Band}, convert_arguments)
#     @assert m.sig isa DataType
#     atypes = m.sig.parameters[3:end]
#     anames = [Symbol("arg", i) for i in 1:length(atypes)]
#     atyped = [:($n::$t) for (n, t) in zip(anames, atypes)]
#     @eval Makie.convert_arguments(::Type{<:BandStroke}, $(atyped...)) = convert_arguments(Band, $(anames...))
# end

function Makie.plot!(p::BandStroke)
    pb = band!(p, Makie.shared_attributes(p, Band), p.args...)
    att = @p let
        Makie.shared_attributes(p, Lines)
        @set __[:linewidth] = p.strokewidth
        @set __[:color] = @lift something($(p.strokecolor), $(p.color))
    end
    # use pb[] instead of p[] to ensure all Band conversions are performed
    # is it possible to miss the convert_arguments() methods defined above?
	if p.direction[] == :y
	    lines!(p, att, @lift reverse.($(pb[1])))
	    lines!(p, att, @lift reverse.($(pb[2])))
	else
		@assert p.direction[] == :x
	    lines!(p, att, pb[1])
	    lines!(p, att, pb[2])
	end
    return p
end


function Makie.convert_arguments(P::Type{<:BandStroke}, i::AbstractInterval, f::Function)
    # f() returns interval for this plottype
    x, y = Makie.PlotUtils.adapted_grid(x -> Makie.mean(f(x)), endpoints(i))
    return convert_arguments(P, x, f.(x))
end
