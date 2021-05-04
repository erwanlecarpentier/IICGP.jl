using OpenCV
using ArgParse
using Cambrian
using CartesianGeneticProgramming
using IICGP
import Cambrian.mutate  # mutate function scope definition
using BenchmarkTools

function load_img(rom_name::String, frame_number::Int64)
    filename = string(@__DIR__, "/images/", rom_name, "_frame_$frame_number.png")
    return OpenCV.imread(filename)
end

function generate_io(rom_name::String="freeway", frame_number::Int64=30)
    img = load_img(rom_name, frame_number)
    r, g, b = IICGP.split_rgb(img)
    return [r, g, b], 5
end

function fitness(ind::CGPInd, input::Vector{T}, target::T) where {T <: OpenCV.InputArray}
    output = process(ind, input)
    [-OpenCV.norm(output[1], target)]
end

# Read configuration file
s = ArgParseSettings()
@add_arg_table! s begin
    "--encoder_cfg"
    help = "encoder configuration script"
    default = "cfg/encoder.yaml"
    "--controller_cfg"
    help = "controller configuration script"
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
n_out = 1  # Single scalar
inp, target = generate_io()
img_size = size(inp[1])
encoder_cfg = get_config(args["encoder_cfg"];
    function_module=IICGP.CGPFunctions, n_in=3, img_size=img_size)
n_in_controller = encoder_cfg.n_out * encoder_cfg.out_size^2
controller_cfg = get_config(args["controller_cfg"]; n_in=n_in_controller, n_out=1)

# Test I/O without evolution
foo = IPCGPInd(encoder_cfg)
bar = CGPInd(controller_cfg)
out = IICGP.process(foo, bar, inp, encoder_cfg.out_size)
# IICGP.display_buffer(foo, 2, indexes=1:4)

#=
if length(args["ind"]) > 0
    ind = CGPInd(cfg, read(args["ind"], String))
    ftn = fitness(ind, inps, outs)
    println("Fitness: ", ftn)
else
    # Define mutate and fit functions
    mutate(i::CGPInd) = goldman_mutate(cfg, i, init_function=IPCGPInd)
    fit(i::CGPInd) = fitness(i, inp, target)
    # Create an evolution framework
    e = CGPEvolution(cfg, fit, init_function=IPCGPInd)
    # Run evolution
    run!(e)
end
=#
