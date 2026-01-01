"""    scalebar(scale; kwargs...)

Add a scalebar to the plot.

Supports all `lines()` and `text()` attributes, forwarding them to the respective plot calls.
The `position` attribute defines the position of the scalebar in relative `Axis` coordinates.
The `target_ax_frac` attribute defines the fraction of the axis width the scalebar should span.
The multiple of `scale` will be chosen automatically (from `muls`) so that the scalebar length is closest to `target_ax_frac`.

Typically, `scale` is a `Unitful` quantity that defines the size of one plot unit.
For example, `scalebar!(1u"mm")` means that the plot units are millimeters.
Alternatively, `scale` can be a tuple `(number, function)` where `function` is called for the string representation.
"""
@recipe Scalebar (scale,) begin
    @modify($(documented_attributes(Lines)).d) do d
        filter_keys(∉([:color]), d)
    end...
    @modify($(documented_attributes(Makie.Text)).d) do d
        filter_keys(∉([:position] ∪ keys(documented_attributes(Lines).d)), d)
    end...

    color = :black
    cycle = nothing
    position = Point2(0.85, 0.08)
    target_ax_frac = 0.2
    muls = [p isa Int ? x*p : round(x*p, sigdigits=4)
        for p in Real[[10.0^p for p in -50:-1]; [1, 10, 100, 1000, 10000]; [10.0^p for p in 5:50]]
        for x in [1, 2, 5]]
end

Makie.data_limits(::Scalebar) = Rect3f(Point3f(NaN), Vec3f(NaN))
Makie.boundingbox(::Scalebar, space::Symbol=:data) = Rect3f(Point3f(NaN), Vec3f(NaN))


function Makie.plot!(p::Scalebar)
    scene = Makie.parent_scene(p)
    @assert Makie.transform_func(scene)[1] == identity

    obs = @lift let
        xlims = @p let
            $(Makie.projview_to_2d_limits(p))
            first.(extrema(__))
            Interval(__...)
        end

        units_in_data = units_in_dataunit($(p.scale))
        mul = argmin(m -> abs(1 / units_in_data * m - $(p.target_ax_frac) * width(xlims)), $(p.muls))
        length_data = 1 / units_in_data * mul

        length_ax = length_data / width(xlims)
        avgpos = convert(Point2, $(p.position))
        points = [avgpos - Vec2(length_ax/2, 0), avgpos + Vec2(length_ax/2, 0)]
        (; points, text=_scalebar_str($(p.scale), mul), textpos=avgpos)
    end

    attrs = @p let
        Makie.shared_attributes(p, Lines)
        @set __[:space] = :relative
    end
    lines!(p, attrs, (@lift $obs.points), xautolimits=false, yautolimits=false)
    attrs = @p let
        Makie.shared_attributes(p, Makie.Text)
        @set __[:space] = :relative
        @set __[:position] = @lift $obs.textpos
        @set __[:align] = (:center, :top)
    end
    text!(p, attrs, (@lift $obs.text), xautolimits=false, yautolimits=false)
    return p
end

units_in_dataunit(x::Number) = ustrip(x)
units_in_dataunit(x::Tuple) = units_in_dataunit(x[1])

_scalebar_str(scale::Quantity, mul) = "$mul $(unit(scale))"
_scalebar_str(scale::Tuple{<:Number,<:Function}, mul) = scale[2](mul)
