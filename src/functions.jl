export CGPFunctions, ImgType

module CGPFunctions

using Images
using ImageMorphology
using ImageSegmentation
using LinearAlgebra

global arity = Dict()

SorX = Union{Symbol, Expr}
ImgType = Union{Array{UInt8,2}, Matrix{UInt8}}

function scaled(x::Float64)
    if isnan(x)
        return 0.0
    end
    min(max(x, -1.0), 1.0)
end

function fgen(name::Symbol, ar::Int, s1::SorX, iotype::U; safe::Bool=false) where {U <: Union{DataType, Union}}
    if safe
        @eval function $name(x::T, y::T, p::Array{Float64}=Float64[])::T where {T <: $(iotype)}
            try
                return $s1
            catch
                return x
            end
        end
    else
        @eval function $name(x::T, y::T, p::Array{Float64}=Float64[])::T where {T <: $(iotype)}
            $s1
        end
    end
    arity[String(name)] = ar
end

# Image processing

"""
    rescale_uint_img(x::AbstractArray)::Array{UInt8}

Rescale input array in [0, 255] and convert data to UInt8.
"""
function rescale_uint_img(x::AbstractArray)::Array{UInt8}
    mini, maxi = minimum(x), maximum(x)
    if mini == maxi
        return floor.(UInt8, mod.(x, 255))
    end
    m = (convert(Array{Float64}, x) .- mini) .* (255 / (maxi - mini))
    floor.(UInt8, m)
end

function remove_details(x::ImgType, p::Float64)::ImgType
    n_passes = ceil(Int64, 5 * p)
    remove_details(x, n_passes)
end

function remove_details(x::ImgType, n_passes::Int64)::ImgType
    for i in 1:n_passes
        x = ImageMorphology.erode(x)
    end
    for i in 1:n_passes
        x = ImageMorphology.dilate(x)
    end
    x
end

function felzenszwalb_segmentation(x::ImgType, p::Float64)::ImgType
    min_size = floor(Int64, 10 * p)
    segments = ImageSegmentation.felzenszwalb(x, 50, min_size)
    rescale_uint_img(segments.image_indexmap)
end

function components_segmentation(x::ImgType)::ImgType
    label = label_components(x)
    m = rescale_uint_img(label)
    remove_details(m, 1) # more passes?
end

function make_boxes(x::AbstractArray)::ImgType
    labels = label_components(x)
    boxes = component_boxes(labels)
    # Filter error boxes reaching typemax(Int64) or typemin(Int64)
    #=
    to_remove = Int64[]
    maxi = maximum(size(x))
    for i in eachindex(boxes)
        if any(boxes[i][1] .< 0) || any(boxes[i][2] .< 0) || any(boxes[i][1] .> maxi) || any(boxes[i][2] .> maxi)
            push!(to_remove, i)
        end
    end
    deleteat!(boxes, to_remove)
    =#
    # Compute areas and sort boxes
    areas = zeros(length(boxes))
    for i in eachindex(boxes)
        areas[i] = abs(boxes[i][1][1] - boxes[i][2][1]) * abs(boxes[i][1][2] - boxes[i][2][2])
    end
    boxes = reverse(boxes[sortperm(areas)])
    boxes_img = zeros(Int64, size(x))
    incr = 1
    for i in 2:length(boxes)
        boxes_img[
            boxes[i][1][1]:boxes[i][2][1],
            boxes[i][1][2]:boxes[i][2][2]
        ] .+= incr
        incr += 1
    end
    rescale_uint_img(boxes_img)
end

function box_segmentation(x::ImgType)::ImgType
    m = remove_details(x, 1) # more passes?
    label = label_components(m)
    make_boxes(label)
end

#=
function binary(x::ImgType, t::UInt8)::ImgType
    out = copy(x)
    out[x .< t] .= 0x00
    out[x .>= t] .= 0xff
    out
end

function binary(x::ImgType, t::Int64)::ImgType
    binary(x, convert(UInt8, t))
end

function binary(x::ImgType, p::Float64)::ImgType
    t = floor(UInt8, 255 * p)
    binary(x, t)
end
=#

