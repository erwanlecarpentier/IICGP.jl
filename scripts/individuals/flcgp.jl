using ArgParse
using Cambrian
using CartesianGeneticProgramming
using IICGP
using LinearAlgebra
import Cambrian.mutate

"""
    function generate_io(n::Int64=10)::Tuple{Array{Float64,2},Array{Float64,1}}

Function generating random inputs/outputs with a simple function mapping.
The function mapping is
    y = 0.5 * (x[1] + x[2] * x[3])
where `x[i]` is in `[0.0, 10.0]`.
Can be used to generate a simple dataset.
"""
function generate_io(n::Int64=1000)::Tuple{Array{Float64,2},Array{Float64,1}}
    inps = 10 * rand(Float64, (n, 3))
    return inps, 0.5 * (inps[:, 1] .+ inps[:, 2] .* inps[:, 3])
end

"""
    function fitness(ind::CGPInd, inps::Array{Float64,2}, outs::Array{Float64,1})::Array{Float64,1}

Fitness function for float-CGP test.
Fitness is calculated based on the L2-error prediction from the given
inputs/outputs dataset.
"""
function fitness(ind::CGPInd, inps::Array{Float64,2},
                 outs::Array{Float64,1})::Array{Float64,1}
    preds = zeros(Float64, (size(inps)[1]))
    for i in eachindex(inps[:,1])
        preds[i] = CartesianGeneticProgramming.process(ind, inps[i,:])[1]
    end
    return [-LinearAlgebra.norm(preds .- outs, 1) / length(preds)]
end

"""
    function fitness(ind::CGPInd, n::Int64=100)::Array{Float64,1}

Fitness function for float-CGP test.
Fitness is calculated based on the L2-error prediction from the generated
inputs/outputs dataset.
"""
function fitness(ind::CGPInd, n::Int64=1000)::Array{Float64,1}
    inps, outs = generate_io(n)
    fitness(ind, inps, outs)
end

# Read configuration file
s = ArgParseSettings()
@add_arg_table! s begin
    "--cfg"
    help = "configuration script"
    default = "cfg/flcgp.yaml"
    "--seed"
    help = "random seed for evolution"
    arg_type = Int
    default = 0
    "--ind"
    help = "individual for evaluation"
    arg_type = String
    default = ""
end
args = parse_args(ARGS, s)
n_in = 3  # Three floating numbers as input
n_out = 1  # Single output
cfg = CartesianGeneticProgramming.get_config(args["cfg"]; n_in=n_in, n_out=n_out)

#=
# Test I/O without evolution
inp, out = generate_io(1)
bar = CGPInd(cfg)
CartesianGeneticProgramming.set_inputs(bar, inp)
CartesianGeneticProgramming.process(bar)
=#

#=
# Test perfect ind
function generate_perfect_ind(cfg::NamedTuple)
    chromosome = [
        0.3, 0.1, 0.0, 0.0, 0.0, # xs
        0.5, 0.6, 0.0, 0.0, 0.0, # ys
        0.4, 0.1, 0.1, 0.1, 0.1, # fs
        0.6  # output
    ]
    return CGPInd(cfg, chromosome)
end
foo = generate_perfect_ind(cfg)
=#

if length(args["ind"]) > 0
    ind = CGPInd(cfg, read(args["ind"], String))
    ftn = fitness(ind, inps, outs)
    println("Fitness: ", ftn)
else
    # Define mutate and fit functions
    mutate(i::CGPInd) = goldman_mutate(cfg, i)
    fit(i::CGPInd) = fitness(i, 1000)
    # Create an evolution framework
    e = CGPEvolution(cfg, fit)
    # Run evolution
    run!(e)
end
