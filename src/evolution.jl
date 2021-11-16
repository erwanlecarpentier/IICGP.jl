export DualCGPEvolution, DualCGPGAEvo, NSGA2Evo, generation

import Cambrian.populate, Cambrian.evaluate, Cambrian.log_gen, Cambrian.save_gen
using Statistics

mutable struct NSGA2Evo{T} <: Cambrian.AbstractEvolution
    config::NamedTuple
    logid::String
    #logger::CambrianLogger
    population::Array{T}
    fitness::Function
    gen::Int64
end

function NSGA2Evo(
    config::NamedTuple,
    resdir::String,
    fitness::Function,
    init_population::Function
)
    logid = config.id
    log_path = joinpath(resdir, logid)
    #logger = CambrianLogger(log_path)
    population = init_population(config)
    NSGA2Evo(config, logid, population, fitness, 0)
end

populate(e::NSGA2Evo{T}) where T = IICGP.nsga2_populate(e)
evaluate(e::NSGA2Evo) = IICGP.fitness_evaluate(e, e.fitness)

function generation(e::NSGA2Evo)
    # Sort all individuals according to Pareto efficiency
    fast_non_dominated_sort!(e)
    # Select elites as most Pareto efficient solutions
    new_population = Vector{NSGA2Ind}()
    sort!(e.population, by = ind -> ind.rank)
    current_rank = 1
    i_start = 1
    i_end = findlast(ind -> ind.rank == current_rank, e.population)
    while length(new_population) < e.config.n_elite
        n_candidates = i_end - i_start + 1
        if !(length(new_population) + n_candidates > e.config.n_elite)
            # Add all the individuals of this rank
            push!(new_population,
                  [NSGA2IndCopy(ind) for ind in e.population[i_start:i_end]]...)
        else
            # Compute crowding distances and add less crowded individuals
            assign_crowding_distances!(e, current_rank)
            sort!(e.population, by = ind -> ind.crowding_distance, rev=true)
            push!(new_population, [NSGA2IndCopy(ind) for ind in
                  e.population[1:e.config.n_elite-length(new_population)]]...)
        end
        current_rank += 1
        i_start = i_end + 1
        i_end = findlast(ind -> ind.rank == current_rank, e.population)
    end
    e.population = new_population
end

"""
    assign_crowding_distances!(e::NSGA2Evo, rank::Int64)

Assign crowding distances as defined in [1] for individuals with rank
corresponding to the input rank.

[1] Deb, Kalyanmoy, et al. "A Fast and Elitist Multiobjective Genetic
Algorithm: NSGA-II." IEEE transactions on evolutionary computation 6.2
(2002): 182-197.
"""
function assign_crowding_distances!(e::NSGA2Evo, rank::Int64)
    subpop = view(e.population, findall(ind -> ind.rank == rank, e.population))
    for ind in subpop
        ind.crowding_distance = 0
    end
    l = length(subpop)
    @inbounds for i in 1:e.config.d_fitness
        sort!(subpop, by = ind -> ind.fitness[i])
        if subpop[1].fitness[i] != subpop[end].fitness[i]
            subpop[1].crowding_distance = Inf
            subpop[end].crowding_distance = Inf
            cd_norm = subpop[end].fitness[i] - subpop[1].fitness[i]
            for j in 2:l-1
                cd_dist = subpop[j+1].fitness[i] - subpop[j-1].fitness[i]
                subpop[j].crowding_distance += cd_dist / cd_norm
            end
        end
    end
end

"""
    fast_non_dominated_sort!(e::NSGA2Evo)

Fast non-dominated sorting algorithm from the NSGA2 paper [1].

[1] Deb, Kalyanmoy, et al. "A Fast and Elitist Multiobjective Genetic
Algorithm: NSGA-II." IEEE transactions on evolutionary computation 6.2
(2002): 182-197.
"""
function fast_non_dominated_sort!(e::NSGA2Evo)
    # Re-initialize individuals statistics
    for ind in e.population
        ind.rank = 0
        ind.domination_count = 0
        empty!(ind.domination_list)
        ind.crowding_distance = 0.0
    end
    # Set domination lists, counts and 1st ranks
    @inbounds for i in 1:length(e.population)
        for j in i+1:length(e.population)
            if dominates(e.population[i], e.population[j])
                push!(e.population[i].domination_list, j)
                e.population[j].domination_count += 1
            elseif dominates(e.population[j], e.population[i])
                push!(e.population[j].domination_list, i)
                e.population[i].domination_count += 1
            end
        end
        if e.population[i].domination_count == 0
            e.population[i].rank = 1
        end
    end
    # Set ranks higher than 2
    current_rank = 2
    while any([ind.rank == current_rank - 1 for ind in e.population])
        for ind in e.population
            if ind.rank == current_rank - 1
                @inbounds for index in ind.domination_list
                    e.population[index].domination_count -= 1
                    if e.population[index].domination_count == 0
                        e.population[index].rank = current_rank
                    end
                end
            end
        end
        current_rank += 1
    end
end

