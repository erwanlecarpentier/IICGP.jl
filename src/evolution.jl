export DualCGPEvolution

import Cambrian.populate, Cambrian.evaluate, Cambrian.log_gen, Cambrian.save_gen

mutable struct DualCGPEvolution{T} <: Cambrian.AbstractEvolution
    config::NamedTuple
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
        fitness::Function;
        encoder_logfile=string("logs/encoder_", encoder_config.id, ".csv"),
        controller_logfile=string("logs/controller_", controller_config.id, ".csv"),
        kwargs...
    )

Dual CGP evolution framework.
"""
function DualCGPEvolution(
    encoder_config::NamedTuple,
    controller_config::NamedTuple,
    fitness::Function;
    encoder_logfile=string("logs/encoder_", encoder_config.id, ".csv"),
    controller_logfile=string("logs/controller_", controller_config.id, ".csv"),
    kwargs...
)
    encoder_logger = CambrianLogger(encoder_logfile)
    controller_logger = CambrianLogger(controller_logfile)
    kwargs_dict = Dict(kwargs)
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
    # TODO have a single config file?
    config = (
        seed=encoder_config.seed,
        n_gen=max(encoder_config.n_gen, controller_config.n_gen),
        log_gen=min(encoder_config.log_gen, controller_config.log_gen),
        save_gen=min(encoder_config.save_gen, controller_config.save_gen)
    )
    DualCGPEvolution(
        config,
        encoder_config, encoder_population, encoder_logger,
        controller_config, controller_population, controller_logger,
        fitness, 0
    )
end

"""
    function log_gen(e::DualCGPEvolution)

Log a generation within a dual CGP evolution framework, including max, mean,
and std of each fitness dimension.
"""
function log_gen(e::DualCGPEvolution)
    println("TODO log_gen(e::DualCGPEvolution)")
    #=
    for d in 1:e.config.d_fitness
        maxs = map(i->i.fitness[d], e.population)
        with_logger(e.logger) do
            @info Formatting.format("{1:04d},{2:e},{3:e},{4:e}",
                                    e.gen, maximum(maxs), mean(maxs), std(maxs))
        end
    end
    flush(e.logger.stream)
    =#
end

"""
    function save_gen(e::DualCGPEvolution)

Save the population of a dual CGP evolution framework in `gens/`.
"""
function save_gen(e::DualCGPEvolution)
    println("TODO function save_gen(e::DualCGPEvolution)")
    #=
    path = Formatting.format("gens/{1}/{2:04d}", e.config.id, e.gen)
    mkpath(path)
    sort!(e.population)
    for i in eachindex(e.population)
        f = open(Formatting.format("{1}/{2:04d}.dna", path, i), "w+")
        write(f, string(e.population[i]))
        close(f)
    end
    =#
end
