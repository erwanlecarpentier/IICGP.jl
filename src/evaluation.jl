export fitness_evaluate

"""
    function null_evaluate(i::CGPInd, j::CGPInd)

Default evaluation function for two CGP individuals.
"""
function null_evaluate(i::CGPInd, j::CGPInd)
    return -Inf
end

"""
    function fitness_evaluate(e::CGPEvolution; fitness::Function=null_evaluate)

Sets the fitness of each individual to the Array of values returned by fitness.
Multithreaded option enabled in this version.
"""
function fitness_evaluate(e::CGPEvolution, fitness::Function=null_evaluate)
    @sync for i in eachindex(e.population)
        Threads.@spawn begin
            e.population[i].fitness[:] = fitness(e.population[i])[:]
        end
    end
end

"""
    function fitness_evaluate(e::DualCGPEvolution, fitness::Function=null_evaluate)

Sets the fitness of each individual to the maximum value of the fitness matrix
in the dual CGP evolution framework.

TODOs:
- handle multi dimensional fitness in coevolution
"""
function fitness_evaluate(e::DualCGPEvolution, fitness::Function=null_evaluate)
    n_encoders = e.encoder_config.n_population
    n_controllers = e.controller_config.n_population
    fitness_matrix = Array{Float64}(undef, n_encoders, n_controllers)
    @sync for i in 1:n_encoders
        for j in 1:n_controllers
            # encoder_i = IPCGPInd(e.encoder_config, e.encoder_population[i].chromosome)
            # controller_j = CGPInd(e.controller_config, e.controller_population[j].chromosome)
            Threads.@spawn begin
                fitness_matrix[i, j] = fitness(
                    e.encoder_population[i],#encoder_i, # TODO put back
                    e.controller_population[j]#controller_j # TODO put back
                )[1] # Currently, only pick 1st fitness dimension
            end
        end
    end
    # Retrieve maximum values for fitness (lenient evolution)
    encoders_fitnesses = maximum(fitness_matrix, dims=2)
    controllers_fitnesses = maximum(fitness_matrix, dims=1)

    # TODO remove START
    println()
    println("-"^100)
    println("fitness_evaluate")
    println(fitness_matrix)
    println(encoders_fitnesses)
    println(controllers_fitnesses)
    println("best enco: ", argmax(encoders_fitnesses))
    #println(e.encoder_population[argmax(encoders_fitnesses)].chromosome)
    println("best cont: ", argmax(controllers_fitnesses))
    #println(e.controller_population[argmax(controllers_fitnesses)].chromosome)
    # TODO remove END

    for i in 1:n_encoders
        e.encoder_population[i].fitness[1] = encoders_fitnesses[i]
        println(i, " ", e.encoder_population[i].fitness)  # TODO remove
    end
    for j in 1:n_controllers
        e.controller_population[j].fitness[1] = controllers_fitnesses[j]
        println(j, " ", e.controller_population[j].fitness)  # TODO remove
    end

    # TODO remove START
    println("-"^100)
    println()
    # TODO remove END
end
