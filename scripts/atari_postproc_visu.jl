using ArcadeLearningEnvironment
using CartesianGeneticProgramming
using Dates
using IICGP
using Random


function plot_dualcgp_ingame(
    enco::CGPInd,
    redu::Reducer,
    cont::CGPInd,
    game::String,
    seed::Int64,
    max_frames::Int64,
    grayscale::Bool,
    downscale::Bool,
    stickiness::Float64
)
    Random.seed!(seed)
    mt = MersenneTwister(seed)
    g = Game(game, seed)
    IICGP.reset!(redu) # zero the buffers
    reward = 0.0
    frames = 0
    prev_action = 0
    while ~game_over(g.ale)
        s = get_state(g, grayscale, downscale)
        if rand(mt) > stickiness || frames == 0
            output = IICGP.process(enco, redu, cont, s)
            action = g.actions[argmax(output)]
        else
            action = prev_action
        end
        reward += act(g.ale, action)
        frames += 1
        # plot_state(s)
        # plot_active_buffer(enco) # TODO plot
        if frames > max_frames
            break
        end
    end
    close!(g)
    [reward]
end

function plot_agent_ingame(exp_dir::String, game::String, max_frames::Int64)
    cfg = cfg_from_exp_dir(exp_dir)
    enco, redu, cont = get_last_dualcgp(exp_dir, game, cfg)
    is_dualcgp = haskey(cfg, "encoder")

    seed = cfg["seed"]
    stickiness = cfg["stickiness"]
    grayscale = cfg["grayscale"]
    downscale = cfg["downscale"]

    if is_dualcgp
        plot_dualcgp_ingame(enco, redu, cont, game, seed, max_frames, grayscale,
                            downscale, stickiness)
    end
end




min_date = DateTime(2021, 09, 01)
max_date = DateTime(2021, 09, 02)
games = ["boxing"] # ["freeway"]  # pong kung_fu_master freeway assault
reducers = ["pooling"] # Array{String,1}() # ["pooling"]
exp_dirs, games = get_exp_dir(min_date=min_date, max_date=max_date, games=games,
                              reducers=reducers)
max_frames = 5

# Plot for each one of the selected experiments
for i in eachindex(exp_dirs)
    plot_agent_ingame(exp_dirs[i], games[i], max_frames)
end
