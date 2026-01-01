module MakieExtra

using Reexport
using AccessorsExtra
using InverseFunctions
using PyFormattedStrings
using Makie: left, right, bottom, top, bottomleft, topleft, bottomright, topright, topline, bottomline, leftline, rightline
using Makie: documented_attributes
using Makie.IntervalSets
using Makie.IntervalSets: width
using Makie: mean
import Makie.GeometryBasics; using Makie.GeometryBasics: HyperRectangle, Rect
using Makie.Unitful
using Makie.GeometryBasics.StaticArrays
using Makie.LinearAlgebra: norm
using DataManipulation
using DataManipulation.StructArrays
using StructHelpers
import Makie: plotfunc, plotfunc!, func2type
using KwdefHelpers

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
    FPlot, AxFunc,
    DataCursor, RectSelection, InteractivePoints, with_widgets, is_selected, selected_data, mark_selected_data,
    axplot,
    @rich,
    obsmap,
    mouse_position_obs,
    intervals, dilate, erode, boundingbox2d,
    liftT,
    offset_texts_auto_1d!,
    autohide_axlabels!,
    link_colormap!, link_legend!,
    Slider₊, Checkbox₊, SliderGridObj,
    @plt

include("lift.jl")
include("scales.jl")
include("ticks.jl")
include("helpers.jl")
include("axplot.jl")
include("zoom_lines.jl")
include("markers.jl")
include("recipes/arrowline.jl")
include("recipes/scalebar.jl")
include("recipes/contourf.jl")
include("recipes/ecdfplot.jl")
include("recipes/glow.jl")
include("recipes/bandstroke.jl")
include("recipes/textwithbox.jl")
include("axisfunction.jl")
include("multiplot.jl")
include("fplot/fplot.jl")
include("avoid_overlaps.jl")
include("ui/radiobuttons.jl")
include("ui/labeledwidgets.jl")
include("ui/slidergridobj.jl")
include("layout.jl")
include("observables.jl")
include("linking.jl")


# XXX: should try upstreaming all of these!

include("geometry.jl")
include("gridlayout.jl")

function show_gl_icon_in_dock(show::Bool=true)
    Sys.isapple() || return
    try
        # Get NSApplication class and selectors
        nsapp_class = @ccall objc_getClass("NSApplication"::Cstring)::Ptr{Cvoid}
        shared_app_sel = @ccall sel_registerName("sharedApplication"::Cstring)::Ptr{Cvoid}
        set_policy_sel = @ccall sel_registerName("setActivationPolicy:"::Cstring)::Ptr{Cvoid}
        
        # Get NSApplication shared instance
        nsapp = @ccall objc_msgSend(nsapp_class::Ptr{Cvoid}, shared_app_sel::Ptr{Cvoid})::Ptr{Cvoid}
        
        # Set activation policy
        NSApplicationActivationPolicyRegular   = 0
        NSApplicationActivationPolicyAccessory = 1
        val = show ? NSApplicationActivationPolicyRegular : NSApplicationActivationPolicyAccessory
        
        @ccall objc_msgSend(nsapp::Ptr{Cvoid}, set_policy_sel::Ptr{Cvoid}, val::Clong)::Ptr{Cvoid}
    catch e
        @warn "Failed to set dock icon visibility" e
    end
end

