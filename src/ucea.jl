export UCEvo, UCInd, evaluate, populate, generation

using Cambrian
using Statistics

import Cambrian.populate, Cambrian.evaluate, Cambrian.log_gen, Cambrian.save_gen


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

mutable struct UCEvo{T} <: Cambrian.AbstractEvolution
    config::NamedTuple
    population::Vector{T}
    fitness::Function
    gen::Int64
end

function UCEvo{T}(config::NamedTuple, init::Function, fitness::Function) where T
    population = init(T, config)
    UCEvo(config, population, fitness, 0)
end

evaluate(e::UCEvo{T}) where T = fitness_evaluate(e, e.fitness)
populate(e::UCEvo{T}) where T = tournament_populate(e)

function ucb(ind::UCInd)
	n_eval = length(ind.fitnesses)
	if n_eval > 0
		return mean(ind.fitnesses) + sqrt(2.0 * log(ind.lifetime) / n_eval)
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

"""
    generation(e::UCEvo{T}) where T

Select elites
"""
function generation(e::UCEvo{T}) where T
    if e.config.greedy_elitism
        sort!(e.population, by=ind->mean_fitness(ind), rev=true)
    else
        sort!(e.population, by=ind->ucb(ind), rev=true)
    end
    e.population = e.population[1:e.config.n_elite]
end

function increment_lifetime!(e::UCEvo{T}) where T
	for ind in e.population
		ind.lifetime += 1
	end
end

function fitness_evaluate(e::UCEvo{T}, fitness::Function) where T
	n_children = e.config.n_population - e.config.n_elite
	# TODO here

	for i in 1:e.config.n_eval
		sort!(e.population, by=ind->ucb(ind), rev=true)
		expected, noise = fitness(e.population[1])
		push!(e.population[1].fitnesses, expected+noise)
		e.population[1].expected_fitness = expected
		increment_lifetime!(e)
	end
end
