using ArcadeLearningEnvironment
using ArgParse
using Cambrian
using CartesianGeneticProgramming
using Dates
using IICGP
using Random
using UnicodePlots # TODO remove

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

function print_usage()
	out = read(`top -bn1 -p $(getpid())`, String)
	res = split(split(out,  "\n")[end-1])
	println("RES: ", res[6], "   %MEM: ", res[10], "   %CPU: ", res[9])
	parse(Float64, replace(res[10], "," => "."))
end


#=
function display_paretto(e::NSGA2Evo)
    o1 = [ind.fitness[1] for ind in e.population]
    o2 = [ind.fitness[2] for ind in e.population]
    out(scatterplot(o1, o2, title = "Paretto front"))#, xlim=[0,1], ylim=[0,1]))
end
=#

s = ArgParseSettings()
@add_arg_table! s begin
    "--cfg"
    help = "configuration script"
    default = joinpath(default_cfgdir, "eccgp_atari.yaml")
    "--game"
    help = "game rom name"
    default = "boxing"
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

# TODO remove START
#=
gtest = Game(rom_name, 1)
stest = get_state(gtest, grayscale, downscale)
close!(gtest)
=#
# TODO remove END

const fitness_norm = [
    soa_scores[rom_name],
    max_n_active_nodes
]

function atari_score(
	game::Game,
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
	# 1 %MEM in [22.9, 25] reset every 300 (went until 800)
    Random.seed!(seed)
    mt = MersenneTwister(seed)
    #game = Game(rom, seed, lck=lck)
	IICGP.reset!(game)
    IICGP.reset!(reducer) # zero buffers
    reward = 0.0
    frames = 0
    prev_action = Int32(0)
	#return rand() # TODO remove
	# 3 %MEM in [4.9, 5.5] reset every 50 (went until 300)
    while ~game_over(game.ale)
		#output = IICGP.process(encoder, reducer, controller, ccfg, stest) # TODO remove
		s = get_state(game, grayscale, downscale) # TODO remove
		#= TODO put back
		if rand(mt) > stickiness || frames == 0
            s = get_state(game, grayscale, downscale)
            output = IICGP.process(encoder, reducer, controller, ccfg, s)
            action = game.actions[argmax(output)]
        else
            action = prev_action
        end
		=#
		action = game.actions[rand(1:length(game.actions))] # TODO remove
        reward += act(game.ale, action)
        frames += 1
        prev_action = action
        if frames > max_frames
            break
        end
		# 5 %MEM around 5.2 +/- 0.2
    end
    #close!(game)
    reward
	# 4 %MEM in [5, Inf?] no reset? (went until 90) with IICGP.reset!(game)
	# 2 %MEM in [22.9, Inf?] no reset? (went until 90) with reset!(game)
end

function sparsity_score(encoder::CGPInd, controller::CGPInd)
    n_enco_active = sum([nd.active for nd in encoder.nodes])
    n_cont_active = sum([nd.active for nd in controller.nodes])
    max_n_active_nodes - (n_enco_active + n_cont_active)
end

# User-defined fitness function (normalized)
function my_fitness(ind::NSGA2ECInd, seed::Int64, game::Game)
    enco = IPCGPInd(ecfg, ind.e_chromosome)
    cont = CGPInd(ccfg, ind.c_chromosome)
    o1 = atari_score(game, enco, reducer, cont, seed)
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
function random_init(cfg::NamedTuple) # cfg = mcfg
    [IICGP.NSGA2ECInd(
        cfg,
        IPCGPInd(ecfg).chromosome,
        CGPInd(ccfg).chromosome
    ) for _ in 1:cfg.n_population]
end

# Initial population containing best constant action individuals
function cstind_init(cfg::NamedTuple)
    # Create cst individuals
    cstinds = IICGP.get_cstind(rom_name, cfg, ecfg, ccfg, reducer)
    # Evaluate cst individuals and sort by 1st objective
    @inbounds for i in eachindex(cstinds)
		seed = 0
		game = Game(rom_name, seed)
		cstinds[i].fitness .= my_fitness(cstinds[i], seed, game)
		close!(game)
    end
	sort!(cstinds, by = ind -> ind.fitness[1], rev = true)
    # Select best n_population individuals (fill lacking with random)
	if length(cstinds) > cfg.n_population
		cstinds =  cstinds[1:cfg.n_population]
	else
		push!(cstinds, [IICGP.NSGA2ECInd(cfg, IPCGPInd(ecfg).chromosome,
			  CGPInd(ccfg).chromosome) for _ in 1:cfg.n_population-length(cstinds)]...)
	end
	@assert length(cstinds) == cfg.n_population
	cstinds
end

# Create evolution framework
e = NSGA2Evo(mcfg, resdir, my_fitness, random_init, rom_name) # TODO put back cstind_init
mem_usage = Vector{Float64}()

# Run experiment
init_backup(mcfg.id, resdir, cfg_path)
gc_freq = 10
for i in 1:e.config.n_gen
    e.gen += 1
    if e.gen > 1
        populate(e)
    end
    evaluate(e)
    new_population = generation(e) # Externalized for logging
    if ((e.config.log_gen > 0) && mod(e.gen, e.config.log_gen) == 0)
        log_gen(e, fitness_norm, is_ec=true)
    end
    e.population = new_population
    #=if ((e.config.save_gen > 0) && mod(e.gen, e.config.save_gen) == 0)
        save_gen(e)
    end=#
	# GC
	#=if mod(i, gc_freq) == 0
		GC.gc()
	end
	GC.gc()
	=#
	# Display memory
	mem = print_usage()
	push!(mem_usage, mem)
	out(lineplot(mem_usage, title = "%MEM"))
end

# Close games
for g in e.atari_games
	close!(g)
end
