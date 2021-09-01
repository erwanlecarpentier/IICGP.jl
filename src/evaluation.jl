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
function fitness_evaluate(e::CGPEvolution, fitness::Function)
    @sync for i in eachindex(e.population)
        Threads.@spawn begin
            e.population[i].fitness[:] = fitness(e.population[i])[:]
        end
    end
end

function fitness_evaluate_ij(
	e::DualCGPEvolution,
	f::Array{Float64, 2},
	i::Int64,
	j::Int64,
	fitness::Function=null_evaluate
)
	enco_i = IPCGPInd(e.encoder_config, e.encoder_population[i].chromosome)
	cont_j = CGPInd(e.controller_config, e.controller_population[j].chromosome)
	f[i,j] = fitness(enco_i, cont_j)[1] # Currently, only pick 1st fitness dimension
end
"""
    function fitness_evaluate(e::DualCGPEvolution, fitness::Function=null_evaluate)

Sets the fitness of each individual to the maximum value of the fitness matrix
in the dual CGP evolution framework.

TODOs:
- handle multi dimensional fitness in coevolution
"""
function fitness_evaluate(e::DualCGPEvolution, fitness::Function=null_evaluate)
    n_enco = e.encoder_config.n_population
    n_cont = e.controller_config.n_population
    fitness_matrix = zeros(n_enco, n_cont)

	# FORMER method with @sync
    #=
	@sync for i in 1:n_enco
        for j in 1:n_cont
            encoder_i = IPCGPInd(e.encoder_config, e.encoder_population[i].chromosome)
            controller_j = CGPInd(e.controller_config, e.controller_population[j].chromosome)
            Threads.@spawn begin
                fitness_matrix[i, j] = fitness(encoder_i, controller_j)[1] # Currently, only pick 1st fitness dimension
            end
        end
    end
	=#

	# NEW method with Threads.@threads
	indexes = [(i, j) for i in 1:n_enco for j in 1:n_cont]
    Threads.@threads for l in 1:(n_enco*n_cont)
        i, j = indexes[l]
		fitness_evaluate_ij(e, fitness_matrix, i, j, fitness)
    end

    for i in eachindex(e.encoder_population)
        e.encoder_population[i].fitness[1] = maximum(fitness_matrix[i,:])
    end
    for j in eachindex(e.controller_population)
        e.controller_population[j].fitness[1] = maximum(fitness_matrix[:,j])
    end
end
