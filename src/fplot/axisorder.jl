# reorder if reorder_args == true, otherwise original order
argfuncs_for_plotargs(ct, X::FPlot; reorder_args::Bool=true, kwargs...) =
    if reorder_args
        ixs = argixs_xy_axes(ct, X, kwargs)
        if isnothing(ixs)
            # default behavior if argixs_xy_axes is not defined
            X.argfuncs
        elseif maximum(ixs) ≤ length(X.argfuncs)
            # reorder args according to argixs_xy_axes
            X.argfuncs[collect(ixs)]
        else
            # got fewer args than argixs_xy_axes expects, use args as-is
            # this handles stuff like scatter() and many others with a single argument
            X.argfuncs
        end
    else
        X.argfuncs
    end

# original order if reorder_args == true, otherwise reorder
function argfuncs_for_xy(ct, X::FPlot; reorder_args::Bool=true, kwargs...)
    argixs = argixs_xy_axes(ct, X, kwargs)
    if !isnothing(argixs) && !all(∈(eachindex(X.argfuncs)), argixs)
        # got fewer args than argixs_xy_axes expects, likely something unusual like scatter() and many others with a single argument
        return nothing
    end
    ixs = if isnothing(argixs)
        # default behavior if argixs_xy_axes is not defined
        X.argfuncs
    elseif reorder_args
        # argfuncs in the original order, but only those present in argixs
        map(1:maximum(argixs)) do i
            i ∈ argixs ? X.argfuncs[i] : nothing
        end
    else
        # argfuncs reordered according to argixs
        X.argfuncs[collect(argixs)]
    end
end


argixs_xy_axes(ct, X::FPlot, kwargs) = nothing
argixs_xy_axes(ct::Function, X::FPlot, kwargs) = argixs_xy_axes(Makie.MakieCore.func2type(ct), X, kwargs)
argixs_xy_axes(::Type{<:VLines}, X::FPlot, kwargs) = (1,)
argixs_xy_axes(::Type{<:HLines}, X::FPlot, kwargs) = (2,)
argixs_xy_axes(::Type{<:Union{BarPlot,Errorbars,Rangebars}}, X::FPlot, kwargs) = get(kwargs, :direction, :y) == :x ? (2, 1) : (1, 2)
argixs_xy_axes(::Type{<:Hist},    X::FPlot, kwargs) = get(kwargs, :direction, :y) == :x ? (2,) : (1,)
argixs_xy_axes(::Type{<:Density}, X::FPlot, kwargs) = get(kwargs, :direction, :y) == :x ? (1,) : (2,)
argixs_xy_axes(::Type{<:Union{Band,BandStroke}}, X::FPlot, kwargs) = get(kwargs, :direction, :x) == :y ? (2, 1) : (1, 2)
