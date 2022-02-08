export LUCIEEvo, LUCIEInd, evaluate, populate, generation

using Cambrian
using Statistics

import Cambrian.populate, Cambrian.evaluate, Cambrian.log_gen, Cambrian.save_gen


mutable struct LUCIEInd{T} <: Cambrian.Individual
    e_chromosome::Vector{T}
    c_chromosome::Vector{T}
    fitnesses::Vector{Float64}
	reached_frames::Vector{Int64}
    lifetime::Int64
	n_eval_init::Int64
	confidence_bound::Float64
end

function LUCIEInd{T}(e_chromosome::Vector{T}, c_chromosome::Vector{T}) where T
    LUCIEInd(e_chromosome, c_chromosome, Vector{Float64}(), Vector{Int64}(),
		0, 0, 0.0)
end

function LUCIEInd{T}(
	config::NamedTuple,
	e_chromosome::Vector{Float64},
	c_chromosome::Vector{Float64}
) where T
    LUCIEInd{T}(e_chromosome, c_chromosome)
end

mutable struct LUCIEEvo{T} <: AbstractEvolution
    config::NamedTuple
    population::Vector{T}
    fitness::Function
    gen::Int64 # current generation number
	step::Int64 # current step (number of pairs of evals during this generation)
	gen_n_eval::Int64
	total_n_eval::Int64
	bound_scale::Float64
	epsilon::Float64
	resdir::String
    atari_games::Vector{Game}
end

function LUCIEEvo{T}(
	config::NamedTuple,
    resdir::String,
	fitness::Function,
	init::Function,
    rom_name::String
) where T
	if config.n_eval_max == Inf
		@assert e.config.epsilon > 0.0
		@assert 0.0 < e.config.delta < 1.0
	end
	population = init(T, config)
	bound_scale = config.bound_scale
	epsilon = config.epsilon
	atari_games = [Game(rom_name, 0) for _ in 1:length(population)]
    LUCIEEvo(config, population, fitness, 0, 0, 0, 0, bound_scale, epsilon,
		resdir, atari_games)
end

evaluate(e::LUCIEEvo{T}) where T = fitness_evaluate(e, e.fitness)

function get_log(e::LUCIEEvo{T}) where T
    [:expected_fitness, :fitnesses, :lifetime]
end

median_fitness(ind::LUCIEInd) = length(ind.fitnesses) > 0 ? median(ind.fitnesses) : -Inf
mean_fitness(ind::LUCIEInd) = length(ind.fitnesses) > 0 ? mean(ind.fitnesses) : -Inf
lower_bound(ind::LUCIEInd) = mean_fitness(ind) - ind.confidence_bound
upper_bound(ind::LUCIEInd) = mean_fitness(ind) + ind.confidence_bound

function increment_lifetime!(e::LUCIEEvo{T}; n::Int64=1) where T
	for ind in e.population
		ind.lifetime += n
	end
end

function increment_n_eval!(e::LUCIEEvo{T}; n::Int64=1) where T
	e.gen_n_eval += n
	e.total_n_eval += n
	#e.total_n_eval_par += ceil(Int64, n / e.config.n_threads)
end

function get_seed(e::LUCIEEvo{T}) where T
	Int64((e.gen - 1) * e.config.n_eval_max / 2 + 2 * e.step)
end

function evaluate_new_ind!(e::LUCIEEvo{T}, fitness::Function) where T
	n_eval = sum([length(ind.fitnesses) < 1 for ind in e.population])
	Threads.@threads for i in eachindex(e.population)
		if length(e.population[i].fitnesses) < 1
			seed = get_seed(e)
			score = fitness(e.population[i], seed, e.atari_games[i], e.config.max_frames)
			push!(e.population[i].fitnesses, score)
		end
	end
	increment_lifetime!(e, n=n_eval)
	increment_n_eval!(e, n=n_eval)
	n_eval
end

