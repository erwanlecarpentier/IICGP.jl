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
        r, g, b = IICGP.load_rgb("freeway", 30)
        z = zeros(UInt8, size(r))
        o = 0xff .* ones(UInt8, size(r))
        images = [r, g, b, z, o]

        for f in [maximum, Statistics.mean, minimum]
            p = Dict("pooling_function"=>f, "size"=>5)
            r = Reducer(pooling_reduction, p)
            for img in images
                pooling_test(r, img)
            end
        end
end
