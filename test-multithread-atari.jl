using ArcadeLearningEnvironment

#=
function copyROM(game_name)
    bin_dir = ""
    while true
        dir_id = string(convert(Int64, ceil(1e12*rand())))
        bin_dir = string(@__DIR__, "/tmp/", dir_id)
        if !isdir(bin_dir)
            mkdir(bin_dir)
            break
        end
    end
    src_file = string(@__DIR__, "/rom/", game_name, ".bin")
    dst_file = string(bin_dir, "/", game_name, ".bin")
    cp(src_file, dst_file, force=true)
    dst_file
end
=#

"""
Random walk in Atari game.
"""
function play_atari(game_name="pong", seed=0, max_frames=1000)
    ale = ALE_new()
    rom_bin_file = copyROM(game_name)
    loadROM(ale, rom_bin_file)
    actions = getMinimalActionSet(ale)
    reward = 0.0
    frames = 0
    while game_over(ale) == false
        action = actions[rand(1:length(actions))]
        reward += act(ale, action)
        frames += 1
        if frames > max_frames
            break
        end
    end
    ALE_del(ale)
    reward
end

function multithreaded_function()
    n = 2
    results = zeros(n)
    @sync for i in 1:n
        Threads.@spawn begin
            results[i] = play_atari()
        end
    end
    println(results)
    results
end

##
if !isdir(string(@__DIR__, "/tmp"))
    mkdir(string(@__DIR__, "/tmp"))
end
for t in 1:10  # Say we want to do the full parallelized process 10 times
    multithreaded_function()
end
