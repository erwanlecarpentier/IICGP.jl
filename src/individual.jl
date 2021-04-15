export IPCGPInd

using CartesianGeneticProgramming

function IPCGPInd(cfg::NamedTuple)
    buffer = Array{Array{UInt8, 3}}(undef, cfg.rows * cfg.columns + cfg.n_in)
    fill!(buffer, zeros(UInt8, cfg.img_size))
    CGPInd(cfg; buffer=buffer)
end

#=
export Node, IPCGPInd
import Base.copy, Base.String, Base.show, Base.summary
import Cambrian, Cambrian.print

"default function for nodes, will cause error if used as a function node"
function f_null(args...)::Nothing
    nothing
end

struct Node
    x::Int16
    y::Int16
    f::Function
    active::Bool
end

struct IPCGPInd <: Cambrian.Individual
    n_in::Int16
    n_out::Int16
    chromosome::Array{Float64}
    genes::Array{Int16}
    outputs::Array{Int16}
    nodes::Array{Node}
    buffer::AbstractArray
    fitness::Array{Float64}
end

function recur_active!(active::BitArray, ind::Int16, xs::Array{Int16},
                       ys::Array{Int16}, fs::Array{Int16},
                       two_arity::BitArray)::Nothing
    if ind > 0 && ~active[ind]
        active[ind] = true
        recur_active!(active, xs[ind], xs, ys, fs, two_arity)
        if two_arity[fs[ind]]
            recur_active!(active, ys[ind], xs, ys, fs, two_arity)
        end
    end
end

function find_active(cfg::NamedTuple, genes::Array{Int16},
                     outputs::Array{Int16})::BitArray
    R = cfg.rows
    C = cfg.columns
    active = falses(R, C)
    xs = genes[:, :, 1] .- Int16(cfg.n_in)
    ys = genes[:, :, 2] .- Int16(cfg.n_in)
    fs = genes[:, :, 3]
    for i in eachindex(outputs)
        recur_active!(active, outputs[i] - Int16(cfg.n_in), xs, ys, fs,
                      cfg.two_arity)
    end
    active
end

function IPCGPInd(cfg::NamedTuple, chromosome::Array{Float64},
                  genes::Array{Int16}, outputs::Array{Int16})::IPCGPInd
    R = cfg.rows
    C = cfg.columns
    nodes = Array{Node}(undef, R * C + cfg.n_in)
    for i in 1:cfg.n_in
        nodes[i] = Node(0, 0, f_null, false)
    end
    i = cfg.n_in
    active = find_active(cfg, genes, outputs)
    for y in 1:C
        for x in 1:R
            i += 1
            nodes[i] = Node(genes[x, y, 1], genes[x, y, 2],
                            cfg.functions[genes[x, y, 3]],
                            active[x, y])
        end
    end
    buffer = Array{Array{UInt8, 3}}(undef, R * C + cfg.n_in)
    fill!(buffer, zeros(UInt8, cfg.img_size))
    fitness = -Inf .* ones(cfg.d_fitness)
    IPCGPInd(cfg.n_in, cfg.n_out, chromosome, genes, outputs, nodes, buffer, fitness)
end

function IPCGPInd(cfg::NamedTuple, chromosome::Array{Float64})::IPCGPInd
    R = cfg.rows
    C = cfg.columns
    genes = reshape(chromosome[1:(R*C*3)], R, C, 3)
    # TODO: recurrency is ugly and slow
    maxs = collect(1:R:R*C)
    maxs = round.((R*C .- maxs) .* cfg.recur .+ maxs)
    maxs = min.(R*C + cfg.n_in, maxs .+ cfg.n_in)
    maxs = repeat(maxs, 1, R)'
    genes[:, :, 1] .*= maxs
    genes[:, :, 2] .*= maxs
    genes[:, :, 3] .*= length(cfg.functions)
    genes = Int16.(ceil.(genes))
    outputs = Int16.(ceil.(chromosome[(R*C*3+1):end] .* (R * C + cfg.n_in)))
    IPCGPInd(cfg, chromosome, genes, outputs)
end

function IPCGPInd(cfg::NamedTuple)::IPCGPInd
    chromosome = rand(cfg.rows * cfg.columns * 3 + cfg.n_out)
    IPCGPInd(cfg, chromosome)
end

function IPCGPInd(cfg::NamedTuple, ind::String)::IPCGPInd
    dict = JSON.parse(ind)
    IPCGPInd(cfg, Array{Float64}(dict["chromosome"]))
end

function copy(n::Node)
    Node(n.x, n.y, n.f, n.active)
end

function copy(ind::IPCGPInd)
    buffer = Array{Array{UInt8, 3}}(undef, length(ind.buffer))
    fill!(buffer, zeros(UInt8, size(ind.buffer[1])))
    nodes = Array{Node}(undef, length(ind.nodes))
    for i in eachindex(ind.nodes)
        nodes[i] = copy(ind.nodes[i])
    end
    IPCGPInd(ind.n_in, ind.n_out, copy(ind.chromosome), copy(ind.genes),
           copy(ind.outputs), nodes, buffer, copy(ind.fitness))
end

function String(n::Node)
    JSON.json(Dict(:x=>n.x, :y=>n.y, :f=>string(n.f), :active=>n.active))
end

function show(io::IO, n::Node)
    print(io, String(n))
end

function String(ind::IPCGPInd)
    JSON.json(Dict("chromosome"=>ind.chromosome, "fitness"=>ind.fitness))
end

function show(io::IO, ind::IPCGPInd)
    print(io, String(ind))
end

function get_active_nodes(ind::IPCGPInd)
    ind.nodes[[n.active for n in ind.nodes]]
end

function summary(io::IO, ind::IPCGPInd)
    print(io, string("IPCGPInd(", get_active_nodes(ind), ", ",
                     findall([n.active for n in ind.nodes]), ", ",
                     ind.outputs, " ,",
                     ind.fitness, ")"))
end

function interpret(i::IPCGPInd)
    x::AbstractArray->process(i, x)
end
=#
