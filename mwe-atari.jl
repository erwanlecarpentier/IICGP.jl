using ArcadeLearningEnvironment

""" Random walk in a single Atari game """
function play_atari(lck, game_name="pong", seed=0, max_frames=3000)
    println("\n\n\nThread $(Threads.threadid()) is playing $game_name")
    ale = ALE_new()
    lock(lck) do
        loadROM(ale, game_name)
    end
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

""" Launch multiple threads, each playing Atari """
function play_atari_multithreaded(n::Int64)
    results = zeros(n)
    lck = ReentrantLock()
    @sync for i in 1:n
        Threads.@spawn begin
            results[i] = play_atari(lck)
        end
    end
    println("\n\n\n$n runs completed, results: $results")
    println("------------------------------------")
    results
end

n_iter = 10
n_run_per_iter = 4
for t in 1:n_iter
    play_atari_multithreaded(n_run_per_iter)
end
