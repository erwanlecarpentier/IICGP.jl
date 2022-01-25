export LUCIEEvo, LUCIEInd, evaluate, populate, generation

using Cambrian
using Statistics


mutable struct LUCIEInd{T} <: Cambrian.Individual
    e_chromosome::Vector{T}
    c_chromosome::Vector{T}
    fitnesses::Vector{Float64}
    lifetime::Int64
	n_eval_init::Int64
	confidence_bound::Float64
end

function LUCIEInd{T}(e_chromosome::Vector{T}, c_chromosome::Vector{T}) where T
    LUCIEInd(e_chromosome, c_chromosome, Vector{Float64}(), 0, 0, 0.0)
end

mutable struct LUCIEEvo{T} <: AbstractEvolution
    config::NamedTuple
    population::Vector{T}
    fitness::Function
    gen::Int64 # current generation number
	step::Int64 # current step (number of pairs of evals during this generation)
	total_n_eval::Int64
	total_n_eval_par::Int64
	bound_scale::Float64
end

function LUCIEEvo{T}(config::NamedTuple, init::Function, fitness::Function) where T
	if config.n_eval == Inf
		@assert e.config.epsilon > 0.0
		@assert 0.0 < e.config.delta < 1.0
	end
	population = init(T, config)
	bound_scale = config.bound_scale
    LUCIEEvo(config, population, fitness, 0, 0, 0, 0, bound_scale)
end

evaluate(e::LUCIEEvo{T}) where T = fitness_evaluate(e, e.fitness)

function get_log(e::LUCIEEvo{T}) where T
    [:expected_fitness, :fitnesses, :lifetime]
end

mean_fitness(ind::LUCIEInd) = length(ind.fitnesses) > 0 ? mean(ind.fitnesses) : -Inf
lower_bound(ind::LUCIEInd) = mean_fitness(ind) - ind.confidence_bound
upper_bound(ind::LUCIEInd) = mean_fitness(ind) + ind.confidence_bound

function increment_lifetime!(e::LUCIEEvo{T}; n::Int64=1) where T
	for ind in e.population
		ind.lifetime += n
	end
end

function increment_n_eval!(e::LUCIEEvo{T}; n::Int64=1) where T
	e.total_n_eval += n
	e.total_n_eval_par += ceil(Int64, n / e.config.n_threads)
end

function evaluate_new_ind!(e::LUCIEEvo{T}, fitness::Function) where T
	n_eval = 0
	for i in eachindex(e.population)
		if length(e.population[i].fitnesses) < 1
			expected, noise = fitness(e.population[i])
			push!(e.population[i].fitnesses, expected + noise)
			e.population[i].expected_fitness = expected
			increment_lifetime!(e)
			n_eval += 1
		end
	end
	increment_n_eval!(e, n=n_eval)
	n_eval
end

function evaluate_pair!(
	e::LUCIEEvo{T},
	fitness::Function,
	h_index::Int64,
	l_index::Int64
) where T
	@assert h_index < l_index
	Threads.@threads for i in [h_index, l_index]
		expected, noise = fitness(e.population[i])
		push!(e.population[i].fitnesses, expected + noise)
		e.population[i].expected_fitness = expected
	end
	#increment_lifetime!(e, n=2) #TODO check
end

#=
function update_bounds!(e::LUCIEEvo{T}) where T
	update_bounds!(e.population, e.config.bounds_scale, e.config.delta)
end

function update_bounds!(
	population::Vector{T},
	bounds_scale::Float64,
	delta::Float64
) where T
	n = Float64(length(population))
	for i in eachindex(population)
		l = Float64(population[i].lifetime)
		u = Float64(length(population[i].fitnesses))
		population[i].confidence_bound = bounds_scale * sqrt(
			log(1.25 * n * l^4 / delta) / (2.0 * u)
		)
	end
end
=#

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
		u_init = Float64(e.population[i].n_eval_init)
		cb = sqrt(log(1.2 * population_size * e.step^3 * (u_init+e.step) / e.config.delta) / (2.0 * u))
	elseif e.config.bound_type == "lucie-tmax"
		k = 1.21 + sum([1.0 / (j^1.1) for j in 1:e.config.n_eval])
		cb = sqrt(log(population_size * k * (e.gen^2.1) * (e.step^1.1) * (e.step + (e.gen-1.0) * e.config.n_eval) / e.config.delta) / (2.0 * u))
	elseif e.config.bound_type == "lucie-tinf"
		cb = sqrt(log(population_size * 4.45 * (e.gen^2.1) * (e.step^2.1) * (u^2.1) / e.config.delta) / (2.0 * u))
	else
		error("Bound type ", e.config.bound_type, " not implemented.")
	end
	e.bounds_scale * cb
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
	upper_l - lower_h < e.config.epsilon
end

function update_bound_scale!(e::LUCIEEvo{T}) where T
	if e.config.is_bound_scale_dynamic
		e.bound_scale = max([mean_fitness(ind) for ind in e.population])
	end
end

"""
	fitness_evaluate(e::LUCIEEvo{T}, fitness::Function) where T

Main evaluation function for LUCIEEvo.
"""
function fitness_evaluate(e::LUCIEEvo{T}, fitness::Function) where T
	n_init_eval = evaluate_new_ind!(e, fitness)
	e.step = floor(Int64, n_init_eval / 2)
	n_eval = e.config.n_eval - n_init_eval
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
end

"""
	generation(e::LUCIEEvo{T}) where T

Main generation function for LUCIEEvo.
"""
function generation(e::LUCIEEvo{T}) where T
    nothing
end

"""
	tournament_populate(e::LUCIEEvo{T}) where T

Main populate function for LUCIEEvo.
"""
function tournament_populate(e::LUCIEEvo{T}) where T
    children = Vector{T}()
    for _ in e.config.n_elite+1:e.config.n_population
		parent = tournament_selection(e.population,
            e.config.tournament_size, mean_fitness)
		child = T(parent.chromosome)
		if e.config.p_crossover > 0 && rand() < e.config.p_crossover
			parents = vcat(parent, [tournament_selection(e.population,
				e.config.tournament_size, mean_fitness) for i in 2:e.config.n_parents])
			child = crossover(parents)
		end
		if e.config.p_mutation > 0 && rand() < e.config.p_mutation
			child = mutate(child, e.config.m_rate)
		end
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
