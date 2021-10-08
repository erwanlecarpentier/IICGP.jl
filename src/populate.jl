export oneplus_populate, ga_populate

"""
    function oneplus_populate(e::DualCGPEvolution)

Implements a 1+λ evolution scheme for both population of a Dual CGP Coevolution.
"""
function oneplus_populate(e::DualCGPEvolution)
    enc = Cambrian.max_selection(e.encoder_population)
    ctr = Cambrian.max_selection(e.controller_population)
    e.encoder_population[1] = enc
    e.controller_population[1] = ctr
    for i in 2:length(e.encoder_population)
        e.encoder_population[i] = mutate(enc, "encoder")
    end
    for i in 2:length(e.controller_population)
        e.controller_population[i] = mutate(ctr, "controller")
    end
end

function tournament_selection(e::DualCGPGAEvo)
    e.tournament_size
end

function ga_populate(e::DualCGPGAEvo)
    enew = Vector{SymInd}()
    cnew = Vector{SymInd}()
    n_e = e.encoder_config.n_population
    n_c = e.controller_config.n_population
    # 1. Add elites
    println("TODO tournament populate elites")
    # 2. Run tournaments until population is full
    while length(enew) < n_e && length(enew) < n_c
        tournament_selection(e)
    end
end
