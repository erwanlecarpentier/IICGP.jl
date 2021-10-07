using IICGP
using Test

cfg_filename = string(@__DIR__, "/dualcgpga_test.yaml")
game = "gravitar"

main_cfg, enco_cfg, cont_cfg, reducer, bootstrap = IICGP.dualcgp_config(
    cfg_filename, game
)
logid = "2021-testlogid"
resdir = dirname(@__DIR__)
fit(e::SymInd, c::SymInd) = e.chromosome[1] * c.chromosome[1]


evo = IICGP.DualCGPGAEvo(enco_cfg, cont_cfg, fit, logid, resdir)
evaluate(evo)










##



@testset "CGP GA Evaluation" begin
    evo = IICGP.DualCGPGAEvo(enco_cfg, cont_cfg, fit, logid, resdir)
end
