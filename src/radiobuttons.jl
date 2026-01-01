# original code by Julius Krumbiegel, here adapted and extended

"""    radiobuttons(cbs::Checkbox...; cb_attributes=...)

Turn a set of checkboxes into radiobuttons:
- only one can be checked at a time;
- apply attributes from `cb_attributes` to adjust the look of all checkboxes.

The selected index is stored in the `selix::Observable` field of the returned object.
"""
function radiobuttons(cbs::Checkbox...; cb_attributes=(roundness=1, checkmark=Circle, checkmarksize=0.3))
	selix = Observable{Int}(findonly(cb -> cb.checked[], cbs))
	for (i, cb) in enumerate(cbs)
		for (k, v) in pairs(cb_attributes)
			setproperty!(cb, k, v)
		end

		cb.onchange = function(_)
			for cb_ in cbs
				if cb_ !== cb && cb_.checked[]
					cb_.checked[] = false
				end
			end
			selix[] = i
			return true
		end
	end
	return (;selix)
end

function radiobuttons(ps::Pair{Checkbox,Button}...; cb_attributes=(roundness=1, checkmark=Circle, checkmarksize=0.3))
	selix = Observable{Int}(findonly(((cb,_),) -> cb.checked[], ps))
	for (i, (cb, btn)) in enumerate(ps)
		for (k, v) in pairs(cb_attributes)
			setproperty!(cb, k, v)
		end

		cb.onchange = function(_)
			for (cb_, _) in ps
				if cb_ !== cb && cb_.checked[]
					cb_.checked[] = false
				end
			end
			selix[] = i
			return true
		end
		on(btn.clicks) do _
			cb.checked[] = true
			cb.onchange[](nothing)
		end
	end
	return (;selix)
end
