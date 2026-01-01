function Slider₊(pos; range, label, startvalue=range[(begin+end)÷2], valuef=string, kwargs...)
	layout = @oget pos.layout pos.parent
	rows = @oget pos.rows pos.span.rows
	cols = @oget pos.cols pos.span.cols
	if length(rows) == 1 && length(cols) == 2
		p1 = layout[rows[1], cols[1]]
		p2 = layout[rows[1], cols[2]]
		Label(p1, label; tellheight=false)
		sl = Slider(p2[2,1]; range, startvalue, kwargs...)
		Label(p2[1,1], (@lift $valuef($(sl.value))); )
		return sl.value, sl
	elseif length(rows) == 1 && length(cols) == 3
		p1 = layout[rows[1], cols[1]]
		p2 = layout[rows[1], cols[2]]
		p3 = layout[rows[1], cols[3]]
		Label(p1, label; tellheight=false)
		sl = Slider(p2; range, startvalue, kwargs...)
		Label(p3, (@lift $valuef($(sl.value))); )
		return sl.value, sl
	else
		error()
	end
end


function Checkbox₊(pos; label, startvalue=false, kwargs...)
	layout = @oget pos.layout pos.parent
	rows = @oget pos.rows pos.span.rows
	cols = @oget pos.cols pos.span.cols
	if length(rows) == 1 && length(cols) == 2
		p1 = layout[rows[1], cols[1]]
		p2 = layout[rows[1], cols[2]]
		btn = Button(p1; label, tellheight=false, buttoncolor=:transparent, buttoncolor_hover=:transparent, buttoncolor_active=:transparent)
		cb = Checkbox(p2; checked=startvalue)
		on(btn.clicks) do _
			cb.checked[] = !cb.checked[]
		end
		return cb.checked, cb
	else
		error()
	end
end
