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
    println("\n----------------------------------------------------------------") # TODO remove
    println("Enterring evaluation") # TODO remove
    println("----------------------------------------------------------------\n") # TODO remove
    t1 = time_ns()  # TODO remove
    n_encoders = e.encoder_config.n_population
    n_controllers = e.controller_config.n_population
    fitness_matrix = Array{Float64}(undef, n_encoders, n_controllers)
    @sync for i in 1:n_encoders
        for j in 1:n_controllers
            encoder_i = IPCGPInd(e.encoder_config, e.encoder_population[i].chromosome)
            controller_j = CGPInd(e.controller_config, e.controller_population[j].chromosome)
            Threads.@spawn begin
                fitness_matrix[i, j] = fitness(
                    encoder_i,
                    controller_j
                )[1] # Currently, only pick 1st fitness dimension
            end
        end
    end
    t2 = time_ns()  # TODO remove
    elapsed = (t2-t1)/1.0e9  # TODO remove
    println("\n----------------------------------------------------------------") # TODO remove
    println("Elapsed time in full fitness_matrix evaluation: $elapsed (s)") # TODO remove
    println("----------------------------------------------------------------\n") # TODO remove
    # Retrieve maximum values for fitness (lenient evolution)
    encoders_fitnesses = maximum(fitness_matrix, dims=2)
    controllers_fitnesses = maximum(fitness_matrix, dims=1)
    for i in 1:n_encoders
        e.encoder_population[i].fitness[1] = encoders_fitnesses[i]
    end
    for j in 1:n_controllers
        e.controller_population[j].fitness[1] = controllers_fitnesses[j]
    end
    println("\n----------------------------------------------------------------") # TODO remove
    println("Exiting evaluation") # TODO remove
    println("----------------------------------------------------------------\n") # TODO remove
end
