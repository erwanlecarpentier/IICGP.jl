export IPCGPInd

using CartesianGeneticProgramming

"""
    function image_buffer(cfg::NamedTuple)

Image buffer constructor for IPCGP individuals.
"""
function image_buffer(cfg::NamedTuple)
    buffer = Array{Array{UInt8,2}}(undef, cfg.rows * cfg.columns + cfg.n_in)
    fill!(buffer, zeros(UInt8, cfg.img_size))
    return buffer
end

"""
    function IPCGPInd(cfg::NamedTuple)

Constructor for IPCGP individual based on configuration.
"""
function IPCGPInd(cfg::NamedTuple)
    buffer = image_buffer(cfg)
    CartesianGeneticProgramming.CGPInd(cfg; buffer=buffer)
end

"""
    function IPCGPInd(cfg::NamedTuple, chromosome::Array{Float64})

Constructor for IPCGP individual based on configuration and chromosome.
"""
function IPCGPInd(cfg::NamedTuple, chromosome::Array{Float64})
    buffer = image_buffer(cfg)
    CartesianGeneticProgramming.CGPInd(cfg, chromosome; buffer=buffer)
end
