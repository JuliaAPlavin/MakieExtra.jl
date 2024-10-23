@recipe(Scalebar, scale) do scene
    Attributes(
        position=Point2(0.85, 0.08),
        target_ax_frac=0.2,
        muls=[x*p for p in Real[1e-9, 1e-8, 1e-7, 1e-5, 1e-4, 1e-3, 0.01, 0.1, 1, 10, 100, 1000, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9] for x in [1, 2, 5]]
    )
end

function Makie.plot!(p::Scalebar)
    target_ax_frac = 0.2

    scene = Makie.parent_scene(p)
    @assert Makie.transform_func(scene)[1] == identity

    obs = @lift let
        xlims = @p let
            $(Makie.projview_to_2d_limits(p))
            first.(extrema(__))
            Interval(__...)
        end

        units_in_data = units_in_dataunit($(p.scale))
        mul = argmin(m -> abs(1 / units_in_data * m - target_ax_frac * width(xlims)), $(p.muls))
        length_data = 1 / units_in_data * mul

        length_ax = length_data / width(xlims)
        avgpos = $(p.position)
        points = [avgpos - Point2(length_ax/2, 0), avgpos + Point2(length_ax/2, 0)]
        (; points, text=_scalebar_str($(p.scale), mul), textpos=avgpos)
    end

    attrs = @p let
        Makie.shared_attributes(p, Lines)
        @set __[:space] = :relative
    end
    lines!(p, attrs, @lift $obs.points)
    attrs = @p let
        Makie.shared_attributes(p, Makie.Text)
        @set __[:space] = :relative
        @set __[:position] = @lift $obs.textpos
        @set __[:align] = (:center, :top)
    end
    text!(p, attrs, @lift $obs.text)
    return p
end

units_in_dataunit(x::Number) = ustrip(x)
units_in_dataunit(x::Tuple) = units_in_dataunit(x[1])

_scalebar_str(scale::Quantity, mul) = "$mul $(unit(scale))"
_scalebar_str(scale::Tuple{<:Number,<:Function}, mul) = scale[2](mul)
