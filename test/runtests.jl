using IICGP
using Test

@testset "IICGP.jl" begin
    @test IICGP.my_f(2, 1) == 5
end
