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

max_frames = 1000

s1, a1, r1 = play_atari(game, seed, max_frames)
s2, a2, r2 = play_atari(game, seed, max_frames)

println()
println("same states  : ", s1 == s2)
println("same actions : ", a1 == a2)
println("same rewards : ", r1 == r2)
