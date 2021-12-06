export UCEvo, UCInd, evaluate, populate, generation, mean_fitness

using Cambrian
using Statistics

import Cambrian.populate, Cambrian.evaluate, Cambrian.log_gen, Cambrian.save_gen


"""
Individuals definition
"""
mutable struct UCInd <: Cambrian.Individual
    e_chromosome::Vector{Float64}
    c_chromosome::Vector{Float64}
    fitnesses::Vector{Float64}
    lifetime::Int64
    reached_frames::Int64
end

function UCInd(e_chromosome::Vector{Float64}, c_chromosome::Vector{Float64})
    UCInd(e_chromosome, c_chromosome, Vector{Float64}(), 0, 0)
end

function UCInd(
	config::NamedTuple,
	e_chromosome::Vector{Float64},
	c_chromosome::Vector{Float64}
)
    UCInd(e_chromosome, c_chromosome)
end

"""
Evolution framework
"""
mutable struct UCEvo{T} <: Cambrian.AbstractEvolution
    config::NamedTuple
    logid::String
    logger::CambrianLogger
	resdir::String
    population::Vector{T}
    fitness::Function
    gen::Int64
    atari_games::Vector{Game}
end

function UCEvo{T}(
	config::NamedTuple,
    resdir::String,
	fitness::Function,
    init_population::Function,
    rom_name::String
) where T
    logid = config.id
    log_path = joinpath(resdir, logid, "logs/logs.csv")
    logger = CambrianLogger(log_path)
    population = init_population(T, config)
	# n_children = config.n_population - config.n_elite
	atari_games = [Game(rom_name, 0) for _ in 1:length(population)]
    UCEvo(config, logid, logger, resdir, population, fitness, 0, atari_games)
end

evaluate(e::UCEvo{T}) where T = fitness_evaluate(e, e.fitness)
populate(e::UCEvo{T}) where T = tournament_populate(e)

ucb(m::Float64, n_total::Int64, n_eval::Int64) = m + sqrt(2.0 * log(n_total) / n_eval)

function ucb(ind::UCInd)
	n_eval = length(ind.fitnesses)
	if n_eval > 0
		return ucb(mean(ind.fitnesses), ind.lifetime, n_eval)
	else
		return Inf
	end
end

function mean_fitness(ind::UCInd)
	if length(ind.fitnesses) > 0
		return mean(ind.fitnesses)
	else
		return -Inf
	end
end

function increment_lifetime!(e::UCEvo{T}, n::Int64) where T
	for ind in e.population
		ind.lifetime += n
	end
end

"""
Elite selection function
"""
function generation(e::UCEvo{T}) where T
    if e.config.greedy_elitism
        sort!(e.population, by=ind->mean_fitness(ind), rev=true)
    else
        sort!(e.population, by=ind->ucb(ind), rev=true)
    end
    e.population = e.population[1:e.config.n_elite]
end

"""
Evaluation function
"""
function fitness_evaluate(e::UCEvo{T}, fitness::Function) where T
	if e.config.surrogate
		if e.gen == 1
			exact_fitness_evaluate(e, fitness)
		else
			surrogate_fitness_evaluate(e, fitness)
		end
	else
		exact_fitness_evaluate(e, fitness)
	end
end

"""
An individual is not evaluated if enough evaluations have been made.
"""
function evaluation_utility(n_eval_max::Int64, ind::UCInd) where T
	if n_eval_max > 0
		if length(ind.fitnesses) < n_eval_max
			ucb(ind)
		else
			-Inf
		end
	else
		ucb(ind)
	end
end

function evaluation_utility(
	n_eval_max::Int64,
	m::Float64,
	n_total::Int64,
	n_eval::Int64
) where T
	if n_eval_max > 0
		if n_eval < n_eval_max
			ucb(m, n_total, n_eval)
		else
			-Inf
		end
	else
		ucb(m, n_total, n_eval)
	end
end

function exact_fitness_evaluate(e::UCEvo{T}, fitness::Function) where T
	# 1. Evaluate all new individuals in parallel
	n_children = e.config.n_population - e.config.n_elite
	sort!(e.population, by=ind->ucb(ind), rev=true) # Children are 1st
	n = e.gen == 1 ? length(e.population) : n_children
	#=
	for i in 1:n
		push!(e.population[i].fitnesses,
			  fitness(e.population[i], e.gen, e.atari_games[i]))
	end
	=#
	lck = ReentrantLock()
	@sync for i in 1:n
        Threads.@spawn begin
  			f = fitness(e.population[i], e.gen, e.atari_games[i])
  			lock(lck)
  			try
  				push!(e.population[i].fitnesses, f)
  			finally
  				unlock(lck)
  			end
        end
    end
	increment_lifetime!(e, n)
	@assert all([length(ind.fitnesses) > 0 for ind in e.population])
	# 2. Finish evaluation budget sequentially
	n_remaining_eval = e.config.n_eval - n
	for _ in 1:n_remaining_eval
		sort!(e.population, by=ind->evaluation_utility(e.config.n_eval_max, ind), rev=true)
		push!(e.population[1].fitnesses,
			  fitness(e.population[1], e.gen, e.atari_games[1]))
		increment_lifetime!(e, 1)
	end
