# https://github.com/jkrumbiegel/GridLayoutBase.jl/pull/65
using Makie.GridLayoutBase: GridLayout, GridPosition, GridSubposition, firstrow, lastrow, firstcol, lastcol, rowgap!, colgap!

function Base.axes(g::GridLayout, d)
    if d == 1
        firstrow(g):lastrow(g)
    elseif d == 2
        firstcol(g):lastcol(g)
    else
        error("A grid only has two dimensions, you're indexing dimension $d.")
    end
end

Base.getindex(g::GridLayout, ix::CartesianIndex{2}) = g[ix[1], ix[2]]


function Base.axes(gp::Union{GridPosition,GridSubposition}, d::Int)
    cs = contents(gp; exact=true)
    isempty(cs) && return 1:1
    length(cs) > 1 && error("There are multiple contents at the GridPosition $gp, can't return axes.")
    c = only(cs)
    c isa GridLayout && return axes(c, d)
    return 1:1
end

Base.getindex(pos::Union{GridPosition, GridSubposition}, ix::CartesianIndex{2}) = pos[ix[1], ix[2]]


colgap!(pos::Union{GridPosition,GridSubposition}, args...) = colgap!(content(pos)::GridLayout, args...)
rowgap!(pos::Union{GridPosition,GridSubposition}, args...) = rowgap!(content(pos)::GridLayout, args...)
