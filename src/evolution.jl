export IPCGPEvolution

import Cambrian.populate, Cambrian.evaluate

mutable struct IPCGPEvolution{T} <: Cambrian.AbstractEvolution
    config::NamedTuple
    logger::CambrianLogger
    population::Array{T}
    fitness::Function
    gen::Int
end

populate(e::IPCGPEvolution) = Cambrian.oneplus_populate(e)
evaluate(e::IPCGPEvolution) = Cambrian.fitness_evaluate(e, e.fitness)

function IPCGPEvolution(cfg::NamedTuple, fitness::Function;
                        logfile=string("logs/", cfg.id, ".csv"))
    logger = CambrianLogger(logfile)
    population = Cambrian.initialize(IPCGPInd, cfg)
    IPCGPEvolution(cfg, logger, population, fitness, 0)
end
