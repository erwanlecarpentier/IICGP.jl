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

# State-of-the-art maximum scores (rough estimate)
const soa_scores = Dict(
    "assault"=>14497.9,
    "asteroids"=>9412.0,
    "boxing"=>100.0,
    "breakout"=>800.0,
    "defender"=>993010.0,
    "freeway"=>30.0,
    "frostbite"=>8144.4,
    "gravitar"=>2350.0,
    "private_eye"=>15028.3,
    "pong"=>20.0,
    "riverraid"=>18184.4,
    "solaris"=>8324,
    "space_invaders"=>23846.0
)

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
const max_frames = mcfg.max_frames
const grayscale = mcfg.grayscale
const downscale = mcfg.downscale
const stickiness = mcfg.stickiness
const lck = ReentrantLock()
const max_n_active_nodes = ecfg.rows * ecfg.columns + ccfg.rows * ccfg.columns

const fitness_norm = [
    soa_scores[rom_name],
    max_n_active_nodes
]

function atari_score(
    encoder::CGPInd,
    reducer::Reducer,
    controller::CGPInd,
    seed::Int64;
    lck::ReentrantLock=lck,
    rom::String=rom_name,
    max_frames::Int64=max_frames,
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
            output = IICGP.process(encoder, reducer, controller, ccfg, s)
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
    reward
end

function sparsity_score(encoder::CGPInd, controller::CGPInd)
    n_enco_active = sum([nd.active for nd in encoder.nodes])
    n_cont_active = sum([nd.active for nd in controller.nodes])
    max_n_active_nodes - (n_enco_active + n_cont_active)
end

# User-defined fitness function (normalized)
function my_fitness(ind::NSGA2ECInd, seed::Int64)
    enco = IPCGPInd(ecfg, ind.e_chromosome)
    cont = CGPInd(ccfg, ind.c_chromosome)
    o1 = atari_score(enco, reducer, cont, seed)
    o2 = sparsity_score(enco, cont)
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
function my_init(cfg::NamedTuple) # cfg = mcfg
    [IICGP.NSGA2ECInd(
        cfg,
        IPCGPInd(ecfg).chromosome,
        CGPInd(ccfg).chromosome
    ) for _ in 1:cfg.n_population]
end

# Initial population containing best constant action individuals
function cstind_init(cfg::NamedTuple)
    game = Game(rom_name, 0)
    actions = game.actions
    close!(game)
    cstinds = get_cstind(cfg, ecfg, ccfg, actions)
end

cstind_init(mcfg) # TODO remove

##

# Create evolution framework
e = NSGA2Evo(mcfg, resdir, my_fitness, cstind_init)

# Run experiment
init_backup(mcfg.id, resdir, cfg_path)
for i in 1:-1#e.config.n_gen
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
