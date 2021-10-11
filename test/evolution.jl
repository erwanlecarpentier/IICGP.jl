using IICGP
using Test


cfg_filename = string(@__DIR__, "/dualcgpga_test.yaml")
game = "gravitar"
mcfg, ecfg, ccfg, reducer, bootstrap = IICGP.dualcgp_config(
    cfg_filename, game
)
logid = "2021-test-logid"
resdir = dirname(@__DIR__)
fit(e::SymInd, c::SymInd) = e.chromosome[1] * c.chromosome[1]

@testset "CGP GA Evolution" begin
    evo = IICGP.DualCGPGAEvo(mcfg, ecfg, ccfg, fit, logid, resdir)
    @test length(evo.encoder_sympop) == ecfg.n_population
    @test length(evo.controller_sympop) == ccfg.n_population
    sympops = [evo.encoder_sympop, evo.controller_sympop]
    cfgs = [ecfg, ccfg]
    types = ["encoder", "controller"]
    for l in eachindex(sympops)
        sympop = sympops[l]
        cfg = cfgs[l]
        type = types[l]
        n_chr = cfg.rows * cfg.columns * (3 + cfg.n_parameters) + cfg.n_out
        for i in eachindex(sympop)
            @test typeof(sympop[i].chromosome) <: Vector{Float64}
            @test length(sympop[i].chromosome) == n_chr
            @test sympop[i].index == i
            @test sympop[i].fitness == [-Inf]
            @test sympop[i].type == type
        end
    end
    mat_size = (ecfg.n_population, ccfg.n_population)
    @test size(evo.fitness_matrix) == mat_size
    @test size(evo.elites_matrix) == mat_size
    @test all(i -> i == -Inf, evo.fitness_matrix)
    @test all(i -> i == false, evo.elites_matrix)
end
