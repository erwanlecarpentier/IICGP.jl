export fitness_evaluate

"""
    function null_evaluate(i::CGPInd, j::CGPInd)

Default evaluation function for two CGP individuals.
"""
function null_evaluate(i::CGPInd, j::CGPInd)
    return -Inf
end

"""
    function fitness_evaluate(e::DualCGPEvolution, fitness::Function=null_evaluate)

Sets the fitness of each individual to the maximum value of the fitness matrix
in the dual CGP evolution framework.
"""
function fitness_evaluate(e::DualCGPEvolution, fitness::Function=null_evaluate)
    println(length(e.encoder_population))
    #=
    for i in eachindex(e.population)
        e.population[i].fitness[:] = fitness(e.population[i])[:]
    end
    =#
end
