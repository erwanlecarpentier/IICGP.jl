using ArgParse
using BenchmarkTools
using Cambrian
using CartesianGeneticProgramming
using IICGP
using LinearAlgebra
import Cambrian.mutate  # mutate function scope definition

# rom_names = setdiff(getROMList(), ["pacman", "surround"])
rom_names = [
    "boxing",
    "centipede",
    "demon_attack",
    "enduro",
    "freeway",
    "kung_fu_master",
    "space_invaders",
    "riverraid",
    "pong"
]

function generate_io(rom_name::String="freeway", frame_number::Int64=30)
    inps = Array{Array{Array{UInt8,2},1},1}()
    outs = Array{Array{Float64,1},1}()
    for rom in rom_names
        r, g, b = IICGP.load_rgb(rom, 30)
        i = IICGP.CGPFunctions.f_binary(r, g, [0.5])
        j = IICGP.CGPFunctions.f_erode(i, i, [0.5])
        k = IICGP.CGPFunctions.f_subtract(j, g, [0.5])
        feature = IICGP.ReducingFunctions.max_pool_reduction(k, 5)
        t1 = 0.5 * (feature[1, 1] + feature[2, 2]) * feature[1, 1]
        t2 = feature[3, 3]
        push!(inps, [r, g, b])
        push!(outs, [t1, t2])
    end
    return inps, outs
end

function fitness(encoder::CGPInd, controller::CGPInd,
                 inps::Array{Array{Array{UInt8,2},1},1},
                 outs::Array{Array{Float64,1},1})
    score = 0.0
    for i in eachindex(inps)
        pred = IICGP.process(encoder, controller, inps[i], encoder_cfg.features_size)
        score -= LinearAlgebra.norm(pred - outs[i])
    end
    return score
end

# Read configuration file
s = ArgParseSettings()
@add_arg_table! s begin
    "--encoder_cfg"
    help = "configuration script"
    default = "cfg/encoder.yaml"
    "--controller_cfg"
    help = "configuration script"
    default = "cfg/controller.yaml"
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
n_in = 3  # RGB images
n_out = 2  # Two scalar values
inps, outs = generate_io()
img_size = size(inps[1][1])

encoder_cfg = get_config(args["encoder_cfg"];
    function_module=IICGP.CGPFunctions, n_in=n_in, img_size=img_size)

n_in_controller = encoder_cfg.n_out * encoder_cfg.features_size^2
controller_cfg = get_config(args["controller_cfg"]; n_in=n_in_controller, n_out=n_out)

#=
# Test I/O without evolution
foo = IPCGPInd(encoder_cfg)
bar = CGPInd(controller_cfg)
out = IICGP.process(foo, bar, inps[1], encoder_cfg.features_size)
=#


if length(args["ind"]) > 0
    ind = CGPInd(cfg, read(args["ind"], String))
    ftn = fitness(ind, inps, outs)
    println("Fitness: ", ftn)
else
    # Define mutate and fit functions
    function mutate(ind::CGPInd, ind_type::String)
        if ind_type == "encoder"
            return goldman_mutate(encoder_cfg, ind, init_function=IPCGPInd)
        elseif ind_type == "controller"
            return goldman_mutate(controller_cfg, ind)
        end
    end
    fit(encoder::CGPInd, controller::CGPInd) = fitness(encoder, controller, inps, outs)
    # Create an evolution framework
    e = IICGP.DualCGPEvolution(encoder_cfg, controller_cfg, fit,
                               encoder_init_function=IPCGPInd)
    # Run evolution
    run!(e)
end
