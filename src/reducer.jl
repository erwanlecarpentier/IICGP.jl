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

"""
    PoolingReducer(f::Function, size::Int64)

Pooling reducer constructor.
"""
function PoolingReducer(f::Function, size::Int64)
    p = Dict("pooling_function"=>f, "size"=>size)
    Reducer(pooling_reduction, p)
end

"""
    CentroidReducer(n::Int64)

Centroid reducer constructor.
"""
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
    # popfirst!(centroids)  # remove largest
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
    pooling_reduction(x::Array{UInt8,2}, parameters::Dict)

Generic pooling function for several images (sequential application).
"""
function pooling_reduction(xs::Array{Array{UInt8,2},1}, parameters::Dict)
    fs = Array{Array{Float64,2},1}(undef, length(xs))
    for i in eachindex(xs)
        fs[i] = pooling_reduction(xs[i], parameters)
    end
    return fs
end

"""
    pooling_reduction(x::Array{UInt8,2}, parameters::Dict)

Generic pooling function for a single image.
"""
function pooling_reduction(x::Array{UInt8,2}, parameters::Dict)
    outsz = (parameters["size"], parameters["size"])
    # out = Array{eltype(x), ndims(x)}(undef, outsz)
    out = Array{Float64, ndims(x)}(undef, outsz)
    tilesz = ceil.(Int, size(x)./outsz)
    R = TileIterator(axes(x), tilesz)
    i = 1
    for tileaxs in R
       out[i] = parameters["pooling_function"](view(x, tileaxs...))
       i += 1
    end
    return out ./ 255.0
end
