export oneplus_populate

"""
    function oneplus_populate(e::DualCGPEvolution)

Simple 1+λ evolution scheme for both population of a Dual CGP Coevolution
scheme.
"""
function oneplus_populate(e::DualCGPEvolution)
    enc = Cambrian.max_selection(e.encoder_population)
    ctr = Cambrian.max_selection(e.controller_population)
    e.encoder_population[1] = enc
    e.controller_population[1] = ctr
    for i in 2:length(e.encoder_population)
        e.encoder_population[i] = mutate(enc)
    end
    for i in 2:length(e.controller_population)
        e.controller_population[i] = mutate(ctr)
    end
end
