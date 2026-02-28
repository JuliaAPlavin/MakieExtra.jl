"""    textwithbox(position; kwargs...)

Like `text()` and supports all `text()` attributes, but also draws a box around the text for legibility.

The box is drawn with the `poly()` recipe, pass required attributes as the `poly=...` argument.
Also, the `poly.padding::Rect` attribute can be used to add padding around the text, measured in pixels.
"""
@recipe TextWithBox (position,) begin
    poly = Attributes()
    documented_attributes(Makie.Text)...
end

function Makie.plot!(p::TextWithBox)
    attrs = attributes(p)
    textlabel!(p, attrs, p.position; cornerradius=0, background_color=get(p.poly[], :color, :white), padding=get(p.poly[], :padding, 0), text_align=p.align)
end
