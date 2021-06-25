using IICGP
using Test
using Statistics

function pooling_test(r::IICGP.AbstractReducer, img::AbstractArray)
    out = r.reduct([img], r.parameters)
    @test size(out) <= size(img)
    @test typeof(out) <: Array{Array{Float64,2},1}
    for i in eachindex(out)
        @test maximum(out[i]) <= 1.0
        @test minimum(out[i]) >= 0.0
    end
end

@testset "Reducing functions" begin
    # Load / generate images
    r1, g1, b1 = IICGP.load_rgb("freeway", 30)
    r2, g2, b2 = IICGP.load_rgb("freeway", 31)
    img_size = size(r1)
    n_in = 1
    z = zeros(UInt8, img_size)
    o = 0xff .* ones(UInt8, img_size)

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
    r = CentroidReducer(n, n_in, img_size)
    @test length(r.parameters["c_prev"]) == length(r.parameters["a_prev"]) == n_in
    out = r.reduct([r1], r.parameters)
    @test length(r.parameters["c_prev"]) == length(r.parameters["a_prev"]) == n_in
    @test length(out) == n_in
    for i in eachindex(r.parameters["c_prev"])
        @test length(r.parameters["c_prev"][i]) == n
        @test length(r.parameters["a_prev"][i]) == n
        @test length(out[i]) == n
    end

    r = CentroidReducer(n, n_in, img_size)
    out = r.reduct([z], r.parameters)
    @test all(c -> (c == (0.0, 0.0)), out[1][2:end])
end
