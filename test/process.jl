using ArcadeLearningEnvironment
using CartesianGeneticProgramming
using IICGP
using Test
using Statistics

# Global test parameters
GAME_NAME = "freeway"

##

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
enco_outputs = Int16[1, 4]
enco_cfg = cfg_from_info(enco_nodes, n_in, enco_outputs, IICGP.CGPFunctions,
                         d_fitness)
enco = IPCGPInd(enco_nodes, enco_cfg, enco_outputs, img_size)

# Feature projection function
features_size = 5
r = PoolingReducer(Statistics.mean, features_size)

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
cont_outputs = Int16[cont_n_in+1, 1, cont_n_in+3]
cont_cfg = cfg_from_info(cont_nodes, cont_n_in, cont_outputs,
                         IICGP.CGPFunctions, d_fitness)
cont = CGPInd(cont_nodes, cont_cfg, cont_outputs)


##
game = Game(GAME_NAME, 0)
rgb = get_rgb(game)
out = IICGP.process(enco, cont, rgb, r)
close!(game)

@test 

##
@testset "Processing functions" begin
    println("TODO")
end
