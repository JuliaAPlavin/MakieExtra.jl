@recipe ECDFPlotFull (xint::Union{Nothing,Interval}, values::AbstractVector{<:Number}) begin
    rev = false
    documented_attributes(Lines)...
    @modify($(documented_attributes(Scatter)).d) do d
        filter_keys(∉(keys(documented_attributes(Lines).d)), d)
    end...
end

function Makie.plot!(p::ECDFPlotFull)
    vs = @lift sort($(p.values); rev=$(p.rev))
    n = @lift length($vs)
    
    lrval = @lift if !isnothing($(p.xint))
        eps = extrema($(p.xint))
        $(p.rev) ? reverse(eps) : eps
    else
        (first($vs), last($vs))
    end

    # xautolimits=false below don't seem to work
    # interval = @something p.xint[] let
    # 	scene = Makie.get_scene(p)
    #     lift(scene.camera.projectionview, p.model, Makie.transform_func(p), scene.viewport) do _...
    # 		left, _ = Makie.project(scene, :relative, :data, Point(0,0))
    # 		right, _ = Makie.project(scene, :relative, :data, Point(1,0))
    # 		left..right
    #     end
    # end
    

    scatter!(
        p, attributes(p),
        vs, @lift (1:$n) ./ $n)

    lines!(
        p, attributes(p),
        (@lift [first($lrval); repeat($vs, inner=2); last($lrval)]),
        (@lift repeat((0:$n) ./ $n, inner=2));
        # xautolimits=false  # XXX: doesn't work at all
    )

    return p
end

Makie.convert_arguments(ct::Type{ECDFPlotFull}, values::AbstractVector{<:Number}) = convert_arguments(ct, nothing, values)
