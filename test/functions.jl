using ArcadeLearningEnvironment
using IICGP
using Test
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

function generate_atari_img_set(frame_number::Int64)
    set = Array{Array{UInt8,2},1}()
    rom_list = setdiff(getROMList(), ["pacman", "surround"])
    for rom in rom_list
        append!(set, IICGP.load_rgb(rom, frame_number))
    end
    set
end

function generate_img_pair_set()
    exp_set = generate_exp_img_set()
    atari_set_30 = generate_atari_img_set(30)
    atari_set_31 = generate_atari_img_set(31)
    exp_set = append!(exp_set, atari_set_30[4:9])
    img_pairs = collect(Combinatorics.combinations(exp_set, 2))
    for i in eachindex(atari_set_30)
        append!(img_pairs, [[atari_set_30[i], atari_set_31[i]]])
    end
    img_pairs
end

function test_inputs(f::Function, inps::AbstractArray; idempotent::Bool=true)
    p = rand(1)
    out = copy(f(inps..., p))
    @test size(out) == size(inps[1])
    @test size(out) == size(inps[2])
    @test typeof(out) == Array{UInt8,2}
    if idempotent
        @test all(out == f(inps..., p))
    end
    @test all(out .>= 0)
    @test all(out .<= 255)
end

function test_functions(functions::Array{Function},
                        pairs::Array{Array{Array{UInt8,2},1},1};
                        idempotent::Bool=true)
    for f in functions
        for p in pairs
            test_inputs(f, p, idempotent=idempotent)
        end
    end
end

@testset "CGP functions for images" begin
    # Fetch functions
    idempotent_functions = [
        IICGP.CGPFunctions.f_dilate,
        IICGP.CGPFunctions.f_erode,
        IICGP.CGPFunctions.f_subtract,
        IICGP.CGPFunctions.f_remove_details,
        IICGP.CGPFunctions.f_make_boxes,
        IICGP.CGPFunctions.f_felzenszwalb_segmentation,
        IICGP.CGPFunctions.f_components_segmentation,
        IICGP.CGPFunctions.f_box_segmentation,
        IICGP.CGPFunctions.f_negative,
        IICGP.CGPFunctions.f_threshold,
        IICGP.CGPFunctions.f_binary
    ]
    non_idempotent_functions = [
        IICGP.CGPFunctions.f_motion_capture,
        IICGP.CGPFunctions.f_motion_distances
    ]

    # Load / generate images
    pairs = generate_img_pair_set()

    # Test idempotent functions
    test_functions(idempotent_functions, pairs, idempotent=true)

    # Test non-idempotent functions
    test_functions(non_idempotent_functions, pairs, idempotent=false)
end

rom_sublist = ["boxing", "freeway", "kung_fu_master", "montezuma_revenge"]

@testset "Motion capture function" begin
    for rom in rom_sublist
        p = rand(1)
        r1, g1, b1 = IICGP.load_rgb(rom, 30)
        r2, g2, b2 = IICGP.load_rgb(rom, 31)

        out1 = IICGP.CGPFunctions.f_motion_capture(r1, g1, p)
        @test out1 == r1
        @test convert(Array{UInt8}, reshape(p, size(r1))) == r1

        out2 = IICGP.CGPFunctions.f_motion_capture(r2, g2, p)
        @test out2 == r2 .- r1
        @test convert(Array{UInt8}, reshape(p, size(r2))) == r2
    end
end

@testset "Motion distance function" begin
    for rom in rom_sublist
        for param in [0.0, 0.1, 0.5, 1.0]
            p = [param]
            r1, g1, b1 = IICGP.load_rgb(rom, 30)
            r2, g2, b2 = IICGP.load_rgb(rom, 31)

            out1 = IICGP.CGPFunctions.f_motion_distances(r1, g1, p)
            @test out1 == r1
            @test convert(Array{UInt8}, reshape(p[end-length(r1)+1:end], size(r1))) == r1

            out2 = IICGP.CGPFunctions.f_motion_distances(r2, g2, p)
            @test convert(Array{UInt8}, reshape(p[end-length(r2)+1:end], size(r2))) == r2
        end
    end
end
