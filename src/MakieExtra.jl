module MakieExtra

using Reexport
using AccessorsExtra
using InverseFunctions
using PyFormattedStrings
using Makie: left, right, bottom, top, bottomleft, topleft, bottomright, topright, topline, bottomline, leftline, rightline
using Makie.MakieCore: documented_attributes
using Makie.IntervalSets
using Makie.IntervalSets: width
using Makie.Unitful
using Makie.LinearAlgebra: norm
using DataPipes
import DataManipulation: shift_range, filteronly, filterfirst, mapinsert
using StructHelpers
import Makie.MakieCore: plotfunc, plotfunc!, func2type

@reexport using Makie
export Makie

export 
    SymLog, AsinhScale,
    BaseMulTicks, EngTicks, PercentFormatter,
    zoom_lines!,
    marker_lw,
    to_x_attrs, to_y_attrs, to_xy_attrs,
    multiplot, multiplot!,
    changes,
    FPlot,
    DataCursor, RectSelection, with_widgets, is_selected, selected_data, mark_selected_data,
    axplot,
    @rich,
    obsmap

include("lift.jl")
include("scales.jl")
include("ticks.jl")
include("helpers.jl")
include("axplot.jl")
include("scalebar.jl")
include("zoom_lines.jl")
include("contourf.jl")
include("markers.jl")
include("glow.jl")
include("bandstroke.jl")
include("axisfunction.jl")
include("arrowline.jl")
include("multiplot.jl")
include("fplot/fplot.jl")


to_x_attrs(attrs) = @modify(k -> Symbol(:x, k), keys(attrs)[∗])
to_y_attrs(attrs) = @modify(k -> Symbol(:y, k), keys(attrs)[∗])
to_xy_attrs(attrs) = merge(to_x_attrs(attrs), to_y_attrs(attrs))


function __init__()
    if ccall(:jl_generating_output, Cint, ()) != 1
        # to support SpecApi
        Core.eval(Makie, Expr(:global, :BandStroke))
        Makie.BandStroke = BandStroke

        Core.eval(Makie, Expr(:global, :LinesGlow))
        Makie.LinesGlow = LinesGlow
    end
end


# adapted from https://github.com/sarvex/ObjectiveC.jl/blob/e2974864b13e91dd72fab85544b12bb782066cca/src/cocoa/cocoa.jl
using ObjectiveC: id, Object, NSString, NSObject, @objc, @objcwrapper
@objcwrapper NSApplication <: NSObject
function show_gl_icon_in_dock(show::Bool)
    path = "/System/Library/Frameworks/AppKit.framework"

	path = NSString(path)
	bundle = @objc [NSBundle bundleWithPath:path::id{NSString}]::id{Object}
	loaded = @objc [bundle::id{Object} load]::id{Object}

    NSApp = Base.bitcast(id{Object}, cglobal(:NSApp, Ptr{Cvoid}) |> unsafe_load)
    @objc [NSApplication sharedApplication]::id{Object}
    NSApplicationActivationPolicyRegular   = 0
    NSApplicationActivationPolicyAccessory = 1
    val = show ? NSApplicationActivationPolicyRegular : NSApplicationActivationPolicyAccessory
    @objc [NSApp::id{Object} setActivationPolicy:val::Int]::id{Object}
end


macro rich(expr)
    @assert Base.isexpr(expr, :string)
    Expr(:call, :rich, esc.(expr.args)...)
end

# https://github.com/MakieOrg/Makie.jl/issues/4393
Base.:*(x::Makie.RichText, y::AbstractString) = rich(x, y)
Base.:*(x::AbstractString, y::Makie.RichText) = rich(x, y)
Base.:*(x::Makie.RichText, y::Makie.RichText) = rich(x, y)


function obsmap(x::Observable, xvals, res::Observable)
	xval₀ = x[]
	result = map(xvals) do x_
		x[] = x_
		return res[]
	end
	x[] = xval₀
	return result
end


# XXX: should upstream all of these!