function binary(x::ImgType, p::Float64)::ImgType
    reshape([x[i] < floor(UInt8, 255 * p) ? 0x00 : 0xff for i in eachindex(x)], size(x))
end

#=
function threshold(x::ImgType, t::UInt8, reverse::Bool=false)::ImgType
    out = copy(x)
    if reverse
        out[x .> t] .= 0x00
    else
        out[x .< t] .= 0x00
    end
    out
end

function threshold(x::ImgType, t::Int64)::ImgType
    threshold(x, convert(UInt8, t))
end

function threshold(x::ImgType, p::Float64)::ImgType
    if p < 0.5
        t = floor(UInt8, 255 * 2 * p)
        threshold(x, t, false)
    else
        t = floor(UInt8, 255 * 2 * (p - 0.5))
        threshold(x, t, true)
    end
end
=#

function threshold(x::ImgType, t::UInt8, reverse::Bool=false)::ImgType
    reshape([reverse ? (x[i]>t ? 0x00 : x[i]) : (x[i]<t ? 0x00 : x[i]) for i in eachindex(x)], size(x))
end

function threshold(x::ImgType, p::Float64)::ImgType
    if p < 0.5
        t = floor(UInt8, 255 * 2 * p)
        threshold(x, t, false)
    else
        t = floor(UInt8, 255 * 2 * (p - 0.5))
        threshold(x, t, true)
    end
end

function index1d_to_index2d(x::AbstractArray, index::Int64)::Tuple{Int64,Int64}
    ci = CartesianIndices(size(x))
    return ci[index][1], ci[index][2]
end

function motion_capture!(x::ImgType, p::Array{Float64})::ImgType
    if length(p) == length(x)
        out = x .- convert(Array{UInt8}, reshape(p, size(x)))
    else
        out = x
        resize!(p, length(x))
    end
    p[:] = x[:]
    return out
end

function motion_distances!(x::ImgType, p::Array{Float64})::ImgType
    if length(p) >= length(x)
        diff = x .- convert(Array{UInt8}, reshape(p[end-length(x)+1:end], size(x)))
        dilated = dilate(diff)
        binarized = binary(dilated, 3)
        labels = label_components(binarized)
        centroids = component_centroids(labels)
        popfirst!(centroids) # remove background centroid
        # boxes = component_boxes(labels)
        # Find reference point
        index1d = max(convert(Int64, ceil(p[1] * length(x))), 1)
        r, c = index1d_to_index2d(x, index1d)
        # Compute distances
        n_centroids = length(centroids)
        distances = zeros(n_centroids)
        for i in 1:n_centroids
            distances[i] = norm(centroids[i] .- (r, c))
        end
        distances_img = zeros(size(x))
        for i in eachindex(distances_img)
            if labels[i] > 0
                distances_img[i] = distances[labels[i]]
            end
        end
        out = rescale_uint_img(distances_img)
    else
        out = x
        resize!(p, length(p) + length(x))
    end
    p[end-length(x)+1:end] = x[:] # save first parameters
    return out
end