# from https://github.com/MakieOrg/Makie.jl/pull/5223#issuecomment-3198115783
function set_gl_dock_icon(icon_path::String)
    Sys.isapple() || return
    try
        # Get NSApplication and NSImage classes
        nsapp_class = @ccall objc_getClass("NSApplication"::Cstring)::Ptr{Cvoid}
        nsimage_class = @ccall objc_getClass("NSImage"::Cstring)::Ptr{Cvoid}
        nsstring_class = @ccall objc_getClass("NSString"::Cstring)::Ptr{Cvoid}
        
        # Get selectors
        shared_app_sel = @ccall sel_registerName("sharedApplication"::Cstring)::Ptr{Cvoid}
        set_icon_sel = @ccall sel_registerName("setApplicationIconImage:"::Cstring)::Ptr{Cvoid}
        init_with_path_sel = @ccall sel_registerName("initWithContentsOfFile:"::Cstring)::Ptr{Cvoid}
        alloc_sel = @ccall sel_registerName("alloc"::Cstring)::Ptr{Cvoid}
        string_with_utf8_sel = @ccall sel_registerName("stringWithUTF8String:"::Cstring)::Ptr{Cvoid}
        
        # Get NSApplication shared instance
        nsapp = @ccall objc_msgSend(nsapp_class::Ptr{Cvoid}, shared_app_sel::Ptr{Cvoid})::Ptr{Cvoid}
        
        # Create NSString from path
        nsstring = @ccall objc_msgSend(nsstring_class::Ptr{Cvoid}, string_with_utf8_sel::Ptr{Cvoid}, icon_path::Cstring)::Ptr{Cvoid}
        
        # Create NSImage
        nsimage_alloc = @ccall objc_msgSend(nsimage_class::Ptr{Cvoid}, alloc_sel::Ptr{Cvoid})::Ptr{Cvoid}
        nsimage = @ccall objc_msgSend(nsimage_alloc::Ptr{Cvoid}, init_with_path_sel::Ptr{Cvoid}, nsstring::Ptr{Cvoid})::Ptr{Cvoid}
        
        # Set application icon
        @ccall objc_msgSend(nsapp::Ptr{Cvoid}, set_icon_sel::Ptr{Cvoid}, nsimage::Ptr{Cvoid})::Ptr{Cvoid}
    catch e
        @warn "Failed to set dock icon" e
    end
end


# was in Makie before, but was removed at some point:
function primary_resolution end


# see https://github.com/MakieOrg/GeoMakie.jl/issues/293
const GeoMakie_radians_source = """
    GEOGCRS["WGS 84",
        DATUM["World Geodetic System 1984",
            ELLIPSOID["WGS 84",6378137,298.257223563,
                LENGTHUNIT["metre",1]],
            ID["EPSG",6326]],
        PRIMEM["Greenwich",0,
            ANGLEUNIT["radian",1],
            ID["EPSG",8901]],
        CS[ellipsoidal,2],
            AXIS["geodetic latitude (Lat)",north,
                ORDER[1],
                ANGLEUNIT["Rad",1]],
            AXIS["geodetic longitude (Lon)",east,
                ORDER[2],
                ANGLEUNIT["Rad",1]]]
"""
GeoAxis_radians!() = update_theme!(GeoAxis_radians())
GeoAxis_radians() = Theme(GeoAxis=(;source=GeoMakie_radians_source))

const GEOMAKIE_SPLITWRAP = Ref(false)
GeoAxis_splitwrap!(b::Bool = true) = GEOMAKIE_SPLITWRAP[] = b


# https://github.com/JuliaLang/julia/pull/57052
merge(a::Tuple, b::Tuple) = (b..., a[length(b) + 1:end]...)
merge(args...) = Base.merge(args...)


to_x_attrs(;kwargs...) = to_x_attrs(NamedTuple(kwargs))
to_y_attrs(;kwargs...) = to_y_attrs(NamedTuple(kwargs))
to_xy_attrs(;kwargs...) = to_xy_attrs(NamedTuple(kwargs))

function to_x_attrs(attrs)
    attrs_nospecial = delete(attrs, (@maybe _.size) ++ (@maybe _.limit))
    res = @modify(k -> Symbol(:x, k), keys(attrs_nospecial)[∗])
    return merge(
        res,
        (haskey(attrs, :limit) ? (;limits=(attrs.limit, nothing)) : (;)),
        (haskey(attrs, :size) ? (;width=attrs.size) : (;)))
