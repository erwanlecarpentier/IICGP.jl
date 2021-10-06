export dualcgp_config, monocgp_config

using Dates


function dict_to_namedtuple(d::Dict)
    NamedTuple{Tuple(keys(d))}(values(d))
end

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
    grayscale = cfg["grayscale"]
    downscale = cfg["downscale"]
    s = get_state(game, grayscale, downscale)
    img_size = size(s[1])
    n_in = length(s)
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
    logid = string(Dates.now(), "_", game_name)
    for k in ["seed", "d_fitness", "n_gen", "log_gen", "save_gen"]
        encoder_cfg[k] = cfg[k]
        controller_cfg[k] = cfg[k]
    end

    # Main config
    main_cfg = Dict()
    for k in keys(cfg)
        if k ∉ ["encoder", "reducer", "controller"]
            main_cfg[k] = cfg[k]
        end
    end
    main_cfg["id"] = logid
    # main_cfg = dict_to_namedtuple(main_cfg)

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
    enco_out = CartesianGeneticProgramming.process(enco, s)
    features = reducer.reduct(enco_out, reducer.parameters)
    features_flatten = collect(Iterators.flatten(Iterators.flatten(features)))
    cont_n_in = length(features_flatten)

    # Controller config
    controller_cfg["function_module"] = IICGP.CGPFunctions
    controller_cfg["n_in"] = cont_n_in
    controller_cfg["n_out"] = n_out
    controller_cfg["id"] = logid
    controller_cfg = get_config(controller_cfg) # dict to named tuple

    main_cfg, encoder_cfg, controller_cfg, reducer, bootstrap
end

function monocgp_config(monocgp_cfg_filename::String, game_name::String)
    cfg = YAML.load_file(monocgp_cfg_filename)
    monocgp_config(cfg, game_name)
end

"""
TODO doc
"""
function monocgp_config(cfg::Dict, game_name::String)
    # Temporarily open a game to retrieve parameters
    seed = cfg["seed"]
    game = Game(game_name, seed)
    grayscale = cfg["grayscale"]
    downscale = cfg["downscale"]
    s = get_state(game, grayscale, downscale)
    img_size = size(s[1])
    n_in = length(s)
    n_out = length(getMinimalActionSet(game.ale))  # One output per legal action
    close!(game)

    # Main config and  initialize sub-configs
    bootstrap = cfg["bootstrap"]
    d_fitness = cfg["d_fitness"]
    n_gen = cfg["n_gen"]
    log_gen = cfg["log_gen"]
    save_gen = cfg["save_gen"]
    reducer_cfg = cfg["reducer"]
    controller_cfg = cfg["controller"]
    reducer_type = reducer_cfg["type"]
    logid = string(Dates.now(), "_", game_name)
    for k in ["seed", "d_fitness", "n_gen", "log_gen", "save_gen"]
        controller_cfg[k] = cfg[k]
    end

    # Main config
    main_cfg = Dict()
    for k in keys(cfg)
        if k ∉ ["encoder", "reducer", "controller"]
            main_cfg[k] = cfg[k]
        end
    end
    # main_cfg = dict_to_namedtuple(main_cfg)

    # Reducer
    reducer = Reducer(reducer_cfg, n_in=n_in, img_size=img_size)

    # Forward pass to retrieve the number of input of the controller
    features = reducer.reduct(s, reducer.parameters)
    features_flatten = collect(Iterators.flatten(Iterators.flatten(features)))
    cont_n_in = length(features_flatten)

    # Controller config
    controller_cfg["function_module"] = IICGP.CGPFunctions
    controller_cfg["n_in"] = cont_n_in
    controller_cfg["n_out"] = n_out
    controller_cfg["id"] = logid
    controller_cfg = get_config(controller_cfg) # dict to named tuple

    main_cfg, controller_cfg, reducer, bootstrap
end
