using ArcadeLearningEnvironment
using ArgParse
using Cambrian
using CartesianGeneticProgramming
using Dates
using IICGP
using Distributed
using BenchmarkTools
import Random

s = ArgParseSettings()
@add_arg_table! s begin
    "--game"
    help = "game rom name"
    default = "assault"
    "--seed"
    help = "random seed for evolution"
    arg_type = Int
    default = 0
end
args = parse_args(ARGS, s)
const seed = args["seed"]
Random.seed!(seed)

function play_atari(
    game::String,
    seed::Int64,
    max_frames::Int64,
    stickiness::Float64
)
    Random.seed!(seed)
    game = Game(game, seed)
    s_traj = Array{Array{Array{UInt8,2},1},1}()
    a_traj = Array{Int64,1}()
    r_traj = Array{Float64,1}()
    frames = 0
    prev_action = 0
    while ~game_over(game.ale)
        if rand() > stickiness || frames == 0
            action = game.actions[rand(1:length(game.actions))]
        else
            action = prev_action
        end
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

game = args["game"]
seed = args["seed"]
max_frames = 10000
stickiness = 0.1
nthreads = Threads.nthreads()
inline_test = false
n_inline_rep = 10

# Reference
s1, a1, r1 = play_atari(game, seed, max_frames, stickiness)

if inline_test
    for i in 1:n_inline_rep
        s2, a2, r2 = play_atari(game, seed, max_frames, stickiness)
        println()
        println("same states  : ", s1 == s2)
        println("same actions : ", a1 == a2)
        println("same rewards : ", r1 == r2)
    end
else
    @sync for i in 1:nthreads
        Threads.@spawn begin
            s2, a2, r2 = play_atari(game, seed, max_frames, stickiness)
            println()
            println("threadid     : ", Threads.threadid())
            println("same states  : ", s1 == s2)
            println("same actions : ", a1 == a2)
            println("same rewards : ", r1 == r2)
        end
    end
end
