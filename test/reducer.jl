using IICGP
using OpenCV
using Test

function test_input(f::Function, img::AbstractArray)
    img_reduced = f(img)
    @test size(img_reduced) <= size(img)
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
        image_name = "centipede_frame_0"
        filename = string(@__DIR__, "/", image_name, ".png")
        m = OpenCV.imread(filename)
        r, g, b = IICGP.split_rgb(m)
        images = [r, g, b]

        functions = [
                IICGP.ReducingFunctions.nearest_reduction,
                IICGP.ReducingFunctions.linear_reduction,
                IICGP.ReducingFunctions.area_reduction,
                IICGP.ReducingFunctions.cubic_reduction,
                IICGP.ReducingFunctions.lanczos_reduction,
                IICGP.ReducingFunctions.max_pool_reduction
        ]

        # Test each function
        test_functions(functions, images)
end
