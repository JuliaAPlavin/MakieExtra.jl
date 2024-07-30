filter_keys(pred, d::Dict) = Dict(k => v for (k, v) in pairs(d) if pred(k))

@recipe ArrowLines () begin
    arrowstyle = "-|>"
    documented_attributes(Lines)...
    @modify($(documented_attributes(Scatter)).d) do d
        filter_keys(∉(keys(documented_attributes(Lines).d)), d)
    end...
end

function Makie.plot!(p::ArrowLines)
    points = p[1]
    @assert length(points[]) == 2
    
    scene = Makie.get_scene(p)
    ps_pix = lift(scene.camera.projectionview, p.model, Makie.transform_func(p), scene.viewport, points) do _, _, _, _, ps
        return Makie.project.(Ref(scene), ps)
    end
    markerangle = @lift atan(reverse($ps_pix[2] - $ps_pix[1])...)

    ast = @lift parse_arrowstyle($(p.arrowstyle))

    attrs = @p let
        Makie.shared_attributes(p, Lines)
        @set __[:linestyle] = @lift $ast.linestyle
    end
    lines!(p, attrs, points)
    if !isnothing(ast[].lm)
        attrs = @p let
            Makie.shared_attributes(p, Scatter)
            @set __[:marker] = @lift $ast.lm
            @set __[:rotation] = @lift $markerangle + deg2rad(180)
        end
        scatter!(p, attrs, @lift $points[1])
    end
    if !isnothing(ast[].rm)
        attrs = @p let
            Makie.shared_attributes(p, Scatter)
            @set __[:marker] = @lift $ast.rm
            @set __[:rotation] = markerangle
        end
        scatter!(p, attrs, @lift $points[2])
    end
end


const marker_l_to_r = Dict(
	"" => "",
	"<" => ">",
	"<|" => "|>",
	">" => "<",
	"|>" => "<|",
)

const marker_rs = Dict(
	"" => nothing,
	">" => Makie.Polygon(Point2f[(0, 0), (-1, 0.5), (-0.5, 0), (-1, -0.5)]),
	"|>" => Makie.Polygon(Point2f[(0, 0), (-1, 0.5), (-1, -0.5)]),
	"<" => Makie.Polygon(Point2f[(-1, 0), (0, 0.5), (-0.5, 0), (0, -0.5)]),
	"<|" => Makie.Polygon(Point2f[(-1, 0), (0, 0.5), (0, -0.5)]),
)

function split_arrowstyle(s)
	lmks = filter(mk -> startswith(s, mk), keys(marker_l_to_r))
	rmks = filter(mk -> endswith(s, mk), keys(marker_rs))
	lmk = isempty(lmks) ? nothing : argmax(length, lmks)
	rmk = isempty(rmks) ? nothing : argmax(length, rmks)
	linek = @p s chopprefix(__, lmk) chopsuffix(__, rmk)
	(
		lmk=lmk,
		rmk=rmk,
		linek,
	)
end

function parse_arrowstyle(s::AbstractString)
	(;lmk, rmk, linek) = split_arrowstyle(s)
	(
		lm=marker_rs[marker_l_to_r[lmk]],
		rm=marker_rs[rmk],
		linestyle=Dict(
			"-" => nothing,
			"--" => :dash,
			".." => :dot,
		)[linek],
	)
end