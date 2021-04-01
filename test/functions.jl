using IICGP
using Test
using OpenCV
using Combinatorics

function generate_white_img(sz::Tuple{Int64,Int64,Int64}=(3, 320, 210))
    convert(UInt8, 255) * ones(UInt8, sz)
end

function generate_black_img(sz::Tuple{Int64,Int64,Int64}=(3, 320, 210))
    zeros(UInt8, sz)
end

function generate_noisy_img(sz::Tuple{Int64,Int64,Int64}=(3, 320, 210))
    rand(collect(UInt8, 0:255), sz)
end

function test_inputs(f::Function, inps::AbstractArray)
    out = copy(f(inps...))
    @test size(out) == size(inps[1])
    @test size(out) == size(inps[2])
    @test typeof(out) == OpenCV.Mat{UInt8}
    @test all(out == f(inps...)) # functions are idempotent
    @test all(out .>= 0)
    @test all(out .<= 255)
end

function test_functions(functions::Array{Function}, img_pairs)
    for f in functions
        for pair in img_pairs
            test_inputs(f, pair)
        end
    end
end

@testset "OpenCV functions" begin
    # Load / generate images
    image_name = "centipede_frame_0"
    filename = string(@__DIR__, "/", image_name, ".png")
    atari_img = OpenCV.imread(filename)
    noisy_img = generate_noisy_img()
    white_img = generate_white_img()
    black_img = generate_black_img()

    img_set = [atari_img, noisy_img, white_img, black_img]
    img_pairs = Combinatorics.combinations(img_set, 2)

    """
    for i in [noisy_img, white_img, black_img]
        OpenCV.imshow("Image", i)
        OpenCV.waitKey(Int32(0))
        @test size(i) == (3, 320, 210)
    end
    """

    # Fetch functions
    functions = [
        IPCGPFunctions.f_add_img,
        IPCGPFunctions.f_subtract_img
    ]

    # Test functions
    test_functions(functions, img_pairs)
end
