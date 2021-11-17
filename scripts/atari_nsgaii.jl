using ArcadeLearningEnvironment
using ArgParse
using Cambrian
using CartesianGeneticProgramming
using Dates
using IICGP
using Random
using UnicodePlots
using LinearAlgebra

import Cambrian.mutate

out(plt) = println(IOContext(stdout, :color=>true), plt)
default_resdir = joinpath(dirname(@__DIR__), "results")
default_cfgdir = joinpath(dirname(@__DIR__), "cfg")

function dict2namedtuple(d::Dict)
    (; (Symbol(k)=>v for (k, v) in d)...)
end

function display_paretto(e::NSGA2Evo)
    o1 = [ind.fitness[1] for ind in e.population]
    o2 = [ind.fitness[2] for ind in e.population]
    out(scatterplot(o1, o2, title = "Paretto front"))#, xlim=[0,1], ylim=[0,1]))
end

s = ArgParseSettings()
@add_arg_table! s begin
    "--cfg"
    help = "configuration script"
    default = joinpath(default_cfgdir, "eccgp_atari.yaml")
    "--game"
    help = "game rom name"
    default = "freeway"
    "--seed"
    help = "random seed"
    default = 0
    "--out"
    help = "output directory"
    arg_type = String
    default = default_resdir
end

args = parse_args(ARGS, s)
const cfg_path = args["cfg"]
const rom_name = args["game"]
#const seed = args["seed"]
const resdir = args["out"]
mcfg, ecfg, ccfg, reducer, bootstrap = IICGP.dualcgp_config(cfg_path, rom_name)
mcfg = dict2namedtuple(mcfg)
const max_f = mcfg.max_frames
const grayscale = mcfg.grayscale
const downscale = mcfg.downscale
const stickiness = mcfg.stickiness
const lck = ReentrantLock()
const fitness_norm = [1.0, 1.0] # TODO set fitness_norm

function play_atari(
    encoder::CGPInd,
    reducer::Reducer,
    controller::CGPInd,
    seed::Int64;
    lck::ReentrantLock=lck,
    rom::String=rom_name,
    max_frames::Int64=max_f,
    grayscale::Bool=grayscale,
    downscale::Bool=downscale,
    stickiness::Float64=stickiness
)
    Random.seed!(seed)
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
    reward + rand(mt)
end

# User-defined fitness function (normalized)
function my_fitness(ind::NSGA2ECInd, seed::Int64)
    enco = IPCGPInd(ecfg, ind.e_chromosome)
    cont = CGPInd(ccfg, ind.c_chromosome)
    o1 = play_atari(enco, reducer, cont, seed)
    o2 = 1.0
    [o1, o2] ./ fitness_norm
end

# User-defined mutation function
function mutate(ind::IICGP.NSGA2ECInd)
    e = IPCGPInd(ecfg, ind.e_chromosome)
    e_child = goldman_mutate(ecfg, e, init_function=IPCGPInd)
    c = CGPInd(ccfg, ind.c_chromosome)
    c_child = goldman_mutate(ccfg, c)
    NSGA2ECInd(mcfg, e_child.chromosome, c_child.chromosome)
end

# User-defined population initialization function
function my_init(cfg::NamedTuple)
    [IICGP.NSGA2ECInd(
        mcfg,
        IPCGPInd(ecfg).chromosome,
        CGPInd(ccfg).chromosome
    ) for _ in 1:cfg.n_population]
end

# Create evolution framework
e = NSGA2Evo(mcfg, resdir, my_fitness, my_init)

# Run experiment
init_backup(mcfg.id, resdir, cfg_path)
for i in 1:e.config.n_gen
    e.gen += 1
    if e.gen > 1
        populate(e)
    end
    evaluate(e)
    display_paretto(e)
    new_population = generation(e) # Externalized for logging
    if ((e.config.log_gen > 0) && mod(e.gen, e.config.log_gen) == 0)
        log_gen(e, fitness_norm, is_ec=true)
    end
    e.population = new_population
    #=if ((e.config.save_gen > 0) && mod(e.gen, e.config.save_gen) == 0)
        save_gen(e)
    end=#
end