"""
    init_chomosomes(cfg::NamedTuple)

Initialize a symbolic population of individual with random chromosomes of sizes
corresponding to the input configuration file.
"""
function init_sympop(cfg::NamedTuple)::Vector{SymInd}
    population = Vector{SymInd}(undef, cfg.n_population)
    for i in 1:cfg.n_population
        chromosome = rand_CGPchromosome(cfg)
        population[i] = SymInd(chromosome, i, cfg.type)
    end
    population
end

mutable struct DualCGPGAEvo <: Cambrian.AbstractEvolution
    config::NamedTuple
    logid::String
    resdir::String
    encoder_config::NamedTuple
    encoder_sympop::Vector{SymInd}
    encoder_logger::CambrianLogger
    controller_config::NamedTuple
    controller_sympop::Vector{SymInd}
    controller_logger::CambrianLogger
    fitness::Function
    fitness_matrix::Matrix{Float64}
    elites_matrix::Matrix{Bool}
    eval_matrix::Matrix{Bool}
    eval_mutant::Bool
    n_eval::Int64
    n_elite::Int64
    tournament_size::Int64
    gen::Int64
end

populate(e::IICGP.DualCGPGAEvo) = IICGP.ga_populate(e)
evaluate(e::IICGP.DualCGPGAEvo) = IICGP.fitness_evaluate(e, e.fitness)

"""
    DualCGPGAEvo(
        main_config::Dict,
        encoder_config::NamedTuple,
        controller_config::NamedTuple,
        fitness::Function,
        logid::String,
        resdir::String
    )

Dual CGP evolution framework.
"""
function DualCGPGAEvo(
    main_config::Dict,
    encoder_config::NamedTuple,
    controller_config::NamedTuple,
    fitness::Function,
    logid::String,
    resdir::String
)
    encoder_logfile = joinpath(resdir, "logs", logid, "encoder.csv")
    controller_logfile = joinpath(resdir, "logs", logid, "controller.csv")
    encoder_logger = CambrianLogger(encoder_logfile)
    controller_logger = CambrianLogger(controller_logfile)
    encoder_sympop = init_sympop(encoder_config)
    controller_sympop = init_sympop(controller_config)
    @assert encoder_config.d_fitness == controller_config.d_fitness
    config = (
        d_fitness=encoder_config.d_fitness,
        seed=encoder_config.seed,
        n_gen=max(encoder_config.n_gen, controller_config.n_gen),
        log_gen=min(encoder_config.log_gen, controller_config.log_gen),
        save_gen=min(encoder_config.save_gen, controller_config.save_gen)
    )
    mat_size = (encoder_config.n_population, controller_config.n_population)
    fitness_matrix = -Inf * ones(mat_size...)
    elites_matrix = falses(mat_size...)
    eval_matrix = falses(mat_size...)
    n_eval = main_config["n_eval"]
    n_elite = main_config["n_elite"]
    eval_mutant = main_config["eval_mutant"]
    tournament_size = main_config["tournament_size"]
    DualCGPGAEvo(
        config, logid, resdir,
        encoder_config, encoder_sympop, encoder_logger,
        controller_config, controller_sympop, controller_logger,
        fitness, fitness_matrix, elites_matrix, eval_matrix, eval_mutant,
        n_eval, n_elite, tournament_size, 0
    )
end

#=
function log_gen_from_pop_logger(d_fitness, pop, logger, gen)
    for d in 1:d_fitness
        maxs = map(i->i.fitness[d], pop) # fitness would be a scalar in GA
        with_logger(logger) do
            @info Formatting.format("{1:04d},{2:e},{3:e},{4:e}",
                                    gen, maximum(maxs), mean(maxs), std(maxs))
        end
    end
    flush(logger.stream)
end

"""
    function log_gen(e::DualCGPEvolution)

Log a generation within a dual CGP evolution framework, including max, mean,
and std of each fitness dimension.
"""
function log_gen(e::DualCGPGAEvo)
    log_gen_from_pop_logger(e.config.d_fitness, e.encoder_population,
                            e.encoder_logger, e.gen)
    log_gen_from_pop_logger(e.config.d_fitness, e.controller_population,
                            e.controller_logger, e.gen)
end

function save_gen_at(path, pop)
    sort!(pop)
    for i in eachindex(pop)
        f = open(Formatting.format("{1}/{2:04d}.dna", path, i), "w+")
        write(f, string(pop[i]))
        close(f)
    end
end

"""
    function save_gen(e::DualCGPEvolution)

Save the population of a dual CGP evolution framework in `gens/` contained in
the results directory.
"""
function save_gen(e::DualCGPGAEvo)
    encoder_path = joinpath(e.resdir, Formatting.format("gens/{1}/encoder_{2:04d}", e.logid, e.gen))
    controller_path = joinpath(e.resdir, Formatting.format("gens/{1}/controller_{2:04d}", e.logid, e.gen))
    mkpath(encoder_path)
    mkpath(controller_path)
    save_gen_at(encoder_path, e.encoder_population)
    save_gen_at(controller_path, e.controller_population)
end
=#

