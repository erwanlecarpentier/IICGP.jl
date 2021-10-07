using ArcadeLearningEnvironment
using ArgParse
using Cambrian
using CartesianGeneticProgramming
using Dates
using IICGP
using Random

import Cambrian.mutate # function extension


s = ArgParseSettings()
@add_arg_table! s begin
    "--cfg"
    help = "configuration script"
    default = "cfg/dualcgpga_atari_pooling.yaml"
    "--game"
    help = "game rom name"
    default = "gravitar"
    "--seed"
    help = "random seed for evolution"
    arg_type = Int
    default = 0
    "--out"
    help = "output directory"
    arg_type = String
    default = dirname(@__DIR__)
    "--ind"
    help = "individual for evaluation"
    arg_type = String
    default = ""
end

args = parse_args(ARGS, s)
const rom = args["game"]
const seed = args["seed"]
const resdir = args["out"]
Random.seed!(seed)
mcfg, ecfg, ccfg, reducer, bootstrap = IICGP.dualcgp_config(args["cfg"], rom)
const max_frames = mcfg["max_frames"]
const stickiness = mcfg["stickiness"]
const grayscale = mcfg["grayscale"]
const downscale = mcfg["downscale"]
const logid = mcfg["id"]

function play_atari(
    encoder::CGPInd,
    reducer::Reducer,
    controller::CGPInd,
    seed::Int64,
    lck::ReentrantLock;
    rom=rom,
    max_frames=max_frames,
    grayscale=grayscale,
    downscale=downscale,
    stickiness=stickiness
)
    # Random.seed!(seed)
    mt = MersenneTwister(seed)
    game = Game(rom, seed, lck=lck)
    IICGP.reset!(reducer) # zero buffers
    reward = 0.0
    frames = 0
    prev_action = Int32(0)
    while ~game_over(game.ale)
        if rand(mt) > stickiness || frames == 0
            s = get_state(game, grayscale, downscale)
            output = IICGP.process(encoder, reducer, controller, s)
            action = game.actions[argmax(output)]
        else
            action = prev_action
        end
        reward += act(game.ale, action)
        frames += 1
        prev_action = action
        if frames > max_frames
            break
        end
    end
    close!(game)
    [reward]
end

# Extend Cambrian mutate function
function mutate(ind::CGPInd, ind_type::String)
    if ind_type == "encoder"
        return goldman_mutate(ecfg, ind, init_function=IPCGPInd)
    elseif ind_type == "controller"
        return goldman_mutate(ccfg, ind)
    end
end

lck = ReentrantLock()
fit(e::CGPInd, c::CGPInd, seed::Int64) = play_atari(e, reducer, c, seed, lck)

# Create an evolution framework
evo = IICGP.DualCGPGAEvo(ecfg, ccfg, fit, logid, resdir)
#encoder_init_function=IPCGPInd, game=game

# Run evolution
init_backup(logid, resdir, args["cfg"])
run!(evo)
