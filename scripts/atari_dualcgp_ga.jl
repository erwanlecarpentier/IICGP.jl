using ArcadeLearningEnvironment
using ArgParse
using Cambrian
using CartesianGeneticProgramming
using Dates
using IICGP
using Random

# function extension
import Cambrian.mutate

```
Playing Atari games using DualCGP on screen input values
```

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
const game = args["game"]
const seed = args["seed"]
const resdir = args["out"]
Random.seed!(seed)

main_cfg, enco_cfg, cont_cfg, reducer, bootstrap = IICGP.dualcgp_config(
    args["cfg"], game
)
const max_frames = main_cfg["max_frames"]
const stickiness = main_cfg["stickiness"]
const grayscale = main_cfg["grayscale"]
const downscale = main_cfg["downscale"]
const logid = main_cfg["id"]

function play_atari(
    encoder::CGPInd,
    reducer::Reducer,
    controller::CGPInd,
    seed::Int64,
    lck::ReentrantLock;
    rom=game,
    max_frames=max_frames,
    grayscale=grayscale,
    downscale=downscale,
    stickiness=stickiness
)
    # Random.seed!(seed)
    mt = MersenneTwister(seed) # TODO per-gen seeding
    game = Game(rom, seed, lck=lck)
    IICGP.reset!(reducer) # zero buffers
    reward = 0.0
    frames = 0
    prev_action = 0
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
        return goldman_mutate(enco_cfg, ind, init_function=IPCGPInd)
    elseif ind_type == "controller"
        return goldman_mutate(cont_cfg, ind)
    end
end

lck = ReentrantLock()
fit(e::CGPInd, c::CGPInd, seed::Int64) = play_atari(e, reducer, c, seed, lck)

# Create an evolution framework
evo = IICGP.DualCGPGAEvo(enco_cfg, cont_cfg, fit, logid, resdir)
#encoder_init_function=IPCGPInd, game=game


# Run evolution
# init_backup(logid, resdir, args["cfg"])
# run!(evo)
