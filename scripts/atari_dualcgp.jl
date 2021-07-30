using ArcadeLearningEnvironment
using ArgParse
using Cambrian
using CartesianGeneticProgramming
using Dates
using IICGP
using Distributed
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
    default = "cfg/dualcgp_test.yaml" # dualcgp_atari_pooling | dualcgp_atari_centroid
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
seed = args["seed"]
Random.seed!(seed)

main_cfg, enco_cfg, cont_cfg, reducer, bootstrap = IICGP.dualcgp_config(args["cfg"],
                                                                        args["game"])
max_frames = main_cfg["max_frames"]
logid = enco_cfg.id

function play_atari(
    encoder::CGPInd,
    reducer::Reducer,
    controller::CGPInd,
    lck::ReentrantLock;
    seed=seed,
    max_frames=max_frames
)
    game = Game(args["game"], seed, lck=lck)
    reward = 0.0
    frames = 0
    while ~game_over(game.ale)
        output = IICGP.process(encoder, reducer, controller, get_rgb(game))
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
            return goldman_mutate(enco_cfg, ind, init_function=IPCGPInd)
        elseif ind_type == "controller"
            return goldman_mutate(cont_cfg, ind)
        end
    end
    lck = ReentrantLock()
    fit(encoder::CGPInd, controller::CGPInd) = play_atari(encoder, reducer,
                                                          controller, lck)
    # Create an evolution framework
    e = IICGP.DualCGPEvolution(enco_cfg, cont_cfg, fit,
                               encoder_init_function=IPCGPInd, logid=logid,
                               bootstrap=bootstrap, game=args["game"])
    # Run evolution
    run!(e)
end
