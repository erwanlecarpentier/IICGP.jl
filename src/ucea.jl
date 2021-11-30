export UCEvo, evaluate, populate, generation, get_log

using Cambrian

import Cambrian.populate, Cambrian.evaluate, Cambrian.log_gen, Cambrian.save_gen


mutable struct UCInd <: Cambrian.Individual
    chromosome::Vector{Float64}
    fitnesses::Vector{Float64}
    expected_fitness::Float64
    lifetime::Int64
end

function UCInd(chromosome::Vector{Float64})
    UCInd(chromosome, Vector{Float64}(), -Inf, 0)
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

evaluate(e::UCEvo{T}) where T = UCEA.fitness_evaluate(e, e.fitness)
populate(e::UCEvo{T}) where T = UCEA.tournament_populate(e)

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

function get_log(e::UCEvo{T}) where T
    [:expected_fitness, :fitnesses, :lifetime]
end
