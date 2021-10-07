using IICGP
using Cambrian
using Test

cfg_filename = string(@__DIR__, "/dualcgpga_test.yaml")
game = "gravitar"

mcfg, ecfg, ccfg, reducer, bootstrap = IICGP.dualcgp_config(cfg_filename, game)
logid = "2021-testlogid"
resdir = dirname(@__DIR__)
fit(e::SymInd, c::SymInd) = e.chromosome[1] * c.chromosome[1]


evo = IICGP.DualCGPGAEvo(ecfg, ccfg, fit, logid, resdir)
evaluate(evo)
# Test at least 1 eval per row col
# Test n_eval eval
# Test elites are selected
# Test there are n_elites elites

# evaluate(evo) # Reevaluate

# Test elites are evaluated
# Test at least 1 eval per row col
# Test n_eval eval
# Test elites are selected
# Test there are n_elites elites

@testset "CGP GA Evaluation" begin
    @test true
end
