export fitness_evaluate, select_indexes

using Random

"""
    null_evaluate(i::CGPInd, j::CGPInd)

Default evaluation function for two CGP individuals setting minimum fitness.
"""
function null_evaluate(i::CGPInd, j::CGPInd)
    return -Inf
end

"""
	fitness_evaluate(e::NSGA2Evo, fitness::Function)

Evaluation function for the NSGA-II algorithm.
"""
function fitness_evaluate(e::NSGA2Evo{T}, fitness::Function) where T
	@sync @inbounds for i in eachindex(e.population)
		Threads.@spawn begin
			e.population[i].fitness .= fitness(e.population[i], e.gen, e.atari_games[i])
		end
    end
end

function fitness_evaluate_two_atari_runs(e::NSGA2Evo{T}, fitness::Function) where T
	n = length(e.population)
	o1, f1 = zeros(n), zeros(Int64, n)
	o2, f2 = zeros(n), zeros(Int64, n)
	@sync @inbounds for i in eachindex(e.population)
		Threads.@spawn begin
			o1[i], f1[i] = fitness(e.population[i], e.gen, e.atari_games[i][1])
		end
		Threads.@spawn begin
			o2[i], f2[i] = fitness(e.population[i], 25000+e.gen, e.atari_games[i][2])
		end
    end
	@inbounds for i in eachindex(e.population)
		e.population[i].fitness .= [o1[i], o2[i]]
		e.population[i].reached_frames = f1[i] + f2[i]
	end
end

"""
    fitness_evaluate(e::CGPEvolution; fitness::Function=null_evaluate)

Sets the fitness of each individual to the Array of values returned by fitness.
Multithreaded option enabled in this version.
"""
function fitness_evaluate(e::CGPEvolution, fitness::Function)
    @sync for i in eachindex(e.population)
        Threads.@spawn begin
            e.population[i].fitness .= fitness(e.population[i])
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
	# 1. Select elites and maybe other pairs set in eval_matrix (e.g. mutant)
	for i in 1:nrows
		for j in 1:ncols
			if e.eval_matrix[i, j]
				push!(indexes, (i, j))
			end
		end
	end
	# 2. Select at least one pair per row/col
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
	for c in candidates # Only push candidate if the row or col is not evaluated
		if c[1] ∉ eliterows || c[2] ∉ elitecols
			push!(indexes, c)
		end
	end
	# 3. Select additional random evaluations
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
	e.fitness_matrix[i, j] = fitness(enco_i, cont_j, e.gen)[1]
end

function set_ind_fitnesses!(e::DualCGPGAEvo)
	for i in eachindex(e.encoder_sympop)
        e.encoder_sympop[i].fitness[1] = maximum(e.fitness_matrix[i,:])
    end
    for j in eachindex(e.controller_sympop)
        e.controller_sympop[j].fitness[1] = maximum(e.fitness_matrix[:,j])
    end
end

function set_elites!(e::DualCGPGAEvo)
	e.elites_matrix = falses(size(e.elites_matrix)...) # zero elites matrix
	ci = CartesianIndices(size(e.fitness_matrix))
    # p = sortperm(vec(e.fitness_matrix))[end-e.n_elite+1:end]
	p = partialsortperm(vec(e.fitness_matrix), 1:e.n_elite; rev=true)
    elite_indexes = ci[p]
	for i in elite_indexes
		e.elites_matrix[i] = true
	end
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
	# 3. Set individual's fitnesses
	set_ind_fitnesses!(e)
	# 4. Set elites
	set_elites!(e)
end