"""
	validate(
		e::LUCIEEvo{T},
		ind_index::Int64,
		fitness::Function
	) where T

Validation function. Evaluate an individual sequentially for
`e.config.validation_size` runs with new seeds. Each run has a different seed,
never seen during training. All individuals of the generation are validated on
the same seeds.
"""
function validate(
	e::LUCIEEvo{T},
	ind_index::Int64,
	fitness::Function
) where T
	validation_fitnesses = Vector{Float64}()
	for i in 1:e.config.validation_size
		seed = e.config.n_gen * e.config.n_eval_max + i + e.gen * e.config.validation_size
		score = fitness(e.population[ind_index], seed, e.atari_games[ind_index], e.config.validation_max_frames)
		push!(validation_fitnesses, score)
	end
	validation_fitnesses
end

function evaluate_pair!(
	e::LUCIEEvo{T},
	fitness::Function,
	h_index::Int64,
	l_index::Int64
) where T
	@assert h_index < l_index
	Threads.@threads for i in [h_index, l_index]
		seed = get_seed(e)
		seed += i == h_index ? 1 : 0
		score = fitness(e.population[i], seed, e.atari_games[i], e.config.max_frames)
		push!(e.population[i].fitnesses, score)
	end
end

function update_bounds!(e::LUCIEEvo{T}) where T
	population_size = Float64(length(e.population))
	for i in eachindex(e.population)
		e.population[i].confidence_bound = confidence_bound(e, population_size, i)
	end
end

function update_n_eval_init!(e::LUCIEEvo{T}) where T
	for i in eachindex(e.population)
		e.population[i].n_eval_init = Float64(length(e.population[i].fitnesses))
	end
end

function confidence_bound(
	e::LUCIEEvo{T},
	population_size::Float64,
	i::Int64
) where T
	cb = 0.0
	u = Float64(length(e.population[i].fitnesses))
	if e.config.bound_type == "lucb1"
		l = Float64(e.population[i].lifetime)
		cb = sqrt(log(1.25 * population_size * l^4 / e.config.delta) / (2.0 * u))
	elseif e.config.bound_type == "lucie"
		# u_init = Float64(e.population[i].n_eval_init)
		cb = sqrt(log(2.3 * population_size * e.step^4 / e.config.delta) / (2.0 * u))
	elseif e.config.bound_type == "lucie-tmax"
		k = 1.21 + sum([1.0 / (j^1.1) for j in 1:e.config.n_eval_max])
		cb = sqrt(log(population_size * k * (e.gen^2.1) * (e.step^1.1) * (e.step + (e.gen-1.0) * e.config.n_eval_max) / e.config.delta) / (2.0 * u))
	elseif e.config.bound_type == "lucie-tinf"
		cb = sqrt(log(population_size * 4.45 * (e.gen^2.1) * (e.step^2.1) * (u^2.1) / e.config.delta) / (2.0 * u))
	else
		error("Bound type ", e.config.bound_type, " not implemented.")
	end
	e.bound_scale * cb
end

function sort_and_pick!(e::LUCIEEvo{T}) where T
	sort!(e.population, by=ind->mean_fitness(ind), rev=true)
	h_index = argmin([lower_bound(ind) for ind in e.population[1:e.config.n_elite]])
	l_index = e.config.n_elite + argmax([upper_bound(ind) for ind in e.population[e.config.n_elite+1:end]])
	h_index, l_index
end

function stopping_criterion(
	e::LUCIEEvo{T},
	h_index::Int64,
	l_index::Int64
) where T
	upper_l = upper_bound(e.population[l_index])
	lower_h = lower_bound(e.population[h_index])
	upper_l - lower_h < e.epsilon
end

function update_bound_scale!(e::LUCIEEvo{T}) where T
	if e.config.is_bound_scale_dynamic
		max_mean = maximum([mean_fitness(ind) for ind in e.population])
		min_mean = minimum([mean_fitness(ind) for ind in e.population])
		e.bound_scale = abs(max_mean - min_mean)
		e.bound_scale = max(e.bound_scale, 1.0)
	end
end

function update_epsilon!(e::LUCIEEvo{T}) where T
	if e.config.is_epsilon_dynamic
		e.epsilon = e.config.epsilon_ratio * e.bound_scale
	end
end

