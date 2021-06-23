export Reducer, PoolingReducer, CentroidReducer

# using OpenCV
using Statistics
using TiledIteration
using Hungarian
using Images
using ImageMorphology
using LinearAlgebra

abstract type AbstractReducer end

struct Reducer <: AbstractReducer
    reduct::Function
    parameters::Dict
end

function PoolingReducer(f::Function, size::Int64)
    p = Dict("pooling_function"=>f, "size"=>size)
    Reducer(pooling_reduction, p)
end

function CentroidReducer(n::Int64)
    p = Dict(
        "n"=>n,
        "c_prev"=>Tuple{Float64,Float64}[],
        "a_prev"=>Int64[]
    )
    Reducer(centroid_reduction, p)
end

"""
    reorder_features(
        c1::Array{Tuple{Float64,Float64},1},
        a1::Array{Int64,1},
        c2::Array{Tuple{Float64,Float64},1},
        a2::Array{Int64,1}
    )

Reorder the features contained in c2, a2 by making a best match with c1, a1.
"""
function reorder_features(
    c1::Array{Tuple{Float64,Float64},1},
    a1::Array{Int64,1},
    c2::Array{Tuple{Float64,Float64},1},
    a2::Array{Int64,1}
)
    weights = zeros(length(c1), length(c1))
    for i in eachindex(c1)
        for j in eachindex(c2)
            weights[i, j] = norm(c1[i] .- c2[j]) + abs(a1[i] - a2[j])
        end
    end
    assignment, cost = hungarian(weights)  # 5.680 μs (40 allocations: 5.44 KiB)
    a2[assignment], c2[assignment]
end

"""
    centroid_reduction(x::Array{UInt8, 2}, parameters::Dict)

Given an image, return the centroids and the boxes areas of the `n` largest
connected components, `n` being defined in the parameters dictionary.
Fill with zeros if there are less than `n` components.
"""
function centroid_reduction(x::Array{UInt8, 2}, parameters::Dict)
    n = parameters["n"]
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
    if length(parameters["c_prev"]) > 0
        a, c = reorder_features(parameters["c_prev"], parameters["a_prev"], c, a)
    end
    println(parameters["a_prev"])
    parameters["a_prev"] = a
    parameters["c_prev"] = c
    c_flat = collect(Iterators.flatten(c))
    c_flat
end

"""
    pooling_reduction(img::Array{UInt8,2}, parameters::Dict)

Generic pooling function.
"""
function pooling_reduction(img::Array{UInt8,2}, parameters::Dict)
    outsz = (parameters["size"], parameters["size"])
    # out = Array{eltype(img), ndims(img)}(undef, outsz)
    out = Array{Float64, ndims(img)}(undef, outsz)
    tilesz = ceil.(Int, size(img)./outsz)
    R = TileIterator(axes(img), tilesz)
    i = 1
    for tileaxs in R
       out[i] = parameters["pooling_function"](view(img, tileaxs...))
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
