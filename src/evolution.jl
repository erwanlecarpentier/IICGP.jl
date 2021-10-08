export DualCGPEvolution, DualCGPGAEvo

import Cambrian.populate, Cambrian.evaluate, Cambrian.log_gen, Cambrian.save_gen
using Statistics

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
    n_eval::Int64
    n_elite::Int64
    tournament_size::Int64
    gen::Int64
end

populate(e::IICGP.DualCGPGAEvo) = IICGP.tournament_populate(e)
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
    n_eval = main_config["n_eval"]
    n_elite = main_config["n_elite"]
    tournament_size = main_config["tournament_size"]
    DualCGPGAEvo(
        config, logid, resdir,
        encoder_config, encoder_sympop, encoder_logger,
        controller_config, controller_sympop, controller_logger,
        fitness, fitness_matrix, elites_matrix, n_eval, n_elite,
        tournament_size, 0
    )
end

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

function log_gen_from_pop_logger(d_fitness, pop, logger, gen)
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
function log_gen(e::DualCGPEvolution)
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
function save_gen(e::DualCGPEvolution)
    encoder_path = joinpath(e.resdir, Formatting.format("gens/{1}/encoder_{2:04d}", e.logid, e.gen))
    controller_path = joinpath(e.resdir, Formatting.format("gens/{1}/controller_{2:04d}", e.logid, e.gen))
    mkpath(encoder_path)
    mkpath(controller_path)
    save_gen_at(encoder_path, e.encoder_population)
    save_gen_at(controller_path, e.controller_population)
end
