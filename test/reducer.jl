using IICGP
using Test
using Statistics

function pooling_test(r::IICGP.AbstractReducer, img::AbstractArray)
    out = r.reduct(img, r.parameters)
    @test size(out) <= size(img)
    @test typeof(out) <: Array{Float64}
    @test maximum(out) <= 1.0
    @test minimum(out) >= 0.0
end

@testset "Reducing functions" begin
    # Load / generate images
    r1, g1, b1 = IICGP.load_rgb("freeway", 30)
    r2, g2, b2 = IICGP.load_rgb("freeway", 31)
    z = zeros(UInt8, size(r1))
    o = 0xff .* ones(UInt8, size(r1))

    # Pooling reduction
    for f in [maximum, Statistics.mean, minimum]

        size = 5
        r = PoolingReducer(f, size)
        for img in [r1, g1, b1, z, o]
            pooling_test(r, img)
        end
    end

    # Centroid reduction
    n = 20

    r = CentroidReducer(n)
    @test length(r.parameters["c_prev"]) == length(r.parameters["a_prev"]) == 0
    out = r.reduct(r1, r.parameters)
    @test length(r.parameters["c_prev"]) == length(r.parameters["a_prev"]) == n
    @test length(out) == 2*n

    r = CentroidReducer(n)
    out = r.reduct(z, r.parameters)
    @test sum(out[3:end]) == 0.0
end
