export oneplus_populate

# TODO remove START
global FIT_ENC = []
global CHR_ENC = []
global IID_ENC = []
global FIT_CTR = []
global CHR_CTR = []
global IID_CTR = []
# TODO remove END

"""
    function oneplus_populate(e::DualCGPEvolution)

Implements a 1+λ evolution scheme for both population of a Dual CGP Coevolution.
"""
function oneplus_populate(e::DualCGPEvolution)

    # TODO remove START
    println()
    println("#"^100)
    println("Enc fitnesses BEFORE max_selection:")
    for ind in e.encoder_population
        println(ind.fitness)
    end
    println()
    println("Ctr fitnesses BEFORE max_selection:")
    for ind in e.controller_population
        println(ind.fitness)
    end
    println()
    # TODO remove END

    enc = Cambrian.max_selection(e.encoder_population)
    ctr = Cambrian.max_selection(e.controller_population)

    # TODO remove START
    println()
    println("#"^100)
    println("Enc fitnesses:")
    for ind in e.encoder_population
        println(ind.fitness)
    end
    println()
    println("Ctr fitnesses:")
    for ind in e.controller_population
        println(ind.fitness)
    end
    println()
    # TODO remove END

    # TODO remove START
    println()
    println("#"^100)
    println("oneplus_populate")
    println("best enco: ", enc.fitness)
    println(enc.chromosome)
    println("best cont: ", ctr.fitness)
    println(ctr.chromosome)
    println("#"^100)
    println()
    # TODO remove END

    # TODO remove START
    global FIT_ENC
    global CHR_ENC
    global IID_ENC
    push!(FIT_ENC, enc.fitness[1])
    if length(CHR_ENC) < 1
        id_enc = 1
    else
        found = false
        for i in eachindex(CHR_ENC)
            if enc.chromosome == CHR_ENC[i]
                id_enc = IID_ENC[i]
                found = true
            end
        end
        if !found
            id_enc = maximum(IID_ENC) + 1
        end
    end
    push!(CHR_ENC, enc.chromosome)
    push!(IID_ENC, id_enc)

    global FIT_CTR
    global CHR_CTR
    global IID_CTR
    push!(FIT_CTR, ctr.fitness[1])
    if length(CHR_CTR) < 1
        id_ctr = 1
    else
        found = false
        for i in eachindex(CHR_CTR)
            if ctr.chromosome == CHR_CTR[i]
                id_ctr = IID_CTR[i]
                found = true
            end
        end
        if !found
            id_ctr = maximum(IID_CTR) + 1
        end
    end
    push!(CHR_CTR, ctr.chromosome)
    push!(IID_CTR, id_ctr)


    println("FIT_ENC:\n", FIT_ENC)
    println("IID_ENC:\n", IID_ENC)

    println("FIT_CTR:\n", FIT_CTR)
    println("IID_CTR:\n", IID_CTR)

    println("#"^100)
    println()
    # TODO remove END

    e.encoder_population[1] = enc
    e.controller_population[1] = ctr
    for i in 2:length(e.encoder_population)
        e.encoder_population[i] = mutate(enc, "encoder")
    end
    for i in 2:length(e.controller_population)
        e.controller_population[i] = mutate(ctr, "controller")
    end
end
