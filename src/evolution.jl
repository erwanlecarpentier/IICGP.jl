export DualCGPEvolution

import Cambrian.populate, Cambrian.evaluate, Cambrian.log_gen, Cambrian.save_gen
using Statistics

mutable struct DualCGPEvolution{T} <: Cambrian.AbstractEvolution
    config::NamedTuple
    logid::String
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
TODO doc
"""
function get_bootstrap_chromosomes(
    enco_cfg::NamedTuple,
    cont_cfg::NamedTuple,
    game::String
)
    enco_bs_path, cont_bs_path = get_bootstrap_paths(enco_cfg, cont_cfg, game)
    println(string("-> enco_bs_path = ", enco_bs_path))
    println(string("-> cont_bs_path = ", cont_bs_path))
    println()
end

"""
TODO doc
"""
function bootstrap_init(
    enco_cfg::NamedTuple,
    cont_cfg::NamedTuple,
    kwargs_dict::Dict
)
    enco_pop = Array{CGPInd}(undef, enco_cfg.n_population)
    cont_pop = Array{CGPInd}(undef, cont_cfg.n_population)
    if haskey(kwargs_dict, :game)
        game = kwargs_dict[:game]
    else
        throw(ArgumentError("No game specified in kwargs"))
    end
    chromosome = get_bootstrap_chromosomes(enco_cfg, cont_cfg, game)
    return enco_pop, cont_pop  # TODO (bootstrap_init) remove
    # TODO (bootstrap_init) put back and reimplemente
    #=
    if haskey(kwargs_dict, :init_function)
        population[1] = kwargs_dict[:init_function](cfg, chromosome)
    else
        population[1] = itype(cfg, chromosome)
    end
    for i in 2:cfg.n_population
        population[i] = mutate(population[1], ind_type)
    end
    population
    =#
end

"""
    function DualCGPEvolution(
        encoder_config::NamedTuple,
        controller_config::NamedTuple,
        fitness::Function;
        bootstrap::Bool=false,
        kwargs...
    )

Dual CGP evolution framework.
"""
function DualCGPEvolution(
    encoder_config::NamedTuple,
    controller_config::NamedTuple,
    fitness::Function;
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
    encoder_logfile = string("logs/", logid, "/encoder.csv")
    controller_logfile = string("logs/", logid, "/controller.csv")
    encoder_logger = CambrianLogger(encoder_logfile)
    controller_logger = CambrianLogger(controller_logfile)

    # CGP populations
    if bootstrap
        encoder_population, controller_population = bootstrap_init(
            encoder_config, controller_config, kwargs_dict
        )
    else
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
        config, logid,
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

Save the population of a dual CGP evolution framework in `gens/`.
"""
function save_gen(e::DualCGPEvolution)
    encoder_path = Formatting.format("gens/{1}/encoder_{2:04d}", e.logid, e.gen)
    controller_path = Formatting.format("gens/{1}/controller_{2:04d}", e.logid, e.gen)
    mkpath(encoder_path)
    mkpath(controller_path)
    save_gen_at(encoder_path, e.encoder_population)
    save_gen_at(controller_path, e.controller_population)
end
