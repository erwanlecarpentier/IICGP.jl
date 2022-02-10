export IPCGPInd, IPCGPCopy, image_buffer, get_last_dualcgp, get_best_lucie_ind
export SymInd, SymIndCopy
export NSGA2Ind, NSGA2IndCopy, dominates
export NSGA2ECInd, NSGA2ECIndCopy, dominates
export ECCGPInd
export rand_CGPchromosome, SymIndCopy

using CartesianGeneticProgramming
using Cambrian
using JSON

"""
NSGA2 standard indivudal
"""
mutable struct NSGA2Ind <: Cambrian.Individual
    chromosome::Vector{Float64}
    fitness::Vector{Float64}
    rank::Int64
    domination_count::Int64
    domination_list::Vector{Int64}
    crowding_distance::Float64
    is_elite::Bool
end

function NSGA2Ind(cfg::NamedTuple, chromosome::Vector{Float64})
    fitness = -Inf * ones(cfg.d_fitness)
    rank = 0
    domination_count = 0
    domination_list = Vector{Int64}()
    crowding_distance = 0.0
    is_elite = false
    NSGA2Ind(chromosome, fitness, rank, domination_count,
             domination_list, crowding_distance, is_elite)
end

function NSGA2IndCopy(ind::NSGA2Ind)
    NSGA2Ind(copy(ind.chromosome), copy(ind.fitness), ind.rank,
             ind.domination_count, ind.domination_list, ind.crowding_distance,
             ind.is_elite)
end

"""
NSGA2 indivudal for Encoder-Controller individual
"""
mutable struct NSGA2ECInd <: Cambrian.Individual
    e_chromosome::Vector{Float64}
    c_chromosome::Vector{Float64}
    fitness::Vector{Float64}
    rank::Int64
    domination_count::Int64
    domination_list::Vector{Int64}
    crowding_distance::Float64
    is_elite::Bool
    reached_frames::Int64
end

function NSGA2ECInd(
    cfg::NamedTuple,
    e_chromosome::Vector{Float64},
    c_chromosome::Vector{Float64}
)
    fitness = -Inf * ones(cfg.d_fitness)
    rank = 0
    domination_count = 0
    domination_list = Vector{Int64}()
    crowding_distance = 0.0
    is_elite = false
    reached_frames = 0
    NSGA2ECInd(e_chromosome, c_chromosome, fitness, rank, domination_count,
               domination_list, crowding_distance, is_elite, reached_frames)
end

function NSGA2IndCopy(ind::NSGA2ECInd)
    NSGA2ECInd(copy(ind.e_chromosome), copy(ind.c_chromosome),
               copy(ind.fitness), ind.rank, ind.domination_count,
               ind.domination_list, ind.crowding_distance, ind.is_elite,
               ind.reached_frames)
end

function dominates(ind1::T, ind2::T) where {T <: Union{NSGA2Ind, NSGA2ECInd}}
    @inbounds for i in eachindex(ind1.fitness)
        if ind1.fitness[i] < ind2.fitness[i]
            return false
        end
    end
    return true
end

"""
Symbolic Individual struct for easy/fast representation in
dual CGP GA evolution.
"""
mutable struct SymInd <: Cambrian.Individual
    chromosome::Vector{Float64}
    index::Int64 # row / column index in 2D fitness matrix
    type::String
    fitness::Vector{Float64}
end

function SymInd(chromosome::Vector{Float64}, index::Int64, type::String)
    SymInd(chromosome, index, type, [-Inf])
end

function SymIndCopy(ind::SymInd)::SymInd
    SymInd(copy(ind.chromosome), copy(ind.index), ind.type, copy(ind.fitness))
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

function get_best_lucie_ind(
    exp_dir::String;
    gen::Int64=0,
    verbose::Bool=true
)
    _, exp_id, game = parse_log_entry(exp_dir)
    cfg = cfg_from_exp_dir(exp_dir)
    log = log_from_exp_dir(exp_dir, log_file="logs/logs.csv",
        header=1, sep=";")
    df = DataFrame(log)
    gen = gen == 0 ? df.gen_number[end] : gen
    df = filter(row -> row.gen_number == gen, df)
    fitnesses = [strvec2vec(row.fitnesses) for row in eachrow(df)]
    mean_fitnesses = [Statistics.mean(f) for f in fitnesses]
    best_ind_index = argmax(mean_fitnesses)
    best_ind_mean_fitness = mean_fitnesses[best_ind_index]
    best_ind_dna_id = int2dnaid(df[best_ind_index,:].dna_id)
    best_ind_n_eval = length(fitnesses[best_ind_index])
    if verbose
        println(string("\nBest individual, generation ", gen, ":"))
        println(string("dna_id: ", best_ind_dna_id, " mean: ",
            best_ind_mean_fitness, " n_eval: ", best_ind_n_eval))
        println("Other individuals:")
        for row in eachrow(df)
            fitnesses = strvec2vec(row.fitnesses)
            n_eval = length(fitnesses)
            mean = Statistics.mean(fitnesses)
            dna_id = int2dnaid(row.dna_id)
            println(string("dna_id: ", dna_id, " mean: ", mean, " n_eval: ",
                n_eval))
        end
    end
    enco_dna_path, cont_dna_path = get_ec_dna_paths(exp_dir, string(gen), best_ind_dna_id)
    enco_dna = read(enco_dna_path, String)
    cont_dna = read(cont_dna_path, String)
    _, enco_cfg, cont_cfg, reducer, _ = dualcgp_config(cfg, game, exp_id)
    enco = IPCGPInd(enco_cfg, enco_dna)
    cont = CGPInd(cont_cfg, cont_dna)
    enco, reducer, cont
end

function get_last_dualcgp(exp_dir::String)
    cfg = cfg_from_exp_dir(exp_dir)
    get_last_dualcgp(exp_dir, cfg)
end

function get_last_dualcgp(exp_dir::String, cfg::Dict)
    _, exp_id, game = parse_log_entry(exp_dir)
    enco_dna_path, cont_dna_path = get_last_dualcgp_paths(exp_dir)
    _, enco_cfg, cont_cfg, reducer, _ = dualcgp_config(cfg, game, exp_id)
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