end
function to_y_attrs(attrs)
    attrs_nospecial = delete(attrs, (@maybe _.size) ++ (@maybe _.limit))
    res = @modify(k -> Symbol(:y, k), keys(attrs_nospecial)[∗])
    return merge(
        res,
        (haskey(attrs, :limit) ? (;limits=(nothing, attrs.limit)) : (;)),
        (haskey(attrs, :size) ? (;height=attrs.size) : (;)))
end
to_xy_attrs(attrs) = merge_axis_kwargs(to_x_attrs(attrs), to_y_attrs(attrs))


function merge_plot_kwargs(a, b)
    axis = merge_axis_kwargs((@oget a.axis), (@oget b.axis))
    return merge_non_nothing(a, b, isnothing(axis) ? nothing : (;axis))
end
merge_plot_kwargs(args...) = foldl(merge_plot_kwargs, args; init=nothing)

function merge_axis_kwargs(a, b)
    limits = merge_limits((@oget a.limits), (@oget b.limits))
    merge_non_nothing(a, b, isnothing(limits) ? nothing : (;limits))
end
merge_axis_kwargs(args...) = foldl(merge_axis_kwargs, args; init=nothing)

merge_limits(a, b) = _merge_limits((@oget Makie.convert_limit_attribute(a)), (@oget Makie.convert_limit_attribute(b)))
_merge_limits(a, b::Nothing) = a
_merge_limits(a::Nothing, b) = b
_merge_limits(a::Nothing, b::Nothing) = nothing
_merge_limits(a::Number, b::Number) = b
_merge_limits(a::NTuple{2,Any}, b::NTuple{2,Any}) = _merge_limits.(a, b)

merge_non_nothing(args...) = all(isnothing, args) ? nothing : merge(filter(!isnothing, args)...)


macro rich(expr::String)
    return expr
end
macro rich(expr)
    @assert Base.isexpr(expr, :string)
    Expr(:call, :rich, esc.(expr.args)...)
end

# https://github.com/MakieOrg/Makie.jl/issues/4393
Base.:*(x::Makie.RichText, y::AbstractString) = rich(x, y)
Base.:*(x::AbstractString, y::Makie.RichText) = rich(x, y)
Base.:*(x::Makie.RichText, y::Makie.RichText) = rich(x, y)


boundingbox2d(args...) = Rect2(boundingbox(args...))


function obsmap(x::Observable, xvals, res::Observable)
    xval₀ = x[]
    result = map(xvals) do x_
        x[] = x_
        return res[]
    end
    x[] = xval₀
    return result
end


# see https://github.com/MakieOrg/Makie.jl/issues/4107 and https://github.com/MakieOrg/Makie.jl/issues/4291
function mouse_position_obs(ax::Axis; key=true, priority=10, consume=true, hold=true)
    emptypoint = Point2(NaN, NaN)
    res = Observable(emptypoint)
    scene = Makie.parent_scene(ax)
    onany(events(scene).mouseposition, events(scene).mousebutton; priority) do _...
        if is_mouseinside(ax) && ispressed(scene, key)
            res[] = mouseposition(ax)
            consume && return Consume()
        else
            if !hold && res[] != emptypoint
                res[] = emptypoint
            end
        end
    end
    return res
end

function autohide_axlabels!(pos; hidex=true, hidey=true)
    layout = @oget pos.layout pos.parent
    rows = @oget pos.rows pos.span.rows
    cols = @oget pos.cols pos.span.cols
	if hidey
		for ax in contents(layout[rows, cols[2:end]])
			ax.ylabelvisible = false
			ax.yticksvisible = false
			ax.yticklabelsvisible = false
		end
	end
	if hidex
		for ax in contents(layout[rows[1:end-1], cols])
			ax.xlabelvisible = false
			ax.xticksvisible = false
			ax.xticklabelsvisible = false
		end
	end
end