fgen(:f_dilate, 1, :(ImageMorphology.dilate(x)), ImgType)
fgen(:f_erode, 1, :(ImageMorphology.erode(x)), ImgType)
fgen(:f_subtract, 2, :(x .- y), ImgType)
fgen(:f_remove_details, 1, :(remove_details(x, p[1])), ImgType)
fgen(:f_make_boxes, 1, :(make_boxes(x)), ImgType)
# Segmentation
fgen(:f_felzenszwalb_segmentation, 1, :(felzenszwalb_segmentation(x, p[1])), ImgType)
fgen(:f_components_segmentation, 1, :(components_segmentation(x)), ImgType)
fgen(:f_box_segmentation, 1, :(box_segmentation(x)), ImgType)
# Thresholds and values
# fgen(:f_negative, 1, :(0xff .- x), ImgType) # Same as f_bitwise_not
fgen(:f_threshold, 1, :(threshold(x, p[1])), ImgType)
fgen(:f_threshold_bis, 1, :(threshold_bis(x, p[1])), ImgType)
fgen(:f_binary, 1, :(binary(x, p[1])), ImgType)
fgen(:f_motion_capture, 1, :(motion_capture!(x, p)), ImgType)
fgen(:f_motion_distances, 1, :(motion_distances!(x, p)), ImgType)
# Filtering
fgen(:f_corners, 1, :(rescale_uint_img(Images.fastcorners(x))), ImgType)
fgen(:f_gaussian, 1, :(rescale_uint_img(ImageFiltering.imfilter(x, Images.Kernel.gaussian(ceil(Int64, 5 * p[1]))))), ImgType)
fgen(:f_laplacian, 1, :(rescale_uint_img(ImageFiltering.imfilter(x, Images.Kernel.Laplacian()))), ImgType)
fgen(:f_sobel_x, 1, :(rescale_uint_img(ImageFiltering.imfilter(x, Images.Kernel.sobel()[2]))), ImgType)
fgen(:f_sobel_y, 1, :(rescale_uint_img(ImageFiltering.imfilter(x, Images.Kernel.sobel()[1]))), ImgType)
fgen(:f_canny, 1, :(rescale_uint_img(Images.canny(x, (Images.Percentile(80), Images.Percentile(20))))), ImgType)
fgen(:f_edges, 1, :(rescale_uint_img(Images.imedge(x)[3])), ImgType)
# Morphological functions
fgen(:f_opening, 1, :(ImageMorphology.opening(x)), ImgType)
fgen(:f_closing, 1, :(ImageMorphology.closing(x)), ImgType)
fgen(:f_tophat, 1, :(ImageMorphology.tophat(x)), ImgType)
fgen(:f_bothat, 1, :(ImageMorphology.bothat(x)), ImgType)
fgen(:f_morphogradient, 1, :(ImageMorphology.morphogradient(x)), ImgType)
fgen(:f_morpholaplace, 1, :(rescale_uint_img(ImageMorphology.morpholaplace(x))), ImgType)
# Bitwise operations
fgen(:f_bitwise_not, 1, :(.~x), ImgType)
fgen(:f_bitwise_and, 2, :(0xff .* (x .& y)), ImgType)
fgen(:f_bitwise_or, 2, :(0xff .* (x .| y)), ImgType)
fgen(:f_bitwise_xor, 2, :(0xff .* (x .⊻ y)), ImgType)
# fgen(:f_compare_eq_img, 2, :(OpenCV.compare(x, y, OpenCV.CMP_EQ)), OpenCV.InputArray)
# fgen(:f_compare_ge_img, 2, :(OpenCV.compare(x, y, OpenCV.CMP_GE)), OpenCV.InputArray)
# fgen(:f_compare_le_img, 2, :(OpenCV.compare(x, y, OpenCV.CMP_LE)), OpenCV.InputArray)

# Mathematical

fgen(:f_add, 2, :((x + y) / 2.0), Float64)
fgen(:f_subtract, 2, :(abs(x - y) / 2.0), Float64)
fgen(:f_mult, 2, :(x * y), Float64)
fgen(:f_div, 2, :(scaled(x / y)), Float64)
fgen(:f_abs, 1, :(abs(x)), Float64)
fgen(:f_sqrt, 1, :(sqrt(abs(x))), Float64)
fgen(:f_pow, 2, :(abs(x) ^ abs(y)), Float64)
fgen(:f_exp, 1, :((2 * (exp(x+1)-1.0))/(exp(2.0)-1.0) -1), Float64)
fgen(:f_sin, 1, :(sin(x)), Float64)
fgen(:f_cos, 1, :(cos(x)), Float64)
fgen(:f_tanh, 1, :(tanh(x)), Float64)
fgen(:f_sqrt_xy, 2, :(sqrt(x^2 + y^2) / sqrt(2.0)), Float64)
fgen(:f_lt, 2, :(Float64(x < y)), Float64)
fgen(:f_gt, 2, :(Float64(x > y)), Float64)

# Logical
fgen(:f_and, 2, :(Float64((&)(Int(round(x)), Int(round(y))))), Float64)
fgen(:f_or, 2, :(Float64((|)(Int(round(x)), Int(round(y))))), Float64)
fgen(:f_xor, 2, :(Float64(xor(Int(abs(round(x))), Int(abs(round(y)))))), Float64)
fgen(:f_not, 1, :(1 - abs(round(x))), Float64)

end
