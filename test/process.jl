using ArcadeLearningEnvironment
using CartesianGeneticProgramming
using IICGP
using Test
using Statistics

# Global test parameters
GAME_NAMES = ["freeway", "centipede", "pong"]
N_OUT_ENCO = 2
N_STEPS = 3

function enco_cont_from_reducer(r::AbstractReducer, game_name::String)
    # Temporarily open a game to retrieve parameters
    game = Game(game_name, 0)
    n_in = 3  # RGB images
    n_out = length(getMinimalActionSet(game.ale))  # One output per legal action
    rgb = get_rgb(game)
    img_size = size(rgb[1])
    d_fitness = 1
    close!(game)

    # Encoder
    enco_nodes = [
        Node(1, 1, IICGP.CGPFunctions.f_dilate, [0.5], false)
    ]
    enco_outputs = convert(
        Array{Int16},
        ceil.((n_in + length(enco_nodes)) * rand(N_OUT_ENCO))
    )
    enco_cfg = cfg_from_info(enco_nodes, n_in, enco_outputs, IICGP.CGPFunctions,
                             d_fitness)
    enco = IPCGPInd(enco_nodes, enco_cfg, enco_outputs, img_size)

    # Forward pass to retrieve the number of input of the controller
    enco_out = CartesianGeneticProgramming.process(enco, rgb)
    features = r.reduct(enco_out, r.parameters)
    features_flatten = collect(Iterators.flatten(Iterators.flatten(features)))

    # Controller
    cont_nodes = [
        Node(1, 2, IICGP.CGPFunctions.f_subtract, [0.5], false),
        Node(1, 2, IICGP.CGPFunctions.f_add, [0.5], false),
        Node(3, 3, IICGP.CGPFunctions.f_cos, [0.6], false)
    ]
    cont_n_in = length(features_flatten)
    cont_outputs = convert(
        Array{Int16},
        ceil.((cont_n_in + length(cont_nodes)) * rand(n_out))
    )
    cont_cfg = cfg_from_info(cont_nodes, cont_n_in, cont_outputs,
                             IICGP.CGPFunctions, d_fitness)
    cont = CGPInd(cont_nodes, cont_cfg, cont_outputs)

    enco, cont, img_size
end

@testset "Processing function" begin
    for game_name in GAME_NAMES
        # Pooling reducer
        features_size = 5
        r = PoolingReducer(Statistics.mean, features_size)
        enco, cont, img_size = enco_cont_from_reducer(r, game_name)
        game = Game(game_name, 0)
        n_out = length(getMinimalActionSet(game.ale))
        for step in 1:N_STEPS
            rgb = get_rgb(game)
            features, out = IICGP.process_f(enco, r, cont, rgb)
            @test length(features) == N_OUT_ENCO
            for i in eachindex(features)
                @test typeof(features[i]) == Array{Float64, 2}
                @test size(features[i]) == (features_size, features_size)
                @test all(f -> (0.0 <= f <= 1.0), features[i])
                @test all(f -> (!isnan(f)), features[i])
            end
            @test length(out) == n_out
        end
        close!(game)

        # Centroid reducer
        n_centroids = 20
        r = CentroidReducer(n_centroids, N_OUT_ENCO, img_size)
        enco, cont, img_size = enco_cont_from_reducer(r, game_name)
        game = Game(game_name, 0)
        for step in 1:N_STEPS
            rgb = get_rgb(game)
            features, out = IICGP.process_f(enco, r, cont, rgb)
            action = game.actions[argmax(output)]
            act(game.ale, action)
            @test length(features) == N_OUT_ENCO
            for i in eachindex(features)
                @test typeof(features[i]) == Array{Tuple{Float64,Float64},1}
                @test length(features[i]) == n_centroids
                @test all(f -> ((0.0, 0.0) <= f <= (1.0, 1.0)), features[i])
                @test all(f -> (!isnan(f[1]) && !isnan(f[2])), features[i])
            end
            @test length(out) == n_out
        end
        close!(game)
    end
end
