@testitem "radiobuttons" begin
    # smoke test only
    fig = Figure()
    rbs = MakieExtra.radiobuttons(Checkbox(fig[1,1]), Checkbox(fig[1,1], checked=true), Checkbox(fig[1,1]))
    @test rbs.selix[] == 2
    rbs = MakieExtra.radiobuttons(Checkbox(fig[1,1], checked=true) => Button(fig[1,2]), Checkbox(fig[1,1]) => Button(fig[1,2]), Checkbox(fig[1,1]) => Button(fig[1,2]))
    @test rbs.selix[] == 1
end
