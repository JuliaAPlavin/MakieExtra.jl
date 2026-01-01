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

    # solution by Julius Krumbiegel (jkrumbiegel) on slack
    scene = Makie.get_scene(p)
    glyphcolls = t.plots[1][1]
	bboxes = lift(glyphcolls, scene.camera.projectionview, scene.viewport, padding, tattrs.offset) do glyphcolls, _, _, padding, offset
	    transformed = Makie.apply_transform(t.transformation.transform_func[], t[1][])
	    pos = Makie.project.(Ref(scene.camera), t.space[], t.markerspace[], transformed)
	
	    map(glyphcolls, pos) do glyphcoll, pos
	        rect = Rect2f(Makie.unchecked_boundingbox(glyphcoll, pos, Makie.to_rotation(t.rotation[])))
            @reset rect.origin .+= offset
            isnothing(padding) ? rect : dilate(rect, padding)
	    end
	end
    poly!(p, pattrs, bboxes)

    reverse!(p.plots)
    return p
end
