using IICGP
using Test

function test_input(f::Function, img::AbstractArray)
    out = f(img)
    @test size(out) <= size(img)
    @test typeof(out) <: Array{Float64}
    @test maximum(out) <= 1.0
    @test minimum(out) >= 0.0
end

function test_functions(functions::Array{Function}, images)
    for f in functions
        for img in images
            test_input(f, img)
        end
    end
end

@testset "Reducing functions" begin
        # Load / generate images
        r, g, b = IICGP.load_rgb("freeway", 30)
        z = zeros(UInt8, size(r))
        o = 0xff .* ones(UInt8, size(r))
        images = [r, g, b, z, o]

        functions = [
                IICGP.ReducingFunctions.max_pool_reduction,
                IICGP.ReducingFunctions.min_pool_reduction,
                IICGP.ReducingFunctions.mean_pool_reduction
        ]

        # Test each function
        test_functions(functions, images)
end
