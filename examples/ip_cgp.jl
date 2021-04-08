using Test
using OpenCV
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
    a = IPCGPFunctions.f_add_img(r, g)
    b = IPCGPFunctions.f_erode_img(a, a)
    c = IPCGPFunctions.f_compare_eq_img(b, g)
    d = IPCGPFunctions.f_dilate_img(c, c)
    output = IPCGPFunctions.f_compare_ge_img(b, d)

    return r, g, b, output
end

# Generate input / output
r, g, b, output = generate_io_image()
