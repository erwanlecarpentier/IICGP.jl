export IPCGPInd, SymInd, IPCGPCopy, image_buffer, get_last_dualcgp
export rand_CGPchromosome

using CartesianGeneticProgramming
using JSON

"""
Symbolic Individual struct for easy/fast representation in
dual CGP GA evolution.
"""
struct SymInd
    chromosome::Vector{Float64}
    index::Int64 # row / column index in 2D fitness matrix
    type::String
    fitness::Float64
end

function SymInd(chromosome::Vector{Float64}, index::Int64, type::String)
    SymInd(chromosome, index, type, -Inf)
end

function rand_CGPchromosome(cfg::NamedTuple)::Vector{Float64}
    rand(cfg.rows * cfg.columns * (3 + cfg.n_parameters) + cfg.n_out)
end

"""
    image_buffer(buffer_size::Int64, img_size::Tuple)

Image buffer constructor for IPCGP individuals.
"""
function image_buffer(buffer_size::Int64, img_size::Tuple)
    buffer = Array{Array{UInt8,2}}(undef, buffer_size)
    fill!(buffer, zeros(UInt8, img_size))
    return buffer
end

"""
    image_buffer(rows::Int64, columns::Int64, n_in::Int64, img_size)

Image buffer constructor for IPCGP individuals.
"""
function image_buffer(rows::Int64, columns::Int64, n_in::Int64, img_size::Tuple)
    # buffer = Array{Array{UInt8,2}}(undef, rows * columns + n_in)
    # fill!(buffer, zeros(UInt8, img_size))
    return image_buffer(rows * columns + n_in, img_size)
end

"""
    image_buffer(cfg::NamedTuple)

Image buffer constructor based on config for IPCGP individuals.
"""
function image_buffer(cfg::NamedTuple)
    return image_buffer(cfg.rows, cfg.columns, cfg.n_in, cfg.img_size)
end

"""
    reset(ind::CGPInd)

Generic function for reseting buffer.
"""
function reset_buffer(ind::CGPInd)
    if typeof(ind.buffer[1]) == Array{UInt8,2}
        ind.buffer .= image_buffer(length(ind.buffer), size(ind.buffer[1]))
    elseif typeof(ind.buffer[1]) == Float64
        ind.buffer .= zeros(length(ind.buffer))
    else
        throw(ArgumentError("Buffer elements type $(typeof(ind.buffer[1])) not recognized."))
    end
end

"""
    IPCGPInd(cfg::NamedTuple)

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

"""
    function IPCGPInd(
        nodes::Array{Node},
        cfg::NamedTuple,
        outputs::Array{Int16},
        img_size::Tuple
    )::CGPInd

Constructor for IPCGP individuals based on given nodes.
"""
function IPCGPInd(
    nodes::Array{Node},
    cfg::NamedTuple,
    outputs::Array{Int16},
    img_size::Tuple
)::CGPInd
    buffer = image_buffer(cfg.rows, cfg.columns, cfg.n_in, img_size)
    CartesianGeneticProgramming.CGPInd(nodes, cfg, outputs, buffer=buffer)
end

"""
    IPCGPInd(nodes::Array{Node}, n_in::Int64, outputs::Array{Int16}, function_module::Module, d_fitness::Int64)::CGPInd

Constructor for IPCGP individuals based on DNA path.
"""
function IPCGPInd(cfg::NamedTuple, dna_path::String)::CGPInd
    dict = JSON.parse(dna_path)
    IPCGPInd(cfg, Array{Float64}(dict["chromosome"]))
end

function IPCGPCopy(ind::CGPInd)
    img_size = size(ind.buffer[1])
    buffer = image_buffer(length(ind.buffer), img_size)
    nodes = Array{Node}(undef, length(ind.nodes))
    for i in eachindex(ind.nodes)
        nodes[i] = copy(ind.nodes[i])
    end
    CartesianGeneticProgramming.CGPInd(
        ind.n_in, ind.n_out, ind.n_parameters,
        copy(ind.chromosome), copy(ind.genes), copy(ind.outputs), nodes, buffer,
        copy(ind.fitness)
    )
end

function get_last_dualcgp(path::String, game::String, cfg::Dict)
    enco_dna_path, cont_dna_path = get_last_dualcgp_paths(path)
    _, enco_cfg, cont_cfg, reducer, _ = dualcgp_config(cfg, game)
    enco = IPCGPInd(enco_cfg, read(enco_dna_path, String))
    cont = CGPInd(cont_cfg, read(cont_dna_path, String))
    enco, reducer, cont
end

function get_last_monocgp(path::String, game::String, cfg::Dict)
    cont_dna_path = get_last_ind_path(path, "controller")
    _, cont_cfg, reducer, _ = monocgp_config(cfg, game)
    cont = CGPInd(cont_cfg, read(cont_dna_path, String))
    reducer, cont
end
