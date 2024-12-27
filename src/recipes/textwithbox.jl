@recipe TextWithBox (position,) begin
    poly = Attributes()
    documented_attributes(Makie.Text)...
end

function Makie.plot!(p::TextWithBox)
    tattrs = @delete $(Makie.attributes(p))[:poly]
    pattrs = @p let
        p.poly
        @delete __[:padding]
        @insert __[:space] = :pixel
    end
    t = text!(p, tattrs, p.position)

    padding = get(p.poly, :padding, nothing)

    # XXX: ignores many observable updates, like the text itself or axis properties
    # see https://github.com/MakieOrg/Makie.jl/issues/4632
    rect = @lift @p let
        boundingbox2d(t, :pixel)
        @set __.origin .+= $(tattrs.offset)
        isnothing(padding) ? __ : dilate(__, $padding)
    end
    poly!(p, pattrs, rect)

    reverse!(p.plots)
    return p
end
