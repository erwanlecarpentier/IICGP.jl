using ArcadeLearningEnvironment
using IICGP

""" Random walk in a single Atari game """
function play_atari(
    lck::ReentrantLock;
    game_name::String="pong",
    seed::Int64=0,
    max_frames::Int64=1000
)
    println("\n\n\nThread $(Threads.threadid()) is playing $game_name")
    game = Game(game_name, seed, lck=lck)
    # game = Game(game_name, seed)
    actions = getMinimalActionSet(game.ale)
    reward = 0.0
    frames = 0
    while ~game_over(game.ale)
        action = actions[rand(1:length(actions))]
        reward += act(game.ale, action)
        frames += 1
        if frames > max_frames
            break
        end
    end
    close!(game)
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
