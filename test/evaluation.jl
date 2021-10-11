using IICGP
using Cambrian
using CartesianGeneticProgramming
using Test

import Cambrian.mutate # function extension


function test_fitness_matrix(e::DualCGPGAEvo)
    esize = (length(e.encoder_sympop), length(e.controller_sympop))
    @test size(e.fitness_matrix) == esize
    nrows, ncols = size(e.fitness_matrix)
    # 1. Test at least 1 eval per row col
    for r in eachrow(e.fitness_matrix)
        @test maximum(r) > -Inf
    end
    for c in eachcol(e.fitness_matrix)
        @test maximum(c) > -Inf
    end
    # 2. Test n_eval eval
    @test length(filter(x->x>-Inf, e.fitness_matrix)) == e.n_eval
    # 3. Test n_elites elites are selected
    @test sum(e.elites_matrix) == e.n_elite
    # 4. Test elites are evaluated and have higher scores
    for i in eachindex(e.elites_matrix)
        if e.elites_matrix[i]
            @test e.fitness_matrix[i] > -Inf
            for j in eachindex(e.fitness_matrix)
                if !e.elites_matrix[j]
                    @test e.fitness_matrix[i] >= e.fitness_matrix[j]
                end
            end
        end
    end
end

function test_ind_fitnesses(e::DualCGPGAEvo)
    # Test that individual's fitness is set according to the fitness matrix
    for i in eachindex(e.encoder_sympop)
        @test e.encoder_sympop[i].fitness[1] == maximum(e.fitness_matrix[i,:])
    end
    for j in eachindex(e.controller_sympop)
        @test e.controller_sympop[j].fitness[1] == maximum(e.fitness_matrix[:,j])
    end
end

cfg_filename = string(@__DIR__, "/dualcgpga_test.yaml")
game = "gravitar"
mcfg, ecfg, ccfg, reducer, bootstrap = IICGP.dualcgp_config(cfg_filename, game)
logid = "2021-testlogid"
resdir = dirname(@__DIR__)
function mutate(ind::CGPInd, ind_type::String)
    if ind_type == "encoder"
        return goldman_mutate(ecfg, ind, init_function=IPCGPInd)
    elseif ind_type == "controller"
        return goldman_mutate(ccfg, ind)
    end
end
fit(e::CGPInd, c::CGPInd, seed::Int64) = [e.chromosome[1] * c.chromosome[1]]
n_iter = 3

@testset "CGP GA Evaluation" begin
    evo = IICGP.DualCGPGAEvo(mcfg, ecfg, ccfg, fit, logid, resdir)
    for iter in 1:n_iter
        evaluate(evo)
        test_fitness_matrix(evo)
        test_ind_fitnesses(evo)
        populate(evo)
    end
end
