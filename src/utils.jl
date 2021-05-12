export load_img, save_img, split_rgb

"""
    function load_img(filename::String)

Load an image given file name.
"""
function load_img(filename::String)
    img = FileIO.load(filename)
    println(typeof(img))
    convert(Array{UInt8}, rawview(channelview(img)))
end

"""
    function load_img(filename::String)

Load a pre-saved Atari image given ROM name and frame number.
"""
function load_img(rom_name::String, frame_number::Int64)
    filename = string(@__DIR__, "/../images/", rom_name, "_frame_30.png")
    load_img(filename)
end

"""
    function load_rgb(rom_name::String, frame_number::Int64)

Load a pre-saved Atari image given ROM name and frame number.
Return an array containing the separated chanels.
"""
function load_rgb(rom_name::String, frame_number::Int64)
    filename = string(@__DIR__, "/../images/", rom_name, "_frame_30.png")
    split_rgb(load_img(filename))
end

"""
    function save_img(img::Array{Float64,3}, filename::String)

Save an image to the input path.
"""
function save_img(img::Array{Float64,3}, filename::String)
    FileIO.save(filename, colorview(RGB, img))
end

"""
    function save_img(img::Array{UInt8,3}, filename::String)

Save an image to the input path.
"""
function save_img(img::Array{UInt8,3}, filename::String)
    img = adjust_histogram(Float64.(img), LinearStretching())
    save_img(img, filename)
end

#=
@deprecated
using OpenCV

"""
    split_rgb(m::T) where {T <: OpenCV.InputArray}

Split input array in three channels.
"""
function split_rgb(m::T) where {T <: OpenCV.InputArray}
    @assert size(m)[1] == 3
    [reshape(m[i, :, :], (1, size(m)[2], size(m)[3])) for i in 1:3]
end
=#


"""
    function split_rgb(img::Array{UInt8,3})

Split input array in three channels.
"""
function split_rgb(img::Array{UInt8,3})
    @assert size(img)[1] == 3
    [img[i, :, :] for i in 1:3]
end
