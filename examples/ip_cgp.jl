using Test
using OpenCV
using ArgParse
using Cambrian
# using CartesianGeneticProgramming
using IICGP


function load_img(rom_name::String, frame_number::Int64)
    filename = string(@__DIR__, "/images/", rom_name, "_frame_$frame_number.png")
    return OpenCV.imread(filename)
end


function generate_io_image(rom_name::String="freeway", frame_number::Int64=30)
    img = load_img(rom_name, frame_number)
    r, g, b = IICGP.split_rgb(img)

    # Arbitrary application of simple OpenCV functions
    a = IPCGPFunctions.f_add_img(r, g)
    b = IPCGPFunctions.f_erode_img(a, a)
    c = IPCGPFunctions.f_compare_eq_img(b, g)
    d = IPCGPFunctions.f_dilate_img(c, c)
    target = IPCGPFunctions.f_compare_ge_img(b, d)

    return [r, g, b], target
end


function fitness(ind::CGPInd, input::Vector{T}, target::T) where {T <: OpenCV.InputArray}
    output = process(ind, input)
    OpenCV.norm(output, target)
end


# Read configuration file
s = ArgParseSettings()
@add_arg_table! s begin
    "--cfg"
    help = "configuration script"
    default = "cfg/ip_cgp.yaml"
    "--seed"
    help = "random seed for evolution"
    arg_type = Int
    default = 0
end
args = parse_args(ARGS, s)
n_in = 3  # RGB images
n_out = 1  # Single image
cfg = read_config(args["cfg"]; n_in=n_in, n_out=n_out)

# Generate input / output
input_rgb, target = generate_io_image()

# TODO here
test_ind = CGPInd(cfg)
out = IICGP.process(test_ind, input_rgb)


# Define mutate and fit functions
mutate(i::CGPInd) = goldman_mutate(cfg, i)
fit(i::CGPInd) = fitness(i, input, target)



# Create an evolution framework
e = CGPEvolution(cfg, fit)

# Run evolution
run!(e)
