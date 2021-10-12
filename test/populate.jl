using IICGP
using Cambrian
using CartesianGeneticProgramming
using Test

import Cambrian.mutate # function extension


function find_chr_index(chr::Vector{Float64}, v::Vector{Vector{Float64}})
    for i in eachindex(v)
        if v[i] == chr
            return i
        end
    end
end

function get_elites(e::DualCGPGAEvo)
    elite_echr = Vector{Vector{Float64}}()
    elite_cchr = Vector{Vector{Float64}}()
    elite_pairs = Vector{Tuple{Int64, Int64}}()
    ci = CartesianIndices(e.elites_matrix)
    for i in eachindex(e.elites_matrix)
        if e.elites_matrix[i]
            row, col = ci[i][1], ci[i][2]
            echr = deepcopy(e.encoder_sympop[row].chromosome)
            cchr = deepcopy(e.controller_sympop[col].chromosome)
            if !(echr in elite_echr)
                push!(elite_echr, echr)
            end
            if !(cchr in elite_cchr)
                push!(elite_cchr, cchr)
            end
            eindex = find_chr_index(echr, elite_echr)
            cindex = find_chr_index(cchr, elite_cchr)
            push!(elite_pairs, (eindex, cindex))
        end
    end
    elite_echr, elite_cchr, elite_pairs
end

function test_indexes(
    e::DualCGPGAEvo,
    elite_echr::Vector{Vector{Float64}},
    elite_cchr::Vector{Vector{Float64}},
    elite_pairs::Vector{Tuple{Int64, Int64}}
)
    indexes = select_indexes(e)
    nrows, ncols = size(e.fitness_matrix)
    # Test: elites are selected for next evaluation
    for pair in elite_pairs
        i, j = pair[1], pair[2]
        echr = elite_echr[i]
        cchr = elite_cchr[j]
        r = find_chr_index(echr, [ind.chromosome for ind in e.encoder_sympop])
        c = find_chr_index(cchr, [ind.chromosome for ind in e.controller_sympop])
        @test (r, c) ∈ indexes
    end
    # Test: each row and each col are to be evaluated
    isrowselected, iscolselected = falses(nrows), falses(ncols)
    for i in indexes
        isrowselected[i[1]] = true
        iscolselected[i[2]] = true
    end
    @test sum(isrowselected) == nrows
    @test sum(iscolselected) == ncols
end

function test_newpop(
    e::DualCGPGAEvo,
    elite_echr::Vector{Vector{Float64}},
    elite_cchr::Vector{Vector{Float64}},
    elite_pairs::Vector{Tuple{Int64, Int64}}
)
    @test length(e.encoder_sympop) == e.encoder_config.n_population
    @test length(e.controller_sympop) == e.controller_config.n_population
    @test sum(e.elites_matrix) == e.n_elite
    # Test: elites are kept between generations (same chromosomes)
    for i in eachindex(elite_echr)
        @test elite_echr[i] == e.encoder_sympop[i].chromosome
    end
    for j in eachindex(elite_cchr)
        @test elite_cchr[j] == e.controller_sympop[j].chromosome
    end
    # Test: indexes (elites / rows / cols)
    test_indexes(e, elite_echr, elite_cchr, elite_pairs)
    # Test: fitness matrix is reset to -Inf
    matsize = size(e.fitness_matrix)
    @test e.fitness_matrix == -Inf * ones(matsize...)
end

function test_newpop_custom(
    e::DualCGPGAEvo,
    elite_echr::Vector{Vector{Float64}},
    elite_cchr::Vector{Vector{Float64}}
)
    @test sum(e.elites_matrix) == length(custom_elites_indexes)
    expected_elites_matrix = falses(5, 5)
    for index in [(1,1), (1,2), (2,3)]
        expected_elites_matrix[index...] = true
    end
    @test e.elites_matrix == expected_elites_matrix
    @test e.encoder_sympop[1].chromosome == elite_echr[1]
    @test e.encoder_sympop[2].chromosome == elite_echr[3]
    @test e.controller_sympop[1].chromosome == elite_cchr[1]
    @test e.controller_sympop[2].chromosome == elite_cchr[2]
    @test e.controller_sympop[3].chromosome == elite_cchr[3]
end