end

function surrogate_fitness_evaluate(e::UCEvo{T}, fitness::Function) where T
	# 1. Evaluate all new individuals in parallel
	n_children = e.config.n_population - e.config.n_elite
	sort!(e.population, by=ind->ucb(ind), rev=true) # Children are 1st
	lck = ReentrantLock()
	@sync for i in 1:n_children
        Threads.@spawn begin
			# OUTDATED unsafe (I thought it was safe)
			#=push!(e.population[i].fitnesses,
				fitness(e.population[i], e.gen, e.atari_games[i]))=#
			# NEW safe
			f = fitness(e.population[i], e.gen, e.atari_games[i])
			lock(lck)
			try
				push!(e.population[i].fitnesses, f)
			finally
				unlock(lck)
			end
        end
    end
	increment_lifetime!(e, n_children)
	@assert all([length(ind.fitnesses) > 0 for ind in e.population])
	# 2. Determine individuals to evaluate next
	n_remaining_eval = e.config.n_eval - n_children
	f = [mean_fitness(ind) for ind in e.population]
	N = [ind.lifetime for ind in e.population]
	n = [length(ind.fitnesses) for ind in e.population]
	to_eval = Vector{Int64}()
	for i in 1:n_remaining_eval
		utilities = [evaluation_utility(e.config.n_eval_max, f[i], N[i], n[i]) for i in eachindex(f)]
		index = argmax(utilities)
		push!(to_eval, index)
		N .+= 1
		n[index] += 1
	end
	# 3. Evaluate remaining individuals
	lck = ReentrantLock()
	@sync for k in eachindex(to_eval)
        Threads.@spawn begin
			i = to_eval[k]
			# OUTDATED unsafe
			#=push!(e.population[i].fitnesses,
				fitness(e.population[i], e.gen, e.atari_games[i]))=#
			# NEW safe
			f = fitness(e.population[i], e.gen, e.atari_games[i])
			lock(lck)
			try
				push!(e.population[i].fitnesses, f)
			finally
				unlock(lck)
			end
		end
    end
	increment_lifetime!(e, n_remaining_eval)
end

"""
Populate function
"""
function tournament_populate(e::UCEvo{T}) where T
    children = Vector{T}()
    for _ in e.config.n_elite+1:e.config.n_population
        parent = ucb_tournament_selection(e.population, e.config.tournament_size)
        push!(children, mutate(parent))
    end
    push!(e.population, children...)
end

function ucb_tournament_selection(
    pop::Vector{T},
    tournament_size::Int64
) where T
    inds = shuffle!(collect(1:length(pop)))
    sort(pop[inds[1:tournament_size]], by=ind->ucb(ind))[end]
end

function fitness_tournament_selection(
    pop::Vector{T},
    tournament_size::Int64
) where T
    inds = shuffle!(collect(1:length(pop)))
    sort(pop[inds[1:tournament_size]], by=ind->ind.fitness)[end]
end

"""
Logging
"""
function log_gen(e::UCEvo{T}) where T
	sep = ";"
    if e.gen == 1
        f = open(joinpath(e.resdir, e.logid, "logs/logs.csv"), "w+")
        write(f, string("gen_number", sep, "fitnesses", sep,
			"reached_frames", sep, "dna_id\n"))
        close(f)
    end
	enco_path = joinpath(e.resdir, e.logid, Formatting.format("gens/encoder_{1:04d}", e.gen))
    cont_path = joinpath(e.resdir, e.logid, Formatting.format("gens/controller_{1:04d}", e.gen))
    mkpath(enco_path)
    mkpath(cont_path)
    for i in eachindex(e.population)
        dna_id = Formatting.format("{1:04d}", i)
		# Log results
		f = open(joinpath(e.resdir, e.logid, "logs/logs.csv"), "a+")
        write(f, Formatting.format(string(e.gen, sep,
			   e.population[i].fitnesses, sep,
			   e.population[i].reached_frames, sep, dna_id, "\n")))
        close(f)
		# Log individuals
		ind_fit = [mean_fitness(e.population[i])]
		enco = IPCGPInd(e.config.e_config, e.population[i].e_chromosome)
		enco.fitness .= ind_fit
		f = open(string(enco_path, "/", dna_id, ".dna"), "w+")
        write(f, string(enco))
        close(f)
        cont = CGPInd(e.config.c_config, e.population[i].c_chromosome)
		cont.fitness .= ind_fit
        f = open(string(cont_path, "/", dna_id, ".dna"), "w+")
        write(f, string(cont))
        close(f)
    end
end
