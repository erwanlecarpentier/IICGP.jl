using IICGP
using Dates
using CartesianGeneticProgramming


function plot_dualcgp_ingame(
    enco::CGPInd,
    redu::Reducer,
    cont::CGPInd,
    game::String,
    seed::Int64,
    max_frames::Int64
)
    Random.seed!(seed)
    game = Game(args["game"], seed)
    # reward = 0.0
    frames = 0
    while ~game_over(game.ale)
        output = IICGP.process(enco, redu, cont, get_rgb(game))
        action = game.actions[argmax(output)]
        act(game.ale, action)
        # reward += act(game.ale, action)
        frames += 1

        # Plot
        plot_active_buffer(enco)

        if frames > max_frames
            break
        end
    end
    close!(game)
    # [reward]
end

min_date = DateTime(2021, 07, 01)
max_date = DateTime(2021, 07, 28)
games = ["pong"] # ["freeway"]  # pong kung_fu_master freeway assault
reducers = ["pooling"] # Array{String,1}() # ["pooling"]

exp_dirs, games = get_exp_dir(min_date=min_date, max_date=max_date, games=games,
                              reducers=reducers)

##

# Plot for each one of the selected experiments
for i in eachindex(exp_dirs)
    cfg = cfg_from_exp_dir(exp_dirs[i])
    enco, redu, cont = get_last_dualcgp(exp_dirs[i], games[i], cfg)
    is_dualcgp = haskey(cfg, "encoder")

    game = games[i]
    seed = cfg["seed"]
    max_frames = 5

    if is_dualcgp
        plot_dualcgp_ingame(enco, redu, cont, game, seed, max_frames)
    end
end
