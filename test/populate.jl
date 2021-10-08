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

evo = IICGP.DualCGPGAEvo(mcfg, ecfg, ccfg, fit, logid, resdir)
evaluate(evo)
populate(evo)



##
@testset "CGP GA Populate" begin
    evo = IICGP.DualCGPGAEvo(mcfg, ecfg, ccfg, fit, logid, resdir)
end
