using ArcadeLearningEnvironment
using CartesianGeneticProgramming
using IICGP
using Test
using Statistics

# Global test parameters
GAME_NAME = "freeway"
N_OUT_ENCO = 2

function enco_cont_from_reducer(r::AbstractReducer)
    # Temporarily open a game to retrieve parameters
    game = Game(GAME_NAME, 0)
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
    features_flatten = collect(Iterators.flatten(features))

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

    enco, cont
end


##

# Pooling reducer
features_size = 5
r = PoolingReducer(Statistics.mean, features_size)
enco, cont = enco_cont_from_reducer(r)

game = Game(GAME_NAME, 0)
n_out = length(getMinimalActionSet(game.ale))
rgb = get_rgb(game)
features, out = IICGP.process_f(enco, r, cont, rgb)
close!(game)

@test length(features) == N_OUT_ENCO
for i in eachindex(features)
    @test typeof(features[i]) == Array{Float64, 2}
    @test size(features[i]) == (features_size, features_size)
    @test all(f -> (0.0 <= f <= 1.0), features[i])
end
@test length(out) == n_out

##

# Centroid reducer
n_centroids = 20
r = CentroidReducer(n_centroids, N_OUT_ENCO)

out = CartesianGeneticProgramming.process(enco, rgb)
features = r.reduct(out, r.parameters)
# TODO here




##
@testset "Processing functions" begin
    println("TODO")
end