function test_tournaments_ind(
    e::DualCGPGAEvo,
    elite_echr::Vector{Vector{Float64}},
    elite_cchr::Vector{Vector{Float64}},
    prev_echr::Vector{Vector{Float64}},
    prev_cchr::Vector{Vector{Float64}},
    comptype::String
)
    for esym in e.encoder_sympop
        if comptype == "in"
            # current chromosome was in previous pop
            @test esym.chromosome in prev_echr
        elseif comptype == "notin"
            if esym.chromosome in elite_echr
                # current chromosome was in previous pop
                @test esym.chromosome in prev_echr
            else
                # current chromosome was NOT in previous pop
                @test esym.chromosome ∉ prev_echr
            end
        end
    end
    for csym in e.controller_sympop
        if comptype == "in"
            @test csym.chromosome in prev_cchr
        elseif comptype == "notin"
            if csym.chromosome in elite_cchr
                @test csym.chromosome in prev_cchr
            else
                @test csym.chromosome ∉ prev_cchr
            end
        end
    end
end

cfg_filename = string(@__DIR__, "/dualcgpga_test.yaml")
game = "gravitar"
mcfg, ecfg, ccfg, reducer, bootstrap = IICGP.dualcgp_config(cfg_filename, game)
logid = "2021-test-logid"
resdir = dirname(@__DIR__)
function mutate(ind::CGPInd, ind_type::String)
    if ind_type == "encoder"
        return goldman_mutate(ecfg, ind, init_function=IPCGPInd)
    elseif ind_type == "controller"
        return goldman_mutate(ccfg, ind)
    end
end
fit(e::CGPInd, c::CGPInd, seed::Int64) = [sum(e.chromosome) * sum(c.chromosome)]
n_iter = 1000
n_seed = 5

@testset "CGP GA Populate" begin
    for t in 1:n_seed
        Random.seed!(t)
        evo = IICGP.DualCGPGAEvo(mcfg, ecfg, ccfg, fit, logid, resdir)
        println(evo.encoder_sympop[1].chromosome[1])
        prevfitnesses = [-Inf]
        for i in 1:n_iter
            evaluate(evo)
            maxfit = maximum(evo.fitness_matrix)
            @test maxfit > -Inf
            @test maxfit >= maximum(prevfitnesses)
            push!(prevfitnesses, maxfit)
            elite_echr, elite_cchr, elite_pairs = get_elites(evo)
            prev_echr = [esym.chromosome for esym in evo.encoder_sympop]
            prev_cchr = [csym.chromosome for csym in evo.controller_sympop]
            populate(evo)
            test_newpop(evo, elite_echr, elite_cchr, elite_pairs)
            test_tournaments_ind(evo, elite_echr, elite_cchr, prev_echr, prev_cchr, "notin")
        end
    end
end

custom_elites_indexes = [(2,2), (2,3), (4,4)]

@testset "CGP GA Populate with custom evaluation" begin
    evo = IICGP.DualCGPGAEvo(mcfg, ecfg, ccfg, fit, logid, resdir)
    for i in 1:n_iter
        evaluate(evo)
        # Custom evaluation
        ne, nc = ecfg.n_population, ccfg.n_population
        nmax = max(ne, nc)
        matsize = (ne, nc)
        evo.elites_matrix = falses(matsize...)
        evo.fitness_matrix = -Inf * ones(matsize...)
    	for i in 1:nmax
            i_modrow = i-ne*divrem(i-1,ne)[1]
            i_modcol = i-nc*divrem(i-1,nc)[1]
    		evo.fitness_matrix[i_modrow, i_modcol] = 1.0
    	end
        elite_echr = Vector{Vector{Float64}}()
        elite_cchr = Vector{Vector{Float64}}()
        if ne == 5 && nc == 5
            for index in custom_elites_indexes
                evo.elites_matrix[index...] = true
                evo.fitness_matrix[index...] = 3.0
                row, col = index
                push!(elite_echr, evo.encoder_sympop[row].chromosome)
                push!(elite_cchr, evo.controller_sympop[col].chromosome)
            end
        end
        populate(evo)
        test_newpop_custom(evo, elite_echr, elite_cchr)
    end
end

#=
function mutate(ind::CGPInd, ind_type::String)
    ind
end

@testset "CGP GA Populate without mutation" begin
    evo = IICGP.DualCGPGAEvo(mcfg, ecfg, ccfg, fit, logid, resdir)
    for i in 1:3
        evaluate(evo)
        elite_echr, elite_cchr, elite_pairs = get_elites(evo)
        prev_echr = [esym.chromosome for esym in evo.encoder_sympop]
        prev_cchr = [csym.chromosome for csym in evo.controller_sympop]
        populate(evo)
        test_newpop(evo, elite_echr, elite_cchr, elite_pairs)
        test_tournaments_ind(evo, elite_echr, elite_cchr, prev_echr, prev_cchr, "in")
    end
end
=#
