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
    #=
    for i in eachindex(e.population)
        e.population[i].fitness[:] = fitness(e.population[i])[:]
    end
    =#
end
