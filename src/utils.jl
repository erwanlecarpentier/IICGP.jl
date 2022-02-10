export load_img, save_img, split_rgb, to_csv_row
export int2dnaid, dict2namedtuple, namedtuple2dict

using Images

int2dnaid(i::Int64) = Formatting.format("{1:04d}", i)

dict2namedtuple(d::Dict) = (; (Symbol(k)=>v for (k, v) in d)...)
namedtuple2dict(nt::NamedTuple) = Dict(pairs(nt))

function to_csv_row(v::AbstractArray, sep::String)
    string(
        [i == length(v) ?
        string(v[i], "\n") :
        string(v[i], sep)
        for i in eachindex(v)]...
    )
end

"""
    load_img(filename::String)

Load an image given file name.
"""
function load_img(filename::String)
    img = FileIO.load(filename)
    convert(Array{UInt8}, rawview(channelview(img)))
end

"""
    load_img(filename::String)

Load a pre-saved Atari image given ROM name and frame number.
"""
function load_img(rom_name::String, frame_number::Int64)
    filename = string(@__DIR__, "/../images/", rom_name, "_frame_30.png")
    load_img(filename)
end

"""
    load_rgb(rom_name::String, frame_number::Int64)

Load a pre-saved Atari image given ROM name and frame number.
Return an array containing the separated chanels.
"""
function load_rgb(rom_name::String, frame_number::Int64)
    filename = string(@__DIR__, "/../images/", rom_name, "_frame_$frame_number.png")
    split_rgb(load_img(filename))
end

"""
    save_img(img::Array{Float64,2}, filename::String)

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
    save_img(img::Array{UInt8,2}, filename::String)

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

"""
    split_rgb(img::Array{UInt8,3})

Split input array in three channels.
"""
function split_rgb(img::Array{UInt8,3})
    @assert size(img)[1] == 3
    [img[i, :, :] for i in 1:3]
end
