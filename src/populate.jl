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

function isin(v::Vector{SymInd}, candidate::SymInd)
    for vi in v
        if candidate.chromosome == vi.chromosome
            return true
        end
    end
    false
end

function ga_populate(e::DualCGPGAEvo)
    enew = Vector{SymInd}()
    cnew = Vector{SymInd}()
    n_e = e.encoder_config.n_population
    n_c = e.controller_config.n_population
    # 1. Add elites
    ci = CartesianIndices(e.elites_matrix)
    for i in CartesianIndices(e.elites_matrix)
        if e.elites_matrix[i]
            ecandidate = e.encoder_sympop[i[1]]
            ccandidate = e.controller_sympop[i[2]]
            if !isin(enew, ecandidate)
                push!(enew, ecandidate)
            end
            if !isin(cnew, ccandidate)
                push!(cnew, ccandidate)
            end
        end
    end
    # 2. Run tournaments until population is full
    #=
    while length(enew) < n_e && length(enew) < n_c
        tournament_selection(e)
    end
    =#
    # 3. Set population and matrices
    println("TODO reset fitness to -Inf")
    println("TODO reset elite matrice to 0 everywhere except for previous elites")
    e.encoder_sympop = enew
    e.controller_sympop = cnew
end
