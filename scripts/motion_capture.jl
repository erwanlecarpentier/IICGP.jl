using OpenCV
using IICGP

# method with global mutable variable
function motion_capture(m::T) where {T <: OpenCV.InputArray}
    if @isdefined global_mutable_mc_buffer
        global global_mutable_mc_buffer
        return OpenCV.subtract(m, global_mutable_mc_buffer)
    else
        global global_mutable_mc_buffer
        global_mutable_mc_buffer = m
        return nothing
    end
end

# method with `let` to hide the internal state
#=
let buffer = Ref{Union{<:OpenCV.InputArray, Nothing}}(nothing)
    global motion_capture
    function motion_capture(m::T) where {T <: OpenCV.InputArray}
        if buffer[] !== nothing
            return OpenCV.subtract(m, buffer)
        else
            buffer = m
            return nothing
        end
    end
 end
=#

function load_img(rom_name::String, frame_number::Int64)
    filename = string(@__DIR__, "/images/", rom_name, "_frame_$frame_number.png")
    return OpenCV.imread(filename)
end

rom_name = "freeway"

# First input
img = load_img(rom_name, 30)
IICGP.imshow(img)
out = motion_capture(img)
# println(out)

# Second input
img = load_img(rom_name, 31)
out = motion_capture(img)
IICGP.imshow(out)
