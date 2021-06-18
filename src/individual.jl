export IPCGPInd

using CartesianGeneticProgramming

"""
    image_buffer(rows::Int64, columns::Int64, n_in::Int64, img_size)

Image buffer constructor for IPCGP individuals.
"""
function image_buffer(rows::Int64, columns::Int64, n_in::Int64, img_size)
    buffer = Array{Array{UInt8,2}}(undef, rows * columns + n_in)
    fill!(buffer, zeros(UInt8, img_size))
    return buffer
end

"""
    image_buffer(cfg::NamedTuple)

Image buffer constructor based on config for IPCGP individuals.
"""
function image_buffer(cfg::NamedTuple)
    return image_buffer(cfg.rows, cfg.columns, cfg.n_in, cfg.img_size)
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
    IPCGPInd(nodes::Array{Node}, n_in::Int64, outputs::Array{Int16}, function_module::Module, d_fitness::Int64)::CGPInd

Constructor for IPCGP individuals based on given nodes.
"""
function IPCGPInd(nodes::Array{Node}, n_in::Int64, outputs::Array{Int16},
                  function_module::Module, d_fitness::Int64,
                  img_size::Tuple)::CGPInd
    CGPInd(nodes, n_in, outputs, function_module, d_fitness; img_proc=true,
           img_size=img_size)
end


"""
    CGPInd(nodes::Array{Node}, n_in::Int64, outputs::Array{Int16}, function_module::Module, d_fitness::Int64)::CGPInd

Constructor for CGP individuals based on given nodes.
"""
function CGPInd(nodes::Array{Node}, n_in::Int64, outputs::Array{Int16},
                function_module::Module, d_fitness::Int64; img_proc=false,
                img_size=())::CGPInd
    # Create the appropriate cfg
    functions = Function[]
    two_arity = BitVector()
    for i in eachindex(nodes)
        fi = getfield(function_module, Symbol(nodes[i].f))
        if fi ∉ functions
            push!(functions, fi)
            push!(two_arity, function_module.arity[String(Symbol(nodes[i].f))] == 2)
        end
    end
    P = length(nodes[1].p)
    n_out = length(outputs)
    R = 1
    C = length(nodes)
    cfg = (
        two_arity=two_arity,
        n_in=n_in,
        #m_rate=0,  # Not used in handcrafter CGP
        n_parameters=P,
        functions=functions,
        recur=0.0,  # Not used in handcrafter CGP
        d_fitness=d_fitness,
        n_out=n_out,
        rows=R,
        columns=C,
        img_size=img_size
    )
    # Create the appropriate chromosome
    maxs = collect(1:R:R*C)
    maxs = round.((R*C .- maxs) .* cfg.recur .+ maxs)
    maxs = min.(R*C + cfg.n_in, maxs .+ cfg.n_in)
    maxs = repeat(maxs, 1, R)'
    xs = Float64[]
    ys = Float64[]
    fs = Float64[]
    ps = rand(P, length(nodes))
    for i in eachindex(nodes)
        push!(xs, nodes[i].x)
        push!(ys, nodes[i].y)
        push!(fs, findall(functions -> functions == nodes[i].f, functions)[1] / length(functions))
        for j in eachindex(nodes[i].p)
            ps[j, i] = nodes[i].p[j]
        end
    end
    xs = (reshape(xs, (1, length(xs))) ./ maxs)[1,:]
    ys = (reshape(ys, (1, length(ys))) ./ maxs)[1,:]
    ps = [ps[i, j] for i in eachindex(ps[:,1]) for j in eachindex(ps[1,:])]
    outs = outputs ./ (R * C + n_in)
    chromosome = vcat(xs, ys, fs, ps, outs)
    # Create individual
    if img_proc
        buffer = image_buffer(cfg)
        CartesianGeneticProgramming.CGPInd(cfg, chromosome; buffer=buffer)
    else
        CartesianGeneticProgramming.CGPInd(cfg, chromosome)
    end
end