mutable struct DualCGPEvolution{T} <: Cambrian.AbstractEvolution
    config::NamedTuple
    logid::String
    resdir::String
    encoder_config::NamedTuple
    encoder_population::Array{T}
    encoder_logger::CambrianLogger
    controller_config::NamedTuple
    controller_population::Array{T}
    controller_logger::CambrianLogger
    fitness::Function
    gen::Int
end

populate(e::IICGP.DualCGPEvolution) = IICGP.oneplus_populate(e)
evaluate(e::IICGP.DualCGPEvolution) = IICGP.fitness_evaluate(e, e.fitness)

"""
    function DualCGPEvolution(
        encoder_config::NamedTuple,
        controller_config::NamedTuple,
        fitness::Function
        resdir::String;;
        bootstrap::Bool=false,
        kwargs...
    )

Dual CGP evolution framework.
"""
function DualCGPEvolution(
    encoder_config::NamedTuple,
    controller_config::NamedTuple,
    fitness::Function,
    resdir::String;
    bootstrap::Bool=false,
    kwargs...
)
    kwargs_dict = Dict(kwargs)

    # Logger
    if haskey(kwargs_dict, :logid)
        logid = kwargs_dict[:logid]
    else
        logid = encoder_config.id
    end
    encoder_logfile = joinpath(resdir, "logs", logid, "encoder.csv")
    controller_logfile = joinpath(resdir, "logs", logid, "controller.csv")
    encoder_logger = CambrianLogger(encoder_logfile)
    controller_logger = CambrianLogger(controller_logfile)

    # CGP populations
    if haskey(kwargs_dict, :encoder_init_function)
        encoder_population = Cambrian.initialize(CGPInd, encoder_config,
            init_function=kwargs_dict[:encoder_init_function])
    else
        encoder_population = Cambrian.initialize(CGPInd, encoder_config)
    end
    if haskey(kwargs_dict, :controller_init_function)
        controller_population = Cambrian.initialize(CGPInd, controller_config,
            init_function=kwargs_dict[:controller_init_function])
    else
        controller_population = Cambrian.initialize(CGPInd, controller_config)
    end

    # Global evolution config
    @assert encoder_config.d_fitness == controller_config.d_fitness
    config = (
        d_fitness=encoder_config.d_fitness,
        seed=encoder_config.seed,
        n_gen=max(encoder_config.n_gen, controller_config.n_gen),
        log_gen=min(encoder_config.log_gen, controller_config.log_gen),
        save_gen=min(encoder_config.save_gen, controller_config.save_gen)
    )

    # Create and return DualCGPEvolution
    DualCGPEvolution(
        config, logid, resdir,
        encoder_config, encoder_population, encoder_logger,
        controller_config, controller_population, controller_logger,
        fitness, 0
    )
end

DualEvo = Union{DualCGPEvolution, DualCGPGAEvo}

function getpop(e::DualEvo; copypop::Bool=false)
    if typeof(e) <: DualCGPGAEvo
        if copypop
            epop = [SymIndCopy(ind) for ind in e.encoder_sympop]
            cpop = [SymIndCopy(ind) for ind in e.controller_sympop]
        else
            epop = e.encoder_sympop
            cpop = e.controller_sympop
        end
    elseif typeof(e) <: DualCGPEvolution
        epop = e.encoder_population
        cpop = e.controller_population
    else
        throw(TypeError("Type $(typeof(e)) not supported in loggen."))
    end
    return epop, cpop
end

function log_gen_from_pop_logger(
    d_fitness::Int64,
    pop::AbstractArray,
    logger::CambrianLogger,
    gen::Int64
)
    for d in 1:d_fitness
        maxs = map(i->i.fitness[d], pop)
        with_logger(logger) do
            @info Formatting.format("{1:04d},{2:e},{3:e},{4:e}",
                                    gen, maximum(maxs), mean(maxs), std(maxs))
        end
    end
    flush(logger.stream)
end

"""
    function log_gen(e::DualCGPEvolution)

Log a generation within a dual CGP evolution framework, including max, mean,
and std of each fitness dimension.
"""
function log_gen(e::DualEvo)
    epop, cpop = getpop(e)
    log_gen_from_pop_logger(e.config.d_fitness, epop, e.encoder_logger, e.gen)
    log_gen_from_pop_logger(e.config.d_fitness, cpop, e.controller_logger, e.gen)
end

function save_gen_at(path::String, pop::AbstractArray)
    sort!(pop)
    for i in eachindex(pop)
        f = open(Formatting.format("{1}/{2:04d}.dna", path, i), "w+")
        write(f, string(pop[i]))
        close(f)
    end
end

"""
    function save_gen(e::DualEvo)

Save the population of a dual CGP evolution framework in `gens/` contained in
the results directory.
"""
function save_gen(e::DualEvo)
    encoder_path = joinpath(e.resdir, Formatting.format("gens/{1}/encoder_{2:04d}", e.logid, e.gen))
    controller_path = joinpath(e.resdir, Formatting.format("gens/{1}/controller_{2:04d}", e.logid, e.gen))
    mkpath(encoder_path)
    mkpath(controller_path)
    epop, cpop = getpop(e; copypop=true)
    save_gen_at(encoder_path, epop)
    save_gen_at(controller_path, cpop)
end
