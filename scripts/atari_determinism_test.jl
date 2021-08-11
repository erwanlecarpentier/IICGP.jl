using ArcadeLearningEnvironment
using IICGP
import Random


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

function write_res(rom, is_deterministic, l::Int64)
    io = open("determinism_res.txt", "a")
    n_spaces = l - length(rom)
    s = string(rom, ' '^n_spaces, " : ", is_deterministic, "\n")
    write(io, s)
    close(io)
end

const seed = 0
const max_frames = 10000
const stickiness = 0.1
const nthreads = Threads.nthreads()
const verbose = false

roms = getROMList()
filter!(e->e≠"pacman", roms)
filter!(e->e≠"surround", roms)
l = maximum([length(r) for r in roms])
res = Dict()
Random.seed!(seed)

for rom in roms
    s1, a1, r1 = play_atari(rom, seed, max_frames, stickiness) # reference
    n_rep = nthreads
    is_deterministic = true
    @sync for i in 1:n_rep
        Threads.@spawn begin
            s2, a2, r2 = play_atari(rom, seed, max_frames, stickiness)

            same_s = s1 == s2
            same_a = a1 == a2
            same_r = r1 == r2
            is_deterministic *= same_s * same_a * same_r

            if verbose
                println()
                println("threadid     : ", Threads.threadid())
                println("same states  : ", same_s)
                println("same actions : ", same_a)
                println("same rewards : ", same_r)
            end
        end
    end

    res[rom] = is_deterministic
    write_res(rom, is_deterministic, l)
end

# Print results
println("\nResults:")
for k in keys(res)
    n_spaces = l - length(k)
    println(k, ' '^n_spaces, " : ", res[k])
end
