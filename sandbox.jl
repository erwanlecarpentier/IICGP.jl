## Load

using FileIO
using TiledIteration
using BenchmarkTools
using LinearAlgebra
# using OpenCV
using Plots
using Images
using ImageMorphology
using ImageShow
using ImageSegmentation
using IICGP

## Position-features from image

m1 = load_img("images/freeway_frame_30.png")
r1, g1, b1 = split_rgb(m1)

m2 = load_img("images/freeway_frame_31.png")
r2, g2, b2 = split_rgb(m2)


a1, c1, cf1 = IICGP.ReducingFunctions.connected_components_features(r1, 20)
a2, c2, cf2 = IICGP.ReducingFunctions.connected_components_features(r2, 20)

n = 15

plot_centroids(r1, c)

##

c_prev = c1
centroids = c2

p = zeros(Int64, length(centroids))
for i in eachindex(centroids)
    di = fill(Inf, length(c_prev))
    for j in eachindex(c_prev)
        dij = norm(centroids[i] .-  c_prev[j])
        di[j] = min(di[j], dij)
    end
    p[i] = argmin(di)
end


##

n_points = 100
w = [4, 0.7, -2.3]
σ(a) = 1 / (1 + exp(-a))
x_data = randn(n_points)
y_data = randn(n_points)
y_data[1:n_points÷2] .+= 8
labels = [round(σ(p'*w)) for p in eachrow([ones(n_points) x_data y_data])]
plt = scatter(x_data, y_data, zcolor=labels)
xs = range(-4, 3, length=100)
ys = range(-4, 11, length=100)
grid = [[1, x, y] for x in xs, y in ys]
heat = [σ(p'*w) for p in grid]
heatmap!(plt, xs, ys, heat, alpha=0.5)
# this doesn't look right

# now transpose and it does
plt = scatter(x_data, y_data, zcolor=labels)
heatmap!(plt, xs, ys, transpose(heat), alpha=0.5)

##

function CGPInd(n_in::Int64, d_fitness::Int64, nodes::Array{Node},
                outputs::Array{Int16}, arity_dict::Dict; kwargs...)::CGPInd
    R = 1
    C = length(nodes)
    all_nodes = Array{Node}(undef, n_in)
    p = Float64[]
    for i in 1:n_in
        all_nodes[i] = Node(0, 0, f_null, p, false)
    end
    push!(all_nodes, nodes...)
    arity_dict["f_null"] = 1
    two_arity = get_two_arity(all_nodes, arity_dict)
    active = find_active(all_nodes, outputs, two_arity)
    # Re-create nodes as they are immutable struct
    for i in eachindex(all_nodes)
        all_nodes[i] = Node(all_nodes[i].x, all_nodes[i].y, all_nodes[i].f,
                            all_nodes[i].p, active[i])
    end
    kwargs_dict = Dict(kwargs)
    # Use given input buffer or default to Array{Float64, 1} type
    if haskey(kwargs_dict, :buffer)
        buffer = kwargs_dict[:buffer]
    else
        buffer = zeros(R * C + n_in)
    end
    fitness = -Inf .* ones(d_fitness)
    n_out = length(outputs)
    n_parameters = length(nodes[1].p)
    chromosome = rand(R * C * (3 + n_parameters) + n_out)
    genes = reshape(chromosome[1:(R*C*(3+n_parameters))], R, C, 3+n_parameters)
    CGPInd(n_in, n_out, n_parameters, chromosome, genes, outputs,
           nodes, buffer, fitness)
end

##

ImgType = Array{UInt8,2}

## Julia maxpool

function max_pool_reduction(img::Array{UInt8,2}, s::Int64=5)
    outsz = (s, s)
    out = Array{eltype(img), ndims(img)}(undef, outsz)
    tilesz = ceil.(Int, size(img)./outsz)
    R = TileIterator(axes(img), tilesz)
    i = 1
    for tileaxs in R
       out[i] = maximum(view(img, tileaxs...))
       i += 1
    end
    return out
end

function max_pool_reduction2(img::Array{UInt8,2}, s::Int64=5)
    n_cols = s
    n_rows = s
    tile_width = convert(Int64, ceil(size(img)[1] / n_cols))
    tile_height = convert(Int64, ceil(size(img)[2] / n_rows))
    out = map(TileIterator(axes(img[:, :]), (tile_width, tile_height))) do tileaxs maximum(img[tileaxs...]) end
    reshape(out, n_cols, n_rows)
end

r1, g1, b1 = IICGP.load_rgb("freeway", 30)

out1 = max_pool_reduction(r1)
# 208.893 μs (1 allocation: 112 bytes)

out2 = max_pool_reduction2(r1)
# 174.697 μs (28 allocations: 136.19 KiB)

IICGP.implot(r1)

##

function rescale_uint_img(x::AbstractArray)::Array{UInt8}
    mini, maxi = minimum(x), maximum(x)
    if mini == maxi
        # return convert(Array{UInt8}, 127 * ones(size(x)))
        return UInt8.(x)
    end
    m = (convert(Array{Float64}, x) .- mini) .* (255 / (maxi - mini))
    floor.(UInt8, m)
end

r1, g1, b1 = IICGP.load_rgb("freeway", 30)

x = r1
y = g1

out1 = rescale_uint_img(Images.fastcorners(x))
out2 = rescale_uint_img(ImageFiltering.imfilter(x, Images.Kernel.gaussian(0)))
out3 = rescale_uint_img(ImageFiltering.imfilter(x, Images.Kernel.Laplacian()))
out4 = rescale_uint_img(ImageFiltering.imfilter(x, Images.Kernel.sobel()[2]))
out5 = rescale_uint_img(ImageFiltering.imfilter(x, Images.Kernel.sobel()[1]))
out6 = rescale_uint_img(Images.canny(x, (Images.Percentile(80), Images.Percentile(20)))))
out7 = rescale_uint_img(Images.imedge(x)[3])
out8 = ImageMorphology.opening(x)
out9 = ImageMorphology.closing(x)
out10= ImageMorphology.tophat(x)
out11= ImageMorphology.bothat(x)
out12= ImageMorphology.morphogradient(x)
out13= rescale_uint_img(ImageMorphology.morpholaplace(x))

IICGP.implot(x)
IICGP.implot(out13)

## Julia img subtract

function img_subtract1(x::Array{UInt8,2}, y::Array{UInt8,2})::Array{UInt8,2}
    z = zeros(UInt8, size(x))
    for i in eachindex(x)
        if x[i] > y[i]
            z[i] = x[i] - y[i]
        end
    end
    z
end

function img_subtract2(x::Array{UInt8,2}, y::Array{UInt8,2})::Array{UInt8,2}
    z = copy(x)
    for i in eachindex(z)
        if z[i] > y[i]
            z[i] -= y[i]
        else
            z[i] = 0
        end
    end
    z
end

function img_subtract3(x::Array{UInt8,2}, y::Array{UInt8,2})::Array{UInt8,2}
    x .- y
end

r1, g1, b1 = IICGP.load_rgb("freeway", 30)
r2, g2, b2 = IICGP.load_rgb("freeway", 31)

out1 = img_subtract1(r2, r1)
# 69.571 μs (2 allocations: 65.77 KiB)

out2 = img_subtract2(r2, r1)
# 70.559 μs (2 allocations: 65.77 KiB)

out3 = img_subtract3(r2, r1)
# 21.667 μs (2 allocations: 65.77 KiB)

@assert out1 == out2

IICGP.implot(r1)
IICGP.implot(r2)
IICGP.implot(out1)
IICGP.implot(out2)
IICGP.implot(out3)

## Julia motion capture

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

r1, g1, b1 = IICGP.load_rgb("freeway", 30)
r2, g2, b2 = IICGP.load_rgb("freeway", 31)
p = rand(1)

out1 = motion_capture!(r1, p)
IICGP.implot(out1)
@assert out1 == r1
@assert convert(Array{UInt8}, reshape(p, size(r1))) == r1

out2 = motion_capture!(r2, p)
# 250.899 μs (8 allocations: 197.39 KiB)
IICGP.implot(out2)
@assert out2 == r2 .- r1
@assert convert(Array{UInt8}, reshape(p, size(r2))) == r2

## Julia segmentation

function remove_details(x::ImgType, n_passes::Int64=1)::ImgType
    for i in 1:n_passes
        x = ImageMorphology.erode(x)
    end
    for i in 1:n_passes
        x = ImageMorphology.dilate(x)
    end
    x
end

"""
    rescale_img(x)::Array{UInt8}

Rescale input array in [0, 255] and convert data to UInt8.
"""
function rescale_img(x)::Array{UInt8}
    mini, maxi = minimum(x), maximum(x)
    m = (convert(Array{Float64}, x) .- mini) .* (255 / (maxi - mini))
    floor.(UInt8, m)
end

function felzenszwalb_segmentation(x, segment_size::Int64=50, min_size::Int64=10)
    segments = felzenszwalb(x, segment_size, min_size)
    rescale_img(segments.image_indexmap)
end

function components_segmentation(x)
    label = label_components(x)
    m = rescale_img(label)
    remove_details(m)
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
    rescale_img(boxes_img)
end

function box_segmentation(x::ImgType)::ImgType
    m = remove_details(x)
    label = label_components(m)
    make_boxes(label)
end

r1, g1, b1 = IICGP.load_rgb("freeway", 30)

out1 = remove_details(r1, 10)
# 311.636 μs (16 allocations: 131.72 KiB)

out2 = felzenszwalb_segmentation(r1, 100, 1)
# 22.131 ms (126980 allocations: 15.43 MiB)

out3 = components_segmentation(r1)
# 1.176 ms (76 allocations: 1.74 MiB)

out4 = box_segmentation(m)
# 2.013 ms (1236 allocations: 1.91 MiB)

out5 = make_boxes(r1)

IICGP.implot(r1)
IICGP.implot(out1)
IICGP.implot(out2)
IICGP.implot(out3)
IICGP.implot(out4)
IICGP.implot(out5)

## Julia matchTemplate function

m1 = load_img("montezuma_revenge", 30)
r1, g1, b1 = IICGP.split_rgb(m1)
m2 = load_img("montezuma_revenge", 31)
r2, g2, b2 = IICGP.split_rgb(m2)
# @btime img = r1[1,:,:]
# 67.606 μs (5 allocations: 65.84 KiB)
img = r1[1,:,:]

function match_template(img, threshold::Float64=700.0)
    tile_w = 10
    tile_h = 10
    match_img = zeros(size(img))
    incr = 1
    for t in TileIterator(axes(img), (tile_w, tile_h))
        template = img[t...]
        for u in TileIterator(axes(img), (tile_w, tile_h))
            if norm(template .- img[u...]) < threshold
                match_img[u...] .+= incr
                incr += 1
            end
        end
    end
    match_img .*= 255 / maximum(match_img)
    floor.(UInt8, match_img)
end

match_img = match_template(img, 700.0)
# 449.513 ms (1127761 allocations: 357.41 MiB)

IICGP.my_imshow(img)
IICGP.my_imshow(match_img, clim="auto")

## distance between boxes and center

# WITH JULIAIMAGES

function index1d_to_index2d_diy(x::AbstractArray, index::Int64)::Tuple{Int64,Int64}
    n_rows = size(x)[1]
    q, r = divrem(index, n_rows)
    if r == 0
        return n_rows, q
    else
        return r, q + 1
    end
end

function index1d_to_index2d(x::AbstractArray, index::Int64)::Tuple{Int64,Int64}
    ci = CartesianIndices(size(x))
    return ci[index][1], ci[index][2]
end

x = rand(700, 100)
for i in 1:length(x)
    r, c = index1d_to_index2d(x, i)
    @assert x[i] == x[r, c]
    r, c = index1d_to_index2d2(x, i)
    @assert x[i] == x[r, c]
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
        out = rescale_img(distances_img)
    else
        out = x
        resize!(p, length(p) + length(x))
    end
    p[end-length(x)+1:end] = x[:] # save first parameters
    return out
end

r1, g1, b1 = IICGP.load_rgb("freeway", 30)
r2, g2, b2 = IICGP.load_rgb("freeway", 31)
p = [0.999]

out1 = motion_distances!(r1, p)
@assert out1 == r1
@assert convert(Array{UInt8}, reshape(p[end-length(r1)+1:end], size(r1))) == r1

out2 = motion_distances!(r2, p)
# @assert out2 == dilate(r2 .- r1)
@assert convert(Array{UInt8}, reshape(p[end-length(r2)+1:end], size(r2))) == r2

IICGP.implot(out1)
IICGP.implot(out2)

## Connected components

# TODO

## Thresholding

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
        reverse = false
    else
        t = floor(UInt8, 255 * 2 * (p - 0.5))
        reverse = true
    end
    threshold(x, t, reverse)
end

r1, g1, b1 = IICGP.load_rgb("freeway", 30)
out = threshold(r1, 0.8)
IICGP.implot(r1)
IICGP.implot(out)

## Binary

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

r1, g1, b1 = IICGP.load_rgb("freeway", 30)
out = binary(r1, 0.75)
IICGP.implot(r1)
IICGP.implot(out)

## Negative

function negative(x::ImgType)::ImgType
    0xff .- x
end

r1, g1, b1 = IICGP.load_rgb("freeway", 30)
out = negative(r1)
IICGP.implot(r1)
IICGP.implot(out)

## Cambrian population initialization

"create all members of the first generation"
function initialize(itype::Type, cfg::NamedTuple; kwargs...)
    population = Array{itype}(undef, cfg.n_population)
    kwargs_dict = Dict(kwargs)
    for i in 1:cfg.n_population
        if haskey(kwargs_dict, :init_function)
            population[i] = kwargs_dict[:init_function](cfg)
        else
            population[i] = itype(cfg)
        end
    end
    population
end

## Function with complex default value

function foo(n::Int64; a::Array{Int64}=Array{Int64}(undef, n, 2*n))
    println(a) # Do whatever
end

n = 2
foo(2)  # Use default value
foo(2, a=Array{Int64}(undef, 3))  # use specific value

function foo(n::Int64; kwargs...)
    kwargs_dict = Dict(kwargs)
    if haskey(kwargs_dict, :a)
        a = kwargs_dict[:a]
    else
        a = Array{Int64}(undef, n, 2*n)  # default value of `a`
        # Notice that here, setting `a` to this default value could be several lines of code
    end
    println(a) # Do whatever
end

n = 2
foo(n, a=Array{Int64}(undef, 3))
foo(n)

## Passing a function as argument

function f()
    println("This is f")
end

function caller_noargs(x::Function)
    x()
end

caller_noargs(f)

## Apply some module's function based on string

module A
function foo1()
    println("Foo 1")
end
function foo2()
    println("Foo 2")
end
end

function bar(m::Module, l::Array{String})
    for s in l
        getfield(m, Symbol(s))()
    end
end

bar(A, ["foo1"])
bar(A, ["foo1", "foo2"])

## Motion capture with functor

function load_img(rom_name::String, frame_number::Int64)
    filename = string(@__DIR__, "/examples/images/", rom_name, "_frame_$frame_number.png")
    return OpenCV.imread(filename)
end

m1 = load_img("freeway", 30)
r1, g1, b1 = IICGP.split_rgb(m1)
m2 = load_img("freeway", 31)
r2, g2, b2 = IICGP.split_rgb(m2)



Base.@kwdef mutable struct MotionCapture
    state::Array{UInt8,3} = zeros(UInt8, (1, 320, 210))
end

function (o::MotionCapture)(img)
    if o.state == nothing
        diff = img
    else
        diff = OpenCV.subtract(img, o.state)
    end
    o.state = img
    return diff
end

f = MotionCapture()

# Apply it several times in a row
for i in 1:3
    out = f(r1)
    IICGP.imshow(out)
    out = f(r2)
    IICGP.imshow(out)
end

##
module A
function foo()
    println("Foo")
end
end

function foocaller()
    A.foo()
end

foocaller()

##


#=
using PkgTemplates

t = Template(;
    user="erwanlecarpentier",
    authors="Erwan Lecarpentier",
    julia=v"1.5.4",
    plugins=[
        Codecov(),
        Coveralls(),
        License(; name="MIT"),
        Git(; manifest=true, ssh=false),
    ],
)

# https://www.youtube.com/watch?v=QVmU29rCjaA&t=1356s
# 7:18

generate("JuliaSandbox", t)
=#
