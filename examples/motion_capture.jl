using OpenCV
using IICGP


function motion_capture(m::T, buffer::T) where {T <: OpenCV.InputArray}
    OpenCV.subtract(m, buffer)
end

function load_img(rom_name::String, frame_number::Int64)
    filename = string(@__DIR__, "/images/", rom_name, "_frame_$frame_number.png")
    return OpenCV.imread(filename)
end

rom_name = "freeway"

# First input
img = load_img(rom_name, 30)
out = motion_capture(img)
IICGP.imshow(out)

# Second input
img = load_img(rom_name, 31)
out = motion_capture(img)
IICGP.imshow(out)
