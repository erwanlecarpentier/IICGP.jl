using ArcadeLearningEnvironment
using IICGP
using Test
using OpenCV
using Combinatorics
using BenchmarkTools

function generate_white_img(sz::Tuple{Int64,Int64}=(210, 320))
    convert(UInt8, 255) * ones(UInt8, sz)
end

function generate_black_img(sz::Tuple{Int64,Int64}=(210, 320))
    zeros(UInt8, sz)
end

function generate_noisy_img(sz::Tuple{Int64,Int64}=(210, 320))
    rand(collect(UInt8, 0:255), sz)
end

function test_inputs(f::Function, inps::AbstractArray)
    out = copy(f(inps...))
    @test size(out) == size(inps[1])
    @test size(out) == size(inps[2])
    @test typeof(out) == IICGP.ImgType
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

function generate_exp_img_set()
    set = Array{Array{UInt8,2},1}()
    # Min / Max / Random images
    append!(set, [
        generate_black_img(),
        generate_white_img(),
        generate_noisy_img()
    ])
    set
end

function generate_atari_img_set()
    set = Array{Array{UInt8,2},1}()
    rom_list = setdiff(getROMList(), ["pacman", "surround"])
    rom_list = ["freeway", "alien", "atlantis"]
    for rom in rom_list
        append!(set, IICGP.load_rgb(rom, 30))
    end
    set
end

function generate_img_pair_set()
    exp_set = generate_exp_img_set()
    atari_set = generate_atari_img_set()
    exp_set = append!(exp_set, atari_set[1:6])
    img_pairs = collect(Combinatorics.combinations(exp_set, 2))
    n_img = length(atari_set)
    for img in atari_set
        append!(img_pairs, [[img, atari_set[rand(1:n_img)]]])
    end
    img_pairs
end

pairs = generate_img_pair_set()

@testset "Julia Image functions" begin
    # Load / generate images
    image_name = "centipede_frame_0"
    filename = string(@__DIR__, "/", image_name, ".png")
    atari_img = OpenCV.imread(filename)
    # grsca_img = OpenCV.cvtColor(atari_img, OpenCV.COLOR_BGR2GRAY)
    sz = (1, 320, 210)
    noisy_img = generate_noisy_img(sz)
    white_img = generate_white_img(sz)
    black_img = generate_black_img(sz)

    img_set = vcat(split_rgb(atari_img), [noisy_img, white_img, black_img])
    img_pairs = Combinatorics.combinations(img_set, 2)

    # Fetch functions
    functions = [
        IICGP.CGPFunctions.f_dilate,
        IICGP.CGPFunctions.f_erode,
        IICGP.CGPFunctions.f_remove_details
    ]

    # Test all functions
    test_functions(functions, img_pairs)
end

#=
@deprecated
@testset "OpenCV functions" begin
    # Load / generate images
    image_name = "centipede_frame_0"
    filename = string(@__DIR__, "/", image_name, ".png")
    atari_img = OpenCV.imread(filename)
    # grsca_img = OpenCV.cvtColor(atari_img, OpenCV.COLOR_BGR2GRAY)
    sz = (1, 320, 210)
    noisy_img = generate_noisy_img(sz)
    white_img = generate_white_img(sz)
    black_img = generate_black_img(sz)

    img_set = vcat(split_rgb(atari_img), [noisy_img, white_img, black_img])
    img_pairs = Combinatorics.combinations(img_set, 2)

    # Fetch functions
    functions = [
        IICGP.CGPFunctions.f_absdiff_img,
        IICGP.CGPFunctions.f_add_img,
        IICGP.CGPFunctions.f_subtract_img,
        IICGP.CGPFunctions.f_addweighted_img,
        IICGP.CGPFunctions.f_bitwise_and_img,
        IICGP.CGPFunctions.f_bitwise_not_img,
        IICGP.CGPFunctions.f_bitwise_or_img,
        IICGP.CGPFunctions.f_bitwise_xor_img,
        IICGP.CGPFunctions.f_compare_eq_img,
        IICGP.CGPFunctions.f_compare_ge_img,
        IICGP.CGPFunctions.f_compare_le_img,
        IICGP.CGPFunctions.f_max_img,
        IICGP.CGPFunctions.f_min_img,
        IICGP.CGPFunctions.f_dilate_img,
        IICGP.CGPFunctions.f_erode_img
    ]

    # Test all functions
    test_functions(functions, img_pairs)
end
=#
