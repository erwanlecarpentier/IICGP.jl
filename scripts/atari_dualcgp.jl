using ArcadeLearningEnvironment
using ArgParse
using Cambrian
using CartesianGeneticProgramming
using Dates
using IICGP
# using Distributed
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
    default = "cfg/test_dual.yaml"
    "--game"
    help = "game rom name"
    default = "assault"
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
const game = args["game"]
const seed = args["seed"]
Random.seed!(seed)

main_cfg, enco_cfg, cont_cfg, reducer, bootstrap = IICGP.dualcgp_config(
    args["cfg"], game
)
const max_frames = main_cfg["max_frames"]
const stickiness = main_cfg["stickiness"]
const grayscale = main_cfg["grayscale"]
const downscale = main_cfg["downscale"]
const logid = enco_cfg.id
const state_ref = get_state_ref(game, seed)

function play_atari(
    encoder::CGPInd,
    reducer::Reducer,
    controller::CGPInd,
    lck::ReentrantLock;
    rom=game,
    seed=seed,
    rom_state_ref=state_ref,
    max_frames=max_frames,
    grayscale=grayscale,
    downscale=downscale,
    stickiness=stickiness
)
    Random.seed!(seed)
    game = Game(rom, seed, lck=lck, state_ref=rom_state_ref)
    reward = 0.0
    frames = 0
    prev_action = 0
    while ~game_over(game.ale)
        if rand() > stickiness || frames == 0
            # s = get_state(game, grayscale, downscale)  # TODO put back
            # output = IICGP.process(encoder, reducer, controller, s)  # TODO put back
            # action = game.actions[argmax(output)]  # TODO put back
            action = game.actions[rand(1:length(game.actions))]  # TODO remove
        else
            action = prev_action
        end
        println("Thread ", Threads.threadid(), " rand = ", rand(), " frame = ", frames)  # TODO remove
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
                               bootstrap=bootstrap, game=game)
    # Run evolution
    init_backup(logid, args["cfg"])
    run!(e)
end
