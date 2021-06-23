export ReducingFunctions, get_centroids

module ReducingFunctions

# using OpenCV
using Statistics
using TiledIteration
using Images
using ImageMorphology

"""
    connected_components_features(x::Array{UInt8, 2}, n::Int64)

Given an image, return the centroids and the boxes areas of the `n` largest
connected components.
Fill with zeros if there are less than `n` components.
"""
function connected_components_features(x::Array{UInt8, 2}, n::Int64)
    labels = label_components(x)
    boxes = component_boxes(labels)
    centroids = component_centroids(labels)
    # popfirst!(centroids) # remove background centroid
    areas = [abs(b[1][1]-b[2][1]-1) * abs(b[1][2]-b[2][2]-1) for b in boxes]
    p = sortperm(areas, rev=true)
    centroids = centroids[p]
    areas = areas[p]
    c = fill((0.0, 0.0), n)
    a = fill(0, n)
    for i in eachindex(centroids)
        c[i] = centroids[i]
        a[i] = areas[i]
        if i == n
            break
        end
    end
    c_flat = collect(Iterators.flatten(c))
    a, c, c_flat
end

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
