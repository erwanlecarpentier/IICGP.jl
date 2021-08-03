using ArcadeLearningEnvironment
using ArgParse
using Cambrian
using CartesianGeneticProgramming
using Dates
using IICGP
using Distributed
import Random

s = ArgParseSettings()
@add_arg_table! s begin
    "--game"
    help = "game rom name"
    default = "centipede"
    "--seed"
    help = "random seed for evolution"
    arg_type = Int
    default = 0
end
args = parse_args(ARGS, s)
seed = args["seed"]
game=args["game"]
Random.seed!(seed)

function play_atari(
    game::String,
    seed::Int64,
    max_frames::Int64
)
    Random.seed!(seed)
    game = Game(game, seed)
    s_traj = Array{Array{Array{UInt8,2},1},1}()
    a_traj = Array{Int64,1}()
    r_traj = Array{Float64,1}()
    frames = 0
    while ~game_over(game.ale)
        action = game.actions[rand(1:length(game.actions))]
        r = act(game.ale, action)
        s = get_rgb(game)
        push!(s_traj, s)
        push!(a_traj, action)
        push!(r_traj, r)
        frames += 1
        if frames > max_frames
            break
        end
    end
    close!(game)
    s_traj, a_traj, r_traj
end

max_frames = 10

s1, a1, r1 = play_atari(game, seed, max_frames)
s2, a2, r2 = play_atari(game, seed, max_frames)

println()
println("same states  : ", s1 == s2)
println("same actions : ", a1 == a2)
println("same rewards : ", r1 == r2)




##

using BenchmarkTools
using Test
using ArraysOfArrays
using ImageCore, Colors
using TensorCast

function g1(game::Game)
    rawscreen = getScreenRGB(game.ale)
    rgb = reshape(rawscreen, (3, game.width, game.height));
    [Array{UInt8}(rgb[i,:,:]) for i in 1:3]
end

function g2(game::Game)
    rawscreen = getScreenRGB(game.ale)
    @cast out3[i][j,k] |= rawscreen[i⊗j⊗k] (i∈1:3, j∈1:game.width, k∈1:game.height)
end

function g3(game::Game)
    rawscreen = getScreenRGB(game.ale)
    [convert(Array{UInt8,2}, reshape(@view(rawscreen[i:3:length(rawscreen)]), (game.width, game.height))) for i in 1:3]
end

game = Game("assault", 0)
# rawscreen = getScreenRGB(game.ale)

println()
if true
    @btime g1(game)
    @btime g2(game)
    @btime g3(game)
end

out1 = g1(game)
out2 = g2(game)
out3 = g3(game)

println(typeof(out1))
println(typeof(out2))
println(typeof(out3))

@testset "Size values" begin
    # Size
    for o in [out2, out3]
        @test size(o) == size(out1)
        for i in 1:3
            @test size(o[i]) == size(out1[i])
        end
    end
    @test out1 == out2
end
