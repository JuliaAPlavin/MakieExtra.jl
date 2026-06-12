@testitem "radiobuttons" begin
    fig = Figure()
    rbs = MakieExtra.radiobuttons(Checkbox(fig[1,1]), Checkbox(fig[1,1], checked=true), Checkbox(fig[1,1]))
    @test rbs.selix[] == 2
    rbs = MakieExtra.radiobuttons(Checkbox(fig[1,1], checked=true) => Button(fig[1,2]), Checkbox(fig[1,1]) => Button(fig[1,2]), Checkbox(fig[1,1]) => Button(fig[1,2]))
    @test rbs.selix[] == 1
end

@testitem "slider₊" begin
    fig = Figure()
    @test_throws ErrorException Slider₊(fig[1,1], range=0:10, label="Test")
    val, sl = Slider₊(fig[1,1:2], range=0:10, label="Test")
    @test (val::Observable)[] == 5
    @test sl isa Slider
    val, = Slider₊(fig[1,1:3], range=0.1:-2:-10, label="Test")
    @test (val::Observable)[] == -3.9
end

@testitem "checkbox₊" begin
    fig = Figure()
    @test_throws ErrorException Checkbox₊(fig[1,1], label="Test")
    @test_throws ErrorException Checkbox₊(fig[1,1:3], label="Test")
    val, cb = Checkbox₊(fig[1,1:2], label="Test")
    @test (val::Observable)[] == false
    @test cb isa Checkbox
end

@testitem "SliderGridObj" begin
    using Accessors
    fig = Figure()
    obj = SliderGridObj(fig[1,1],
        (a=1, b=(2, 3),),
        (@o _.a) => (;range=0:10),
        (@o _.b[2]) => (;range=0:10, label="B2", startvalue=7),
    )
    @test obj isa Observable
    @test obj[] == (a=1, b=(2, 7))
end