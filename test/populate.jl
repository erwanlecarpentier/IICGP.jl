using IICGP
using Cambrian
using CartesianGeneticProgramming
using Test

import Cambrian.mutate # function extension


cfg_filename = string(@__DIR__, "/dualcgpga_test.yaml")
game = "gravitar"
mcfg, ecfg, ccfg, reducer, bootstrap = IICGP.dualcgp_config(
    cfg_filename, game
)
logid = "2021-test-logid"
resdir = dirname(@__DIR__)
function mutate(ind::CGPInd, ind_type::String)
    if ind_type == "encoder"
        return goldman_mutate(ecfg, ind, init_function=IPCGPInd)
    elseif ind_type == "controller"
        return goldman_mutate(ccfg, ind)
    end
end
fit(e::CGPInd, c::CGPInd) = [e.chromosome[1] * c.chromosome[1]]




evo = IICGP.DualCGPGAEvo(mcfg, ecfg, ccfg, fit, logid, resdir)
evaluate(evo)
populate(evo)




##
@testset "CGP GA Populate" begin
    evo = IICGP.DualCGPGAEvo(mcfg, ecfg, ccfg, fit, logid, resdir)

    # Test that elites are kept between generations (same chromosomes)
    # Test that pop size is maintened
    # Test that non elites have a close parent in previous generation
end