Makie.Record(obs::Observable, iter::AbstractVector; kwargs...) = Record(current_figure(), obs, iter; kwargs...)
Makie.Record(func::Function, iter::AbstractVector; kwargs...) = Record(func, current_figure(), iter; kwargs...)


Makie.project(s, r::HyperRectangle) = HyperRectangle(Makie.project(s, r.origin), Makie.project(s, r.origin + r.widths) - Makie.project(s, r.origin))

fullproject(ax, p) = Makie.project(Makie.get_scene(ax), Makie.apply_transform(Makie.transform_func(ax), p)) + viewport(ax)[].origin


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


# XXX: hack, ignore kwargs that Makie erroneously propagates
# this is very low-specificity method that should only trigger when no kwargs-accepting methods exist
# this method is relied upon in, for example, VLBIPlots.jl
Makie.convert_arguments(args...; kwargs...) = isempty(kwargs) ? throw(MethodError(convert_arguments, args)) : convert_arguments(args...)


Makie.Record(figlike::Figure, obs::Observable, iter::AbstractVector; kw_args...) =
    Record(figlike, iter; kw_args...) do i
        obs[] = i
    end



rel2data(which::Symbol, orig) = rel2data(current_axis(), which::Symbol, orig)
rel2data(ax::Axis, which::Symbol, orig) = transform_val_space(ax, which, :relative => :data, orig)

data2rel(which::Symbol, orig) = data2rel(current_axis(), which::Symbol, orig)
data2rel(ax::Axis, which::Symbol, orig) = transform_val_space(ax, which, :data => :relative, orig)

transform_val_space(ax, which::Symbol, args...) = transform_val_space(ax, Dict(:x=>1, :y=>2)[which], args...)

function transform_val_space(ax::Axis, which::Int, spaces::Pair{Symbol,Symbol}, orig::Union{Tuple,AbstractVector})
    scene = Makie.get_scene(ax)
    lift(scene.camera.projectionview, Makie.plots(ax)[1].model, Makie.transform_func(ax), scene.viewport, orig) do _, _, tf, _, orig
        tf_cur = @set tf[3-which] = identity
        if spaces[1] == :data
            orig = map(|>, orig, tf_cur)
        end
        new = Makie.project(scene.camera, spaces..., Point2(orig))
        if spaces[2] == :data
            new = Point2(map(|>, new, Accessors.inverse.(tf_cur)))
        end
        @set orig[which] = new[which]
    end
end

function transform_val_space(ax::Axis, which::Int, spaces::Pair{Symbol,Symbol}, orig::Number)
    new = transform_val_space(ax, which, spaces, set((1,1), (@o _[which]), orig))
    return @lift $new[which]
end


# see also https://github.com/MakieOrg/Makie.jl/issues/4887
to_rect_padding(p::Rect) = p
function to_rect_padding(p)
    l, r, b, t = Makie.to_lrbt_padding(p)
    return Rect(-l..r, -b..t)
end

if @isdefined Annotation
    # see discussion in https://github.com/MakieOrg/Makie.jl/pull/5034
    Makie.convert_arguments(::Type{<:Annotation}, p) = convert_arguments(Annotation, convert_arguments(PointBased(), p) |> only)
    function Makie.convert_arguments(::Type{<:Annotation}, off, p)
        p isa AbstractVector{<:Makie.VecTypes} && throw(MethodError(convert_arguments, (Annotation, off, p)))
        convert_arguments(Annotation, off, convert_arguments(PointBased(), p) |> only)
    end
    Makie.convert_arguments(::Type{<:Annotation}, v1::VecTypes{2}, v2::AbstractVector{<:VecTypes{2}}) = convert_arguments(Annotation, v1, only(v2))
end

# https://github.com/MakieOrg/Makie.jl/pull/5037
function Makie.closest_index_inexact(sliderrange, value::Number)
	_, selected_i = findmin(sliderrange) do val
		abs(val - value)
	end
    return selected_i
end

end
