using IICGP
using Cambrian
using CartesianGeneticProgramming
using Test


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
    println("TODO test elites")
end

cfg_filename = string(@__DIR__, "/dualcgpga_test.yaml")
game = "gravitar"
mcfg, ecfg, ccfg, reducer, bootstrap = IICGP.dualcgp_config(cfg_filename, game)
logid = "2021-testlogid"
resdir = dirname(@__DIR__)
fit(e::CGPInd, c::CGPInd) = [e.chromosome[1] * c.chromosome[1]]

@testset "CGP GA Evaluation" begin
    evo = IICGP.DualCGPGAEvo(mcfg, ecfg, ccfg, fit, logid, resdir)
    evaluate(evo)
    test_fitness_matrix(evo)
end
