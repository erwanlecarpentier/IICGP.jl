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

    # Arbitrary application of simple OpenCV functions
    i = IICGP.CGPFunctions.f_add_img(r, g)
    j = IICGP.CGPFunctions.f_erode_img(i, i)
    k = IICGP.CGPFunctions.f_compare_eq_img(j, g)
    # l = IICGP.CGPFunctions.f_dilate_img(k, k)
    # m = IICGP.CGPFunctions.f_compare_ge_img(j, l)

    # Feature map
    feature = IICGP.ReducingFunctions.max_pool_reduction(k, 5)

    target = 0.5 * (feature[1, 1, 1] + feature[1, 2, 2]) / feature[1, 1, 1]

    return [r, g, b], target
end

function fitness(encoder::CGPInd, controller::CGPInd, input::Vector{T}, target::Int64) where {T <: OpenCV.InputArray}
    out = IICGP.process(encoder, controller, input, encoder_cfg.features_size)
    if out == target
        return 1.0
    else
        return 0.0
    end
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
n_in_controller = encoder_cfg.n_out * encoder_cfg.features_size^2
controller_cfg = get_config(args["controller_cfg"]; n_in=n_in_controller, n_out=1)

# Test I/O without evolution
#=
foo = IPCGPInd(encoder_cfg)
bar = CGPInd(controller_cfg)
out = IICGP.process(foo, bar, inp, encoder_cfg.features_size)
# IICGP.display_buffer(foo, 2, indexes=1:4)
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
    fit(encoder::CGPInd, controller::CGPInd) = fitness(encoder, controller, inp, target)
    # Create an evolution framework
    e = IICGP.DualCGPEvolution(encoder_cfg, controller_cfg, fit,
                               encoder_init_function=IPCGPInd)
    # Run evolution
    run!(e)
end
