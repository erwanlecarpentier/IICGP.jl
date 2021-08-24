using IICGP
using Test

cfg_filename = string(@__DIR__, "/dualcgp_test.yaml")
game = "assault"

main_cfg, enco_cfg, cont_cfg, reducer, bootstrap = IICGP.dualcgp_config(
    cfg_filename, game
)
enco = IPCGPInd(enco_cfg)
cont = CGPInd(cont_cfg)
@test true
