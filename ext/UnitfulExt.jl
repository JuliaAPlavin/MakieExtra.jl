module UnitfulExt

using Unitful
import MakieExtra: _split_unit

_split_unit(o::Base.Fix1{typeof(ustrip)}, _...) = (identity, string(o.x))

end
