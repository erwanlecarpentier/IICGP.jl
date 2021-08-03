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

function g1(game::Game)
    rawscreen = getScreenRGB(game.ale)
    rgb = reshape(rawscreen, (3, game.width, game.height));
    [Array{UInt8}(rgb[i,:,:]) for i in 1:3]
end

function g2(game::Game)
    rawscreen = getScreenRGB(game.ale)
    rgb = reshape(rawscreen, (3, game.width, game.height));
    [@views(rgb[i,:,:]) for i in 1:3]
end

function g3(game::Game)
    rawscreen = getScreenRGB(game.ale)
    rgb = reshape(rawscreen, (3, game.width, game.height));
    rgb = permutedims(rgb, [2, 3, 1]);
    nestedview(rgb, 2)
end

function g4(game::Game)
    rawscreen = getScreenRGB(game.ale)
    out = Array{Array{UInt8,2},1}(undef, 3)
    for i in 1:3
        out[i] = reshape(view(rawscreen, i:3:length(rawscreen)), (game.width, game.height))
    end
    out
end

function g5(game::Game)
    rawscreen = getScreenRGB(game.ale)
    [convert(Array{UInt8,2}, reshape(@view(rawscreen[i:3:length(rawscreen)]), (game.width, game.height))) for i in 1:3]
end

function g6(game::Game)
    rawscreen = getScreenRGB(game.ale)
    [reshape(rawscreen[i:3:length(rawscreen)], (game.width, game.height)) for i in 1:3]
end


game = Game("assault", 0)

A = game.actions
action = game.actions[rand(1:length(A))]
r = act(game.ale, action)

rawscreen = getScreenRGB(game.ale)
rgb1 = reshape(rawscreen, (3, game.width, game.height))
rgb2 = permutedims(reshape(rawscreen, (3, game.width, game.height)), [2, 3, 1])

println()
if true
    @btime g1(game)
    @btime g2(game)
    @btime g3(game)
    @btime g4(game)
    @btime g5(game)
    @btime g6(game)
end

out1 = g1(game)
out2 = g2(game)
out3 = g3(game)
out4 = g4(game)
out5 = g5(game)
out6 = g6(game)

println(typeof(out1))
println(typeof(out2))
println(typeof(out3))
println(typeof(out4))
println(typeof(out5))
println(typeof(out6))

@testset "Size values" begin
    # Size
    for o in [out2, out3, out4, out5, out6]
        @test size(o) == size(out1)
        for i in 1:3
            @test size(o[i]) == size(out1[i])
        end
    end
    @test out1 == out2
    @test out1 == out4
    @test out1 == out3
    @test out1 == out5
    @test out1 == out6
end

close!(game)


##

using BenchmarkTools
using ArraysOfArrays

f1(x::AbstractArray) = [Array{Float64}(x[i,:,:]) for i in 1:size(x)[1]]
f2(x::AbstractArray) = [@views(x[i,:,:]) for i in 1:size(x)[1]]
function f3(x::AbstractArray)
    nestedview(permutedims(x, [2, 3, 1]), 2)
end

inp = rand(3, 100, 100)
@btime f1(inp)
@btime f2(inp)
@btime f3(inp)

out1 = f1(inp)
out2 = f2(inp)
out3 = f3(inp)

@assert out1 == out2
@assert out1 == out3


## Full problem MWE

using BenchmarkTools
using TensorCast


function f1(x::Array{Int64,1})
    w = h = 3
    reshaped = reshape(x, (3,w,h))
    [Array{Int64}(reshaped[i,:,:]) for i in 1:3]
end

function f2(x::Array{Int64,1})
    w = h = 3
    [convert(Array{Int64,2}, reshape(@view(x[i:3:length(x)]), (w,h))) for i in 1:3]
end

function f3(x::Array{Int64,1})
    w = h = 3
    convert(Array{Array{Int64,2},1}, @cast out3[i][j,k] := x[i⊗j⊗k] (i∈1:3, j∈1:w, k∈1:h))
end

inp = collect(1:27)

println()
@btime f1(inp)
@btime f2(inp)

@assert f1(inp) == f2(inp)

for f in [f1, f2]
    println(typeof(f(inp)))
end
