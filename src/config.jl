export dualcgp_config

using Dates


function dualcgp_config(dualcgp_cfg_filename::String, game_name::String)
    cfg = YAML.load_file(dualcgp_cfg_filename)
    dualcgp_config(cfg, game_name)
end

function dualcgp_config(cfg::NamedTuple, game_name::String)
    cfg_dict = Dict(pairs(cfg))
    dualcgp_config(cfg_dict, game_name)
end

"""
    dualcgp_config(cfg::Dict, game_name::String)

Retrieve the encoder and controller configuration files from the main dual CGP
configuration file.
Return both config dictionaries along with the corresponding reducer.
"""
function dualcgp_config(cfg::Dict, game_name::String)
    # Temporarily open a game to retrieve parameters
    seed = cfg["seed"]
    game = Game(game_name, seed)
    rgb = get_rgb(game)
    img_size = size(rgb[1])
    n_in = 3  # RGB images
    n_out = length(getMinimalActionSet(game.ale))  # One output per legal action
    close!(game)

    # Main config and  initialize sub-configs
    bootstrap = cfg["bootstrap"]
    d_fitness = cfg["d_fitness"]
    n_gen = cfg["n_gen"]
    log_gen = cfg["log_gen"]
    save_gen = cfg["save_gen"]
    encoder_cfg = cfg["encoder"]
    reducer_cfg = cfg["reducer"]
    controller_cfg = cfg["controller"]
    reducer_type = reducer_cfg["type"]
    logid = string(Dates.now(), "_", game_name, "_", reducer_type, "_", seed)
    for k in ["seed", "d_fitness", "n_gen", "log_gen", "save_gen"]
        encoder_cfg[k] = cfg[k]
        controller_cfg[k] = cfg[k]
    end

    # Encoder config
    encoder_cfg["function_module"] = IICGP.CGPFunctions
    encoder_cfg["n_in"] = n_in
    encoder_cfg["img_size"] = img_size
    encoder_cfg["id"] = logid
    encoder_cfg = get_config(encoder_cfg) # dict to named tuple

    # Reducer
    reducer = Reducer(reducer_cfg, n_in=encoder_cfg.n_out, img_size=img_size)

    # Forward pass to retrieve the number of input of the controller
    enco = IPCGPInd(encoder_cfg)
    enco_out = CartesianGeneticProgramming.process(enco, rgb)
    features = reducer.reduct(enco_out, reducer.parameters)
    features_flatten = collect(Iterators.flatten(Iterators.flatten(features)))
    cont_n_in = length(features_flatten)

    # Controller config
    controller_cfg["function_module"] = IICGP.CGPFunctions
    controller_cfg["n_in"] = cont_n_in
    controller_cfg["n_out"] = n_out
    controller_cfg["id"] = logid
    controller_cfg = get_config(controller_cfg) # dict to named tuple

    encoder_cfg, controller_cfg, reducer, bootstrap
end
