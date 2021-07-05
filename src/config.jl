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
    logid = string(Dates.now(), "_", game_name, "_", seed)
    close!(game)

    # Main config
    cfg = YAML.load_file(dualcgp_cfg_filename)
    d_fitness = cfg["d_fitness"]
    encoder_cfg = cfg["encoder"]
    reducer_cfg = cfg["reducer"]
    controller_cfg = cfg["controller"]

    # Encoder config
    encoder_cfg["function_module"] = IICGP.CGPFunctions
    encoder_cfg["n_in"] = n_in
    encoder_cfg["img_size"] = img_size
    encoder_cfg["d_fitness"] = d_fitness
    encoder_cfg["seed"] = seed
    encoder_cfg["id"] = logid
    encoder_cfg = get_config(encoder_cfg) # dict to named tuple

    # Reducer
    reducer_type = reducer_cfg["type"]
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
    controller_cfg["d_fitness"] = d_fitness
    controller_cfg["seed"] = seed
    controller_cfg["id"] = logid
    controller_cfg = get_config(controller_cfg) # dict to named tuple

    encoder_cfg, controller_cfg, reducer
end
