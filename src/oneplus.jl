export oneplus_populate

"""
    function oneplus_populate(e::DualCGPEvolution)

Implements a 1+λ evolution scheme for both population of a Dual CGP Coevolution.
"""
function oneplus_populate(e::DualCGPEvolution)
    enc = Cambrian.max_selection(e.encoder_population)
    ctr = Cambrian.max_selection(e.controller_population)

    # TODO remove START
    println()
    println("#"^100)
    println("oneplus_populate")
    println("best enco:")
    println(enc.chromosome)
    println("best cont:")
    println(ctr.chromosome)
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
