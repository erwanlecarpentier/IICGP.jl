export ReducingFunctions

module ReducingFunctions

# using OpenCV
using Statistics
using TiledIteration

#=
function nearest_reduction(m::T; s::Int64=5) where {T <: OpenCV.InputArray}
    # dsize = OpenCV.Size(convert(Int32, s), convert(Int32, s))
    return OpenCV.resize(m, OpenCV.Size(convert(Int32, s), convert(Int32, s)),
                         m, 1.0, 1.0, OpenCV.INTER_NEAREST)
end

function linear_reduction(m::T; s::Int64=5) where {T <: OpenCV.InputArray}
    # dsize = OpenCV.Size(convert(Int32, s), convert(Int32, s))
    return OpenCV.resize(m, OpenCV.Size(convert(Int32, s), convert(Int32, s)),
                         m, 1.0, 1.0, OpenCV.INTER_LINEAR)
end

function area_reduction(m::T; s::Int64=5) where {T <: OpenCV.InputArray}
    # dsize = OpenCV.Size(convert(Int32, s), convert(Int32, s))
    return OpenCV.resize(m, OpenCV.Size(convert(Int32, s), convert(Int32, s)),
                         m, 1.0, 1.0, OpenCV.INTER_AREA)
end

function cubic_reduction(m::T; s::Int64=5) where {T <: OpenCV.InputArray}
    # dsize = OpenCV.Size(convert(Int32, s), convert(Int32, s))
    return OpenCV.resize(m, OpenCV.Size(convert(Int32, s), convert(Int32, s)),
                         m, 1.0, 1.0, OpenCV.INTER_CUBIC)
end

function lanczos_reduction(m::T; s::Int64=5) where {T <: OpenCV.InputArray}
    # dsize = OpenCV.Size(convert(Int32, s), convert(Int32, s))
    return OpenCV.resize(m, OpenCV.Size(convert(Int32, s), convert(Int32, s)),
                         m, 1.0, 1.0, OpenCV.INTER_LANCZOS4)
end
=#

"""
    max_pool_reduction(img::Array{UInt8,2}, s::Int64=5)

Max pooling function.
"""
function max_pool_reduction(img::Array{UInt8,2}, s::Int64=5)
    outsz = (s, s)
    # out = Array{eltype(img), ndims(img)}(undef, outsz)
    out = Array{Float64, ndims(img)}(undef, outsz)
    tilesz = ceil.(Int, size(img)./outsz)
    R = TileIterator(axes(img), tilesz)
    i = 1
    for tileaxs in R
       out[i] = maximum(view(img, tileaxs...))
       i += 1
    end
    return out ./ 255.0
end

"""
    min_pool_reduction(img::Array{UInt8,2}, s::Int64=5)

Min pooling function.
"""
function min_pool_reduction(img::Array{UInt8,2}, s::Int64=5)
    outsz = (s, s)
    # out = Array{eltype(img), ndims(img)}(undef, outsz)
    out = Array{Float64, ndims(img)}(undef, outsz)
    tilesz = ceil.(Int, size(img)./outsz)
    R = TileIterator(axes(img), tilesz)
    i = 1
    for tileaxs in R
       out[i] = minimum(view(img, tileaxs...))
       i += 1
    end
    return out ./ 255.0
end

"""
    mean_pool_reduction(img::Array{UInt8,2}, s::Int64=5)

Mean pooling function.
"""
function mean_pool_reduction(img::Array{UInt8,2}, s::Int64=5)
    outsz = (s, s)
    # out = Array{eltype(img), ndims(img)}(undef, outsz)
    out = Array{Float64, ndims(img)}(undef, outsz)
    tilesz = ceil.(Int, size(img)./outsz)
    R = TileIterator(axes(img), tilesz)
    i = 1
    for tileaxs in R
       out[i] = Statistics.mean(view(img, tileaxs...))
       i += 1
    end
    return out ./ 255.0
end

function max_pool_reduction2(img::Array{UInt8,2}, s::Int64=5)
    n_cols = s
    n_rows = s
    tile_width = convert(Int64, ceil(size(img)[1] / n_cols))
    tile_height = convert(Int64, ceil(size(img)[2] / n_rows))
    out = map(TileIterator(axes(img[:, :]), (tile_width, tile_height))) do tileaxs maximum(img[tileaxs...]) end
    reshape(out, n_cols, n_rows)
end

function max_pool_reduction_threads(m::AbstractArray, s::Int64=5)
    outsz = (size(m, 1), ntuple(_->s, ndims(m) - 1)...)
    out = Array{eltype(m), ndims(m)}(undef, outsz)
    tilesz = ceil.(Int, size(m)./outsz)
    R = TileIterator(axes(m), tilesz)
    Threads.@threads for i in eachindex(R)
       @inbounds out[i] = maximum(view(m, R[i]...))
    end
    return out
end

end
