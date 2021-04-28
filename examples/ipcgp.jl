using OpenCV
using ArgParse
using Cambrian
using CartesianGeneticProgramming
using IICGP

function load_img(rom_name::String, frame_number::Int64)
    filename = string(@__DIR__, "/images/", rom_name, "_frame_$frame_number.png")
    return OpenCV.imread(filename)
end

function generate_io_image(rom_name::String="freeway", frame_number::Int64=30)
    img = load_img(rom_name, frame_number)
    r, g, b = IICGP.split_rgb(img)

    # Arbitrary application of simple OpenCV functions
    i = IICGP.CGPFunctions.f_add_img(r, g)
    j = IICGP.CGPFunctions.f_erode_img(i, i)
    k = IICGP.CGPFunctions.f_compare_eq_img(j, g)
    l = IICGP.CGPFunctions.f_dilate_img(k, k)
    target = IICGP.CGPFunctions.f_compare_ge_img(j, l)

    return [r, g, b], target
end

function fitness(ind::CGPInd, input::Vector{T}, target::T) where {T <: OpenCV.InputArray}
    output = process(ind, input)
    [-OpenCV.norm(output[1], target)]
end

# Read configuration file
s = ArgParseSettings()
@add_arg_table! s begin
    "--cfg"
    help = "configuration script"
    default = "cfg/ipcgp.yaml"
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
n_out = 1  # Single image
input_rgb, target = generate_io_image()
img_size = size(target)
cfg = CartesianGeneticProgramming.get_config(args["cfg"]; function_module=IICGP.CGPFunctions, n_in=n_in, n_out=n_out, img_size=img_size)

inp, target = generate_io_image()

#=
# Test I/O without evolution
foo = IICGP.IPCGPInd(cfg)
CartesianGeneticProgramming.set_inputs(foo, input_rgb)
CartesianGeneticProgramming.process(foo)
IICGP.display_buffer(foo, 2, indexes=1:3)
=#


if length(args["ind"]) > 0
    ind = CGPInd(cfg, read(args["ind"], String))
    ftn = fitness(ind, inps, outs)
    println("Fitness: ", ftn)
else
    # Define mutate and fit functions
    mutate(i::CGPInd) = goldman_mutate(cfg, i)
    fit(i::CGPInd) = fitness(i, inp, target)
    # Create an evolution framework
    e = CGPEvolution(cfg, fit)
    # Run evolution
    run!(e)
end
