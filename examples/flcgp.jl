using ArgParse
using Cambrian
using CartesianGeneticProgramming
using IICGP
using LinearAlgebra
import Cambrian.mutate

"""
Function generating random inputs/outputs with a simple function mapping.
The function mapping is
    y = cos(x[1] + x[2] * x[3])
where `x[i]` is in `[0.0, 1.0]`.
Can be used to generate a simple dataset.
"""
function generate_io(n::Int64=10)::Tuple{Array{Float64,2},Array{Float64,1}}
    inps = rand(Float64, (n, 3))
    outs = zeros(Float64, (size(inps)[1]))
    for i in eachindex(inps[:,1])
        # outs[i] = cos(inps[i,1] + inps[i,2] * inps[i,3])
        outs[i] = inps[i,1] + inps[i,2] * inps[i,3]
    end
    return inps, outs
end

"""
Fitness function for float-CGP test.
Fitness is calculated based on the L2-error prediction from the given
inputs/outputs dataset.
"""
function fitness(ind::CGPInd, inps::Array{Float64,2},
                 outs::Array{Float64,1})::Array{Float64,1}
    inps, outs = generate_io(100)
    preds = zeros(Float64, (size(inps)[1]))
    for i in eachindex(inps[:,1])
        preds[i] = process(ind, inps[i,:])[1]
    end
    return [-LinearAlgebra.norm(preds .- outs)]
end

"""
Fitness function for float-CGP test.
Fitness is calculated based on the L2-error prediction from the generated
inputs/outputs dataset.
"""
function fitness(ind::CGPInd, n::Int64=100)::Array{Float64,1}
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


foo = CGPInd(cfg)

# Test on random CGP individual
#=
foo = CGPInd(cfg)
fitness(foo)

if length(args["ind"]) > 0
    ind = CGPInd(cfg, read(args["ind"], String))
    ftn = fitness(ind, inps, outs)
    println("Fitness: ", ftn)
else
    # Define mutate and fit functions
    mutate(i::CGPInd) = goldman_mutate(cfg, i)
    fit(i::CGPInd) = fitness(i)

    # Create an evolution framework
    e = CGPEvolution(cfg, fit)

    # Run evolution
    run!(e)
end
=#
