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

@testset "Julia Image functions" begin
    # Fetch functions
    idempotent_functions = [
        IICGP.CGPFunctions.f_dilate,
        IICGP.CGPFunctions.f_erode,
        IICGP.CGPFunctions.f_remove_details,
        IICGP.CGPFunctions.f_subtract
    ]
    non_idempotent_functions = [
        IICGP.CGPFunctions.f_subtract,
        IICGP.CGPFunctions.f_motion_capture
    ]

    # Load / generate images
    pairs = generate_img_pair_set()

    # Test idempotent functions
    test_functions(idempotent_functions, pairs, idempotent=true)

    # Test non-idempotent functions
    test_functions(non_idempotent_functions, pairs, idempotent=false)
end
