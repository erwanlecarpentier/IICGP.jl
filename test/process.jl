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
rawscreen = getScreenRGB(game.ale)
rgb = permutedims(reshape(rawscreen, (3, game.width, game.height)), [1, 3, 2])
n_in = 3  # RGB images
n_out = length(getMinimalActionSet(game.ale))  # One output per legal action
img_size = size(rgb)[2:3]
close!(game)

# Encoder
enco_nodes = [
    Node(1, 1, IICGP.CGPFunctions.f_motion_capture, [0.5], false)
]
enco_outputs = Int16[4]
enco_cfg = cfg_from_info(enco_nodes, n_in, enco_outputs, IICGP.CGPFunctions, 1)
enco = IPCGPInd(enco_nodes, enco_cfg, enco_outputs, img_size)

# Feature projection function
size = 5
r = PoolingReducer(Statistics.mean, size)

# Controller
cont_nodes = [
    Node(1, 2, IICGP.CGPFunctions.f_subtract, [0.5], false),
    Node(1, 2, IICGP.CGPFunctions.f_add, [0.5], false),
    Node(3, 3, IICGP.CGPFunctions.f_cos, [0.6], false)
]
cont_outputs = Int16[3, 4, 5]
cont_n_in = length(enco_outputs) * features_size^2
cont_cfg = cfg_from_info(cont_nodes, cont_n_in, cont_outputs, IICGP.CGPFunctions, 1)
cont = CGPInd(cont_nodes, cont_cfg, cont_outputs)

##
@testset "Processing functions" begin
    println("TODO")
end
