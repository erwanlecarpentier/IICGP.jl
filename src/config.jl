export dualcgp_config

using Dates


"""
    function dualcgp_config(
        dualcgp_cfg_filename::String,
        game_name::String;
        seed::Int64=0
    )

Retrieve the encoder and controller configuration files from the main dual CGP
configuration file.
"""
function dualcgp_config(
    dualcgp_cfg_filename::String,
    game_name::String;
    seed::Int64=0
)
    # Temporarily open a game to retrieve parameters
    game = Game(game_name, 0)
    rgb = get_rgb(game)
    img_size = size(rgb[1])
    n_in = 3  # RGB images
    n_out = length(getMinimalActionSet(game.ale))  # One output per legal action
    close!(game)

    # Main config and  initialize sub-configs
    cfg = YAML.load_file(dualcgp_cfg_filename)
    d_fitness = cfg["d_fitness"]
    n_gen = cfg["n_gen"]
    log_gen = cfg["log_gen"]
    save_gen = cfg["save_gen"]
    encoder_cfg = cfg["encoder"]
    reducer_cfg = cfg["reducer"]
    controller_cfg = cfg["controller"]
    reducer_type = reducer_cfg["type"]
    logid = string(Dates.now(), "_", game_name, "_", reducer_type, "_", seed)
    for k in ["d_fitness", "n_gen", "log_gen", "save_gen"]
        encoder_cfg[k] = cfg[k]
        controller_cfg[k] = cfg[k]
    end

    # Encoder config
    encoder_cfg["function_module"] = IICGP.CGPFunctions
    encoder_cfg["n_in"] = n_in
    encoder_cfg["img_size"] = img_size
    encoder_cfg["seed"] = seed
    encoder_cfg["id"] = logid
    encoder_cfg = get_config(encoder_cfg) # dict to named tuple

    # Reducer
    if reducer_type == "pooling"
        pooling_function = reducer_cfg["pooling_function"]
        if pooling_function == "mean"
            pf = Statistics.mean
        elseif pooling_function == "max"
            pf = maximum
        elseif pooling_function == "min"
            pf = minimum
        else
            throw(ArgumentError("Pooling function $pooling_function not implemented."))
        end
        reducer = PoolingReducer(pf, reducer_cfg["features_size"])
    elseif reducer_type == "centroid"
        reducer = CentroidReducer(reducer_cfg["n_centroids"], encoder_cfg.n_out, img_size)
    else
        throw(ArgumentError("Reducer type $reducer_type not implemented."))
    end

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
    controller_cfg["seed"] = seed
    controller_cfg["id"] = logid
    controller_cfg = get_config(controller_cfg) # dict to named tuple

    encoder_cfg, controller_cfg, reducer
end
