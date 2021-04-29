export IPCGPInd

using CartesianGeneticProgramming

struct IPCGPInd <: Cambrian.Individual
    cgp_ind::CartesianGeneticProgramming.CGPInd
end

"""
    function IPCGPInd(cfg::NamedTuple)

Configuration-based constructor for IPCGP individual.
"""
function IPCGPInd(cfg::NamedTuple)
    buffer = Array{Array{UInt8, 3}}(undef, cfg.rows * cfg.columns + cfg.n_in)
    fill!(buffer, zeros(UInt8, cfg.img_size))
    IPCGPInd(CartesianGeneticProgramming.CGPInd(cfg; buffer=buffer))
end
