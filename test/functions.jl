using IICGP
using Test
using OpenCV
using Combinatorics
using BenchmarkTools

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
    grsca_img = OpenCV.cvtColor(atari_img, OpenCV.COLOR_BGR2GRAY)
    sz = (1, 320, 210)
    noisy_img = generate_noisy_img(sz)
    white_img = generate_white_img(sz)
    black_img = generate_black_img(sz)

    img_set = vcat(split_rgb(atari_img), [grsca_img, noisy_img, white_img, black_img])
    img_pairs = Combinatorics.combinations(img_set, 2)

    # Fetch functions
    functions = [
        IPCGPFunctions.f_add_img,
        IPCGPFunctions.f_subtract_img,
        IPCGPFunctions.f_absdiff_img,
        IPCGPFunctions.f_addweighted_img,
        IPCGPFunctions.f_bitwise_and_img,
        IPCGPFunctions.f_bitwise_not_img,
        IPCGPFunctions.f_bitwise_or_img,
        IPCGPFunctions.f_bitwise_xor_img,
        IPCGPFunctions.f_compare_eq_img,
        IPCGPFunctions.f_compare_ge_img,
        IPCGPFunctions.f_max_img,
        IPCGPFunctions.f_min_img,
        IPCGPFunctions.f_dilate_img
    ]

    functions = functions[1:5]
    println(size(functions))

    # Test all functions
    test_functions(functions, img_pairs)
end

# @btime IPCGPFunctions.f_dilate_img(img_set[1])
# @btime IPCGPFunctions.f_erode_img(img_set[1])
