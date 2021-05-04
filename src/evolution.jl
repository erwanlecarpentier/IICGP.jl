export DualCGPEvolution

# import Cambrian.populate, Cambrian.evaluate

mutable struct DualCGPEvolution{T} <: Cambrian.AbstractEvolution
    encoder_config::NamedTuple
    encoder_population::Array{T}
    encoder_logger::CambrianLogger
    controller_config::NamedTuple
    controller_population::Array{T}
    controller_logger::CambrianLogger
    fitness::Function
    gen::Int
end

# populate(e::CGPEvolution) = Cambrian.oneplus_populate(e)
# evaluate(e::CGPEvolution) = Cambrian.fitness_evaluate(e, e.fitness)

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
    DualCGPEvolution(
        encoder_config, encoder_population, encoder_logger,
        controller_config, controller_population, controller_logger,
        fitness, 0
    )
end
