using Test
using OpenCV
using ArgParse
using Cambrian
using CartesianGeneticProgramming
using IICGP

"""
Fitness function for float-CGP test.
Fitness is calculated based on the error prediction from
"""
function fitness(ind::CGPInd, input::Vector{Float64})
    
    #output = process(ind, input)
    [0.0]
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
input_rgb, target = generate_io_image()
img_size = size(target)
cfg = read_config(args["cfg"]; n_in=n_in, n_out=n_out, img_size=img_size)


test_ind = CGPInd(cfg)
out = IICGP.process(test_ind, input_rgb)
IICGP.imshow(out[1])
my_img = IPCGPFunctions.f_compare_eq_img(input_rgb[2], input_rgb[3])
fitness(test_ind, input_rgb, target)


# Define mutate and fit functions
mutate(i::IPCGPInd) = goldman_mutate(cfg, i)
fit(i::IPCGPInd) = fitness(i, input_rgb, target)

# Create an evolution framework
e = CGPEvolution(cfg, fit)

# Run evolution
run!(e)
