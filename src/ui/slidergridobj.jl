function SliderGridObj(loc, obj, specs...)
	sliderspecs = map(specs) do s
		o = first(s)
		merge((;
			label=shortlabel(o),
			startvalue=o(obj),
		), last(s))
	end
	Label(loc[1,1], "$(nameof(typeof(obj))):", tellwidth=false)
	sg = SliderGrid(loc[2,1], sliderspecs...)
	vals = lift(tuple, map(s -> s.value, sg.sliders)...)
	@lift setall($obj, concat(first.(specs)...), $vals)
end
