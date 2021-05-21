export load_img, save_img, split_rgb

using Images

"""
    function load_img(filename::String)

Load an image given file name.
"""
function load_img(filename::String)
    img = FileIO.load(filename)
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
    filename = string(@__DIR__, "/../images/", rom_name, "_frame_$frame_number.png")
    split_rgb(load_img(filename))
end

"""
    function save_img(img::Array{Float64,2}, filename::String)

Save an image to the input path.
"""
function save_img(img::Array{Float64}, filename::String)
    n_dims = ndims(img)
    if n_dims == 2
        FileIO.save(filename, colorview(Gray, img))
    elseif n_dims == 3
        FileIO.save(filename, colorview(RGB, img))
    else
        println("Warning: `save_img` image dimension is $n_dims - not saving")
    end
end

"""
    function save_img(img::Array{UInt8,2}, filename::String)

Save an image to the input path.
"""
function save_img(img::Array{UInt8}, filename::String)
    mini, maxi = minimum(img), maximum(img)
    img = Float64.(img)
    if mini != maxi
        img = adjust_histogram(img, LinearStretching())
    end
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