"""
	fitness_evaluate(e::LUCIEEvo{T}, fitness::Function) where T

Main evaluation function for LUCIEEvo.
"""
function fitness_evaluate(e::LUCIEEvo{T}, fitness::Function) where T
	e.gen_n_eval = 0
	n_init_eval = evaluate_new_ind!(e, fitness)
	e.step = floor(Int64, n_init_eval / 2)
	e.step = max(e.step, 1) # Domain check
	n_eval = e.config.n_eval_max - n_init_eval
	pac_evaluation(e, fitness, n_eval)
end

function pac_evaluation(e::LUCIEEvo{T}, fitness::Function, n_eval_max::Int64) where T
	update_n_eval_init!(e)
	update_bounds!(e)
	h_index, l_index = sort_and_pick!(e)
	n_eval = 0
	while !stopping_criterion(e, h_index, l_index)
		evaluate_pair!(e, fitness, h_index, l_index)
		increment_lifetime!(e, n=2)
		increment_n_eval!(e, n=2)
		e.step += 1
		n_eval += 2
		if n_eval >= n_eval_max
			break
		end
		update_bounds!(e)
		h_index, l_index = sort_and_pick!(e)
	end
	update_bound_scale!(e)
	update_epsilon!(e)
end

"""
	generation(e::LUCIEEvo{T}) where T

Main generation function for LUCIEEvo.
"""
function generation(e::LUCIEEvo{T}) where T
    nothing
end

function median_fitness_tournament_selection(
    pop::Vector{T},
    tournament_size::Int64
) where T
    inds = shuffle!(collect(1:length(pop)))
    sort(pop[inds[1:tournament_size]], by=ind->median_fitness(ind))[end]
end

"""
	tournament_populate(e::LUCIEEvo{T}) where T

Main populate function for LUCIEEvo.
"""
function tournament_populate(e::LUCIEEvo{T}) where T
    children = Vector{T}()
    for _ in e.config.n_elite+1:e.config.n_population
		parent = median_fitness_tournament_selection(e.population,
            e.config.tournament_size)
		child = T(parent.e_chromosome, parent.c_chromosome)
		child = mutate(child)
		push!(children, child)
    end
    return children
end

function populate(e::LUCIEEvo{T}) where T
    new_pop = Vector{T}()
    if e.config.greedy_elitism
        sort!(e.population, by=ind->mean_fitness(ind), rev=true)
    else
        sort!(e.population, by=ind->upper_bound(ind), rev=true)
    end
    for i in 1:e.config.n_elite
        push!(new_pop, e.population[i])
    end
    children = tournament_populate(e)
    push!(new_pop, children...)
    e.population = new_pop
end

"""
Logging
"""
function log_gen(e::LUCIEEvo{T}, do_validate::Bool) where T
	logid = e.config.id
	sep = ";"
	logged_data_header = ["gen_number", "fitnesses", "reached_frames",
		"total_n_eval", "gen_n_eval", "epsilon", "bound_scale", "dna_id", "validation_fitnesses"]
    if e.gen == 1
        f = open(joinpath(e.resdir, logid, "logs/logs.csv"), "w+")
		header = to_csv_row(logged_data_header, sep)
        write(f, header)
        close(f)
    end
	enco_path = joinpath(e.resdir, logid, Formatting.format("gens/encoder_{1:04d}", e.gen))
    cont_path = joinpath(e.resdir, logid, Formatting.format("gens/controller_{1:04d}", e.gen))
    mkpath(enco_path)
    mkpath(cont_path)
    for i in eachindex(e.population)
        dna_id = Formatting.format("{1:04d}", i)
		if do_validate
			validation_fitnesses = validate(e, i, e.fitness)
		else
			validation_fitnesses = NaN
		end
		# Log results
		f = open(joinpath(e.resdir, logid, "logs/logs.csv"), "a+")
		data = [
			e.gen, e.population[i].fitnesses,
			e.population[i].reached_frames, e.total_n_eval, e.gen_n_eval,
			e.epsilon, e.bound_scale, dna_id, validation_fitnesses
		]
        write(f, Formatting.format(to_csv_row(data, sep)))
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
