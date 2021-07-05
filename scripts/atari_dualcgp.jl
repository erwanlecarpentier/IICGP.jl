using ArcadeLearningEnvironment
using ArgParse
using Cambrian
using CartesianGeneticProgramming
using Dates
using IICGP
import Random
import Cambrian.mutate  # mutate function scope definition

```
Playing Atari games using DualCGP on screen input values

This uses a single Game seed, meaning an unfair deterministic Atari
environment. To evolve using a different game seed per generation, add in
reset_expert=true and seed=evo.gen below.
```

s = ArgParseSettings()
@add_arg_table! s begin
    "--cfg"
    help = "configuration script"
    default = "cfg/dualcgp_atari_pooling.yaml"
    "--encoder_cfg"
    help = "configuration script"
    default = "cfg/atari_encoder.yaml"
    "--controller_cfg"
    help = "configuration script"
    default = "cfg/atari_controller.yaml"
    "--game"
    help = "game rom name"
    default = "centipede"
    "--seed"
    help = "random seed for evolution"
    arg_type = Int
    default = 0
    "--ind"
    help = "individual for evaluation"
    arg_type = String
    default = ""
end
args = parse_args(ARGS, s)
Random.seed!(args["seed"])

##
encoder_cfg, controller_cfg, reducer = dualcgp_config(
    args["cfg"], args["game"], args["seed"]
)

##

# Temporarily open a game to retrieve parameters
game = Game(args["game"], 0)
out = get_rgb(game)
n_in = 3  # RGB images
n_out = length(getMinimalActionSet(game.ale))  # One output per legal action
img_size = size(out[1])
logid = string(Dates.now(), "_", args["game"], "_", args["seed"])
close!(game)

# Encoder configuration
encoder_cfg = get_config(
    args["encoder_cfg"];
    function_module=IICGP.CGPFunctions,
    n_in=n_in,
    img_size=img_size,
    id=logid
)

##

# Controller configuration
n_in_controller = encoder_cfg.n_out * encoder_cfg.features_size^2
controller_cfg = get_config(
    args["controller_cfg"];
    n_in=n_in_controller,
    n_out=n_out
)

"""
    play_atari(encoder::CGPInd, controller::CGPInd; seed=0, max_frames=18000)

Fitness function.
"""
function play_atari(encoder::CGPInd, controller::CGPInd; seed=0,
                    max_frames=18000)
    game = Game(args["game"], seed)
    reward = 0.0
    frames = 0
    while ~game_over(game.ale)
        output = IICGP.process(encoder, controller, get_rgb(game),
                               encoder_cfg.features_size)
        action = game.actions[argmax(output)]
        reward += act(game.ale, action)
        frames += 1
        if frames > max_frames
            break
        end
    end
    close!(game)
    [reward]
end


if length(args["ind"]) > 0
    ind = CGPInd(cfg, read(args["ind"], String))
    ftn = fitness(ind, inps, outs)
    println("Fitness: ", ftn)
else
    # Define mutate and fit functions
    function mutate(ind::CGPInd, ind_type::String)
        if ind_type == "encoder"
            return goldman_mutate(encoder_cfg, ind, init_function=IPCGPInd)
        elseif ind_type == "controller"
            return goldman_mutate(controller_cfg, ind)
        end
    end
    fit(encoder::CGPInd, controller::CGPInd) = play_atari(encoder, controller)
    # Create an evolution framework
    e = IICGP.DualCGPEvolution(encoder_cfg, controller_cfg, fit,
                               encoder_init_function=IPCGPInd, logid=logid)
    # Run evolution
    run!(e)
end