_which_to_ix(which::Integer) = which == -1 ? 1 : which == 1 ? 2 : error("which must be -1 or 1, got $which")
corner(r::Makie.GeometryBasics.HyperRectangle{2}, which::NTuple{2,Integer}) = Point(extrema(r)[_which_to_ix(which[1])][1], extrema(r)[_which_to_ix(which[2])][2])
corners(r::Makie.GeometryBasics.HyperRectangle{2}) = (bottomleft(r), topleft(r), topright(r), bottomright(r))

Makie.project(s, r::Makie.GeometryBasics.HyperRectangle) = Makie.GeometryBasics.HyperRectangle(Makie.project(s, r.origin), Makie.project(s, r.origin + r.widths) - Makie.project(s, r.origin))

fullproject(ax, p) = Makie.project(Makie.get_scene(ax), Makie.apply_transform(Makie.transform_func(ax), p)) + viewport(ax)[].origin

Makie.inverse_transform(f::Function) = inverse(f)

Makie.GeometryBasics.HyperRectangle{N}(ints::Vararg{<:Interval, N}) where {N} = Makie.HyperRectangle{N}(
    Point(leftendpoint.(ints)),
    Point(rightendpoint.(ints) .- leftendpoint.(ints))
)

# https://github.com/MakieOrg/Makie.jl/pull/4090
function _mouseposition(ax::Axis)
    pos = Makie.mouseposition(Makie.get_scene(ax))
    # `pos` has the axis scaling already applied to it, so to get the true data
    # coordinates we have to invert the scaling.
    return Vec2{Float64}(Makie.inverse_transform(ax.xscale[])(pos[1]),
                         Makie.inverse_transform(ax.yscale[])(pos[2]))
end

# https://github.com/JuliaGizmos/Observables.jl/pull/115
"""
     changes(obs::AbstractObservable)

Returns an `Observable` that only forwards `obs` updates when its value changes.
"""
function changes(obs::Makie.AbstractObservable{T}) where {T}
    # could just be:
    # map(identity, obs, ignore_equal_values=true)
    # but this could narrow the Observable type from T

    result = Observable{T}(obs[], ignore_equal_values=true)
    map!(identity, result, obs)
    return result
end


# https://github.com/MakieOrg/Makie.jl/pull/4037
# Base.setindex(x::Attributes, value, key::Symbol) = merge(Attributes(; NamedTuple{(key,)}((value,))...), x)
function Base.setindex(x::Attributes, value::Observable, key::Symbol)
    y = copy(x)
    y[key] = value
    return y
end
Base.setindex(x::Attributes, value, key::Symbol) = Base.setindex(x, Observable(value), key)

function Accessors.insert(attrs::Attributes, il::IndexLens, val)
    res = copy(attrs)
    res[only(il.indices)] = val
    return res
end

function Accessors.delete(attrs::Attributes, il::IndexLens)
    res = copy(attrs)
    delete!(res, only(il.indices))
    return res
end


function Makie.convert_arguments(P::Type{<:Union{Band,BandStroke,Rangebars}}, i::AbstractInterval, f::Function)
    x, y = Makie.PlotUtils.adapted_grid(x -> Makie.mean(f(x)), endpoints(i))
    return convert_arguments(P, x, f.(x))
end


Base.:(⊆)(a::Rect2, b::Rect2) = xint(a) ⊆ xint(b) && yint(a) ⊆ yint(b)

shift_range(p::T, (r1, r2)::Pair{<:Rect2,<:Rect2}) where {T<:Point2} = T(
    shift_range(p[1], xint(r1) => xint(r2)),
    shift_range(p[2], yint(r1) => yint(r2)),
)


# XXX: hack, ignore kwargs that Makie erroneously propagates
# this is very low-specificity method that should only trigger when no kwargs-accepting methods exist
# this method is relied upon in, for example, VLBIPlots.jl
Makie.convert_arguments(args...; kwargs...) = isempty(kwargs) ? throw(MethodError(convert_arguments, args)) : convert_arguments(args...)

end
