"""    linesglow(positions; kwargs...)

Like `lines()`, but with a glowing effect.
Use `glowwidth`, `glowalpha` and `glowcolor` to control the glow appearance.

Under the hood, `linesglow()` draws multiple lines with increasing width and decreasing alpha to create the glow effect.
"""
@recipe LinesGlow (positions,) begin
    glowwidth = 0
    glowalpha = 1
    glowcolor = nothing
    documented_attributes(Makie.Lines)...
end

Makie.conversion_trait(::Type{<:LinesGlow}) = Makie.PointBased()

function Makie.plot!(p::LinesGlow)
    att = attributes(p)
    nsteps = max(5, ceil(Int, p.glowwidth[] / 2))
    glowcolor = Makie.@lift @something($(p.glowcolor), $(p.color))
    for x in range(1, 0, length=nsteps)
        alpha = (Makie.@lift (1-x)/nsteps*1.5 * $(p.glowalpha))
        linewidth = (Makie.@lift $(att.linewidth) + $(p.glowwidth) * x)
        lines!(p, att, p.positions; color=glowcolor, linewidth, alpha)
    end
    lines!(p, att, p.positions)
    return p
end


"""    textglow(position; kwargs...)

Like `text()` and accepts the same attributes, but glowing doesn't cause artifacts.
"""
@recipe TextGlow (position,) begin
    documented_attributes(Makie.Text)...
end

function Makie.plot!(p::TextGlow)
    att = attributes(p)
    text!(p, att, p.position; color=att.glowcolor)
    text!(p, att, p.position; glowwidth=0)
    return p
end
