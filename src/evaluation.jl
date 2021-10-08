export fitness_evaluate

using Random

"""
    null_evaluate(i::CGPInd, j::CGPInd)

Default evaluation function for two CGP individuals.
"""
function null_evaluate(i::CGPInd, j::CGPInd)
    return -Inf
end

"""
    fitness_evaluate(e::CGPEvolution; fitness::Function=null_evaluate)

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
    fitness_evaluate(e::DualCGPEvolution, fitness::Function=null_evaluate)

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

"""
	select_indexes(e::DualCGPGAEvo)

Select the indexes of the pairs to be evaluated for this generation.
	- 1. Select the elite pairs
	- 2. Select at least one pair per row/col
	- 3. Select random pairs until e.n_eval pairs have been selected
"""
function select_indexes(e::DualCGPGAEvo)
	indexes = Vector{Tuple{Int64, Int64}}()
	nrows = size(e.elites_matrix, 1)
	ncols = size(e.elites_matrix, 2)
	nmax = max(nrows, ncols)
	# 1. Evaluate elites
	for i in 1:nrows
		for j in 1:ncols
			if e.elites_matrix[i, j]
				push!(indexes, (i, j))
			end
		end
	end
	# 2. Evaluate at least one pair per row/col
	shuffledrows = shuffle(collect(1:nrows))
	shuffledcols = shuffle(collect(1:ncols))
	candidates = Vector{Tuple{Int64, Int64}}()
	for i in 1:nmax
		i_modrow = i-nrows*divrem(i-1,nrows)[1]
		i_modcol = i-ncols*divrem(i-1,ncols)[1]
		c = (shuffledrows[i_modrow], shuffledcols[i_modcol])
		push!(candidates, c)
	end
	eliterows = [i[1] for i in indexes]
	elitecols = [i[2] for i in indexes]
	for c in candidates
		if c[1] ∉ eliterows && c[2] ∉ elitecols
			push!(indexes, c)
		end
	end
	# 3. Additional random evaluations
	while length(indexes) < e.n_eval
		c = (rand(1:nrows), rand(1:ncols))
		if c ∉ indexes
			push!(indexes, c)
		end
	end
	indexes
end

function fitness_evaluate_ij!(
	e::DualCGPGAEvo,
	i::Int64,
	j::Int64,
	fitness::Function
)
	enco_i = IPCGPInd(e.encoder_config, e.encoder_sympop[i].chromosome)
	cont_j = CGPInd(e.controller_config, e.controller_sympop[j].chromosome)
	e.fitness_matrix[i, j] = fitness(enco_i, cont_j)[1]
end

function set_elites!(e::DualCGPGAEvo)
	println("TODO set_elites!")
end

"""
	fitness_evaluate(e::DualCGPGAEvo, fitness::Function=null_evaluate)

GA sparse fitness evaluation method.
"""
function fitness_evaluate(e::DualCGPGAEvo, fitness::Function=null_evaluate)
	# 1. Select indexes of individuals to evaluate
	indexes = select_indexes(e)
	# 2. Evaluate those individuals
	Threads.@threads for l in eachindex(indexes)
        i, j = indexes[l]
		fitness_evaluate_ij!(e, i, j, fitness)
    end
	# 3. Set elites
	set_elites!(e)
end
