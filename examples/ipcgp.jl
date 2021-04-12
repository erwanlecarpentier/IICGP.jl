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
    a = IICGP.CGPFunctions.f_add_img(r, g)
    b = IICGP.CGPFunctions.f_erode_img(a, a)
    c = IICGP.CGPFunctions.f_compare_eq_img(b, g)
    d = IICGP.CGPFunctions.f_dilate_img(c, c)
    target = IICGP.CGPFunctions.f_compare_ge_img(b, d)

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
my_img = IICGP.CGPFunctions.f_compare_eq_img(input_rgb[2], input_rgb[3])
fitness(test_ind, input_rgb, target)


# Define mutate and fit functions
mutate(i::IPCGPInd) = goldman_mutate(cfg, i)
fit(i::IPCGPInd) = fitness(i, input_rgb, target)

# Create an evolution framework
e = CGPEvolution(cfg, fit)

# Run evolution
run!(e)
