struct AxFunc{F}
    f::F
    attrs
end

AxFunc(f; kwargs...) = AxFunc(f, NamedTuple(kwargs))
AxFunc(f::AxFunc; kwargs...) = AxFunc(f.f, merge(f.attrs, kwargs))
(fa::AxFunc)(args...; kwargs...) = fa.f(args...; kwargs...)


ax_attrs_from_func(f) = (;label=shortlabel(f))
ax_attrs_from_func(f::AxFunc) = (;ax_attrs_from_func(f.f)..., f.attrs...)


shortlabel(f::AxFunc) = get(f.attrs, :label, shortlabel(f.f))
shortlabel(::Nothing) = ""
function shortlabel(f)
    o, unit = AccessorsExtra._split_unitstr_from_optic(f)
    ostr = AccessorsExtra.barebones_string(o)
    isnothing(unit) ? ostr : "$ostr ($unit)"
end
