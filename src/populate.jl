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
    best_pair_index = sortperm(fitnesses)[end]
    best_pair_carte = ci[best_pair_index]
    echr = copy(e.encoder_sympop[best_pair_carte[1]].chromosome)
    cchr = copy(e.controller_sympop[best_pair_carte[2]].chromosome)
    return echr, cchr
end

function isin(v::Vector{SymInd}, candidate::SymInd)
    for vi in v
        if candidate.chromosome == vi.chromosome
            return true
        end
    end
    false
end

function find_symind_index(ind::SymInd, v::Vector{SymInd})
    for i in eachindex(v)
        if v[i].chromosome == ind.chromosome
            return i
        end
    end
end

function ga_populate(e::DualCGPGAEvo)
    enew = Vector{SymInd}()
    cnew = Vector{SymInd}()
    n_e = e.encoder_config.n_population
    n_c = e.controller_config.n_population
    # 1. Add elites
    new_elite_indexes = Vector{Tuple{Int64, Int64}}()
    for i in CartesianIndices(e.elites_matrix)
        if e.elites_matrix[i]
            ecandidate = SymIndCopy(e.encoder_sympop[i[1]])
            ccandidate = SymIndCopy(e.controller_sympop[i[2]])
            if !isin(enew, ecandidate)
                push!(enew, ecandidate)
            end
            if !isin(cnew, ccandidate)
                push!(cnew, ccandidate)
            end
            row = find_symind_index(ecandidate, enew)
            col = find_symind_index(ccandidate, cnew)
            push!(new_elite_indexes, (row, col))
        end
    end
    # 2. Run tournaments until population is full
    new_mutant_indexes = Vector{Tuple{Int64, Int64}}()
    ci = CartesianIndices(size(e.fitness_matrix))
    while length(enew) < n_e || length(cnew) < n_c
        echr, cchr = tournament_selection(e, ci)
        if length(enew) < n_e
            type = e.encoder_config.type
        	enco = IPCGPInd(e.encoder_config, echr)
            enco_m = mutate(enco, type)
            push!(enew, SymInd(enco_m.chromosome, 0, type))
        end
        if length(cnew) < n_c
            type = e.controller_config.type
        	cont = CGPInd(e.controller_config, cchr)
            cont_m = mutate(cont, type)
            push!(cnew, SymInd(cont_m.chromosome, 0, type))
        end
        row, col = length(enew), length(cnew)
        push!(new_mutant_indexes, (row, col))
    end
    # 3. Set new population and reset matrices
    e.encoder_sympop = enew
    e.controller_sympop = cnew
    mat_size = size(e.fitness_matrix)
    e.fitness_matrix = -Inf * ones(mat_size...)
    e.elites_matrix = falses(mat_size...)
    e.eval_matrix = falses(mat_size...)
    for index in new_elite_indexes
        e.elites_matrix[index...] = true
        e.eval_matrix[index...] = true
    end
    if e.eval_mutant
        for index in new_mutant_indexes # TODO test
            e.eval_matrix[index...] = true
        end
    end
end
