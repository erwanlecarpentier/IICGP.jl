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

function tournament_selection(e::DualCGPGAEvo, ci::CartesianIndices)
    n_pairs = length(e.fitness_matrix)
    selected = randperm(n_pairs)[1:e.tournament_size]
    fitnesses = e.fitness_matrix[selected]
    best_pair_index = sortperm(fitnesses)[-1]
    best_pair_carte = ci[best_pair_index]
    # echr = e.encoder_sympop[best_pair_carte[1]].chromosome
    # cchr = e.controller_sympop[best_pair_carte[2]].chromosome
    enc = e.encoder_sympop[best_pair_carte[1]]
    ctr = e.controller_sympop[best_pair_carte[2]]
    return enc, ctr
    # return mutate(enc, "encoder"), mutate(ctr, "controller")
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
    ci = CartesianIndices(size(e.fitness_matrix))
    while length(enew) < n_e && length(cnew) < n_c
        enc, ctr = tournament_selection(e, ci)
        if length(enew) < n_e
            push!(enew, mutate(enc, "encoder"))
        end
        if length(cnew) < n_c
            push!(cnew, mutate(ctr, "controller"))
        end
    end
    # 3. Set population and matrices
    # TODO here before deciding to keep ind pop
    println("TODO reset fitness matrix to -Inf")
    println("TODO reset elite matrice to 0 everywhere except for previous elites")
    e.encoder_sympop = enew
    e.controller_sympop = cnew
end
