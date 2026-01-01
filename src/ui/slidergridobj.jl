function SliderGridObj(loc, obj, specs...)
	sliderspecs = map(specs) do s
		o = first(s)
		@p let
			last(s)
			set(__, (@maybe _.label), @oget __.label AccessorsExtra.barebones_string(o))
			set(__, (@maybe _.startvalue), @oget __.startvalue argmin(x -> abs(x - o(obj)), __.range))
		end
	end
	Label(loc[1,1], "$(nameof(typeof(obj))):", tellwidth=false)
	sg = SliderGrid(loc[2,1], sliderspecs...)
	vals = lift(tuple, map(s -> s.value, sg.sliders)...)
	@lift setall($obj, concat(first.(specs)...), $vals)
end
