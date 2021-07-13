using ArcadeLearningEnvironment

""" Random walk in a single Atari game. """
function play_atari(game_name="pong", seed=0, max_frames=1000)
    ale = ALE_new()
    loadROM(ale, game_name)
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

""" Launch multiple threads, each playing Atari. """
function play_atari_multithreaded()
    n = 2
    results = zeros(n)
    @sync for i in 1:n
        Threads.@spawn begin
            results[i] = play_atari()
        end
    end
    println("Thread id: $(Threads.threadid()) - results: $results")
    results
end

n_iter = 10
for t in 1:n_iter
    play_atari_multithreaded()
end
