using ArcadeLearningEnvironment
using ArgParse
using Cambrian
using CartesianGeneticProgramming
using Dates
using IICGP
using Distributed
import Random
import Cambrian.mutate  # to extend the function
import Cambrian.evaluate  # to extend the function


s = ArgParseSettings()
@add_arg_table! s begin
    "--cfg"
    help = "configuration script"
    default = "cfg/test.yaml"
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

main_cfg, cont_cfg, reducer, bootstrap = IICGP.monocgp_config(args["cfg"], args["game"])

max_frames = main_cfg["max_frames"]
logid = cont_cfg.id

function play_atari(
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
        output = IICGP.process(reducer, controller, get_rgb(game))
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
    mutate(ind::CGPInd) = goldman_mutate(cont_cfg, ind)
    lck = ReentrantLock()
    fit(controller::CGPInd) = play_atari(reducer, controller, lck)
    evaluate(e::CGPEvolution) = IICGP.fitness_evaluate(e, e.fitness)
    e = CartesianGeneticProgramming.CGPEvolution(cont_cfg, fit)
    init_backup(logid, args["cfg"])
    run!(e)
    fetch_backup(logid, args["cfg"])
end
