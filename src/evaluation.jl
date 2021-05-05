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

TODOs:
- handle multi dimensional fitness in coevolution
"""
function fitness_evaluate(e::DualCGPEvolution, fitness::Function=null_evaluate)
    n_encoders = length(e.encoder_population)
    n_controllers = length(e.controller_population)
    fitness_matrix = Array{Float64}(undef, n_encoders, n_controllers)
    for i in 1:n_encoders
        for j in 1:n_controllers
            fitness_matrix[i, j] = fitness(
                e.encoder_population[i],
                e.controller_population[j]
            )
        end
    end
    # Retrieve maximum values for fitness
    encoders_fitnesses = maximum(fitness_matrix, dims=2)
    controllers_fitnesses = maximum(fitness_matrix, dims=1)
    for i in 1:n_encoders
        e.encoder_population[i].fitness[1] = encoders_fitnesses[i]
        # fitness(e.population[i])[:]
    end
    for j in 1:n_controllers
        e.controller_population[j].fitness[1] = controllers_fitnesses[j]
    end
end
