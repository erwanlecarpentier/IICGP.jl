using IICGP
using TiledIteration
using BenchmarkTools

## maxpool

function max_pool(img::Array{UInt8}; s::Int64=5)
    n_cols = s
    n_rows = s
    tile_width = convert(Int64, ceil(size(img)[2] / n_cols))
    tile_height = convert(Int64, ceil(size(img)[3] / n_rows))
    out = map(TileIterator(axes(img[1, :, :]), (tile_width, tile_height))) do tileaxs maximum(img[1, tileaxs...]) end
    reshape(out, 1, n_cols, n_rows)
end
inp = rand(collect(UInt8, 0:255), (1, 100, 100))
out = max_pool(inp)


IICGP.imshow(inp, 10.0)
IICGP.imshow(out, 100.0)

## Julia matchTemplate function

using TiledIteration

function load_img(rom_name::String, frame_number::Int64)
    filename = string(@__DIR__, "/examples/images/", rom_name, "_frame_$frame_number.png")
    return OpenCV.imread(filename)
end

m1 = load_img("montezuma_revenge", 30)
r1, g1, b1 = IICGP.split_rgb(m1)
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

my_imshow(img)
my_imshow(match_img, clim="auto")


## distance between boxes and center
using IICGP
using LinearAlgebra
using OpenCV
using ImageMorphology
using BenchmarkTools
using Plots
using Images
using ImageShow

function load_img(rom_name::String, frame_number::Int64)
    filename = string(@__DIR__, "/examples/images/", rom_name, "_frame_$frame_number.png")
    return OpenCV.imread(filename)
end

m1 = load_img("freeway", 30)
r1, g1, b1 = IICGP.split_rgb(m1)
m2 = load_img("freeway", 31)
r2, g2, b2 = IICGP.split_rgb(m2)

# WITH JULIAIMAGES

# Same as OpenCV.subtract
function my_subtract(x, y)
    z = zeros(UInt8, size(x))
    for i in eachindex(x[1,:,1])
        for j in eachindex(x[1,1,:])
            if x[1,i,j] > y[1,i,j]
                z[1,i,j] = x[1,i,j] - y[1,i,j]
            end
        end
    end
    z
end

function disprange(m)
    k = m[1, 300:310, 25:35]
    convert(Array{Int64}, k)
end

function img_threshold(x, threshold=1)
    y = zeros(UInt8, size(x))
    for i in eachindex(x[1,:,1])
        for j in eachindex(x[1,1,:])
            if x[1,i,j] >= threshold
                y[1,i,j] = 255
            end
        end
    end
    y
end

function motion_distances_to_center_julia(x, x_p)
    diff = my_subtract(x_p, x)
    dilated = dilate(diff)
    thresholded = img_threshold(dilated)
    label = label_components(thresholded)
    centroids = component_centroids(label)
    # boxes = component_boxes(label)
    center = collect(size(x)[2:3] ./ 2)
    max_distance = norm(center)
    n_labels = length(centroids)
    distances_to_center = zeros(UInt8, n_labels)
    for i in 1:n_labels
        distances_to_center[i] = floor(255 * norm(collect(centroids[i][2:3]) - center) / max_distance)
    end
    distances_to_center_img = zeros(UInt8, size(label))
    for i in eachindex(label[1, :, 1])
        for j in eachindex(label[1, 1, :])
            distances_to_center_img[1, i, j] = distances_to_center[label[1, i, j] + 1]
        end
    end
    distances_to_center_img
end

function motion_objects_julia(x, x_p)
    diff = my_subtract(x_p, x)
    dilated = dilate(diff)
    thresholded = img_threshold(dilated)
    thresholded
end

function motion_boxes_julia(x, x_p)
    diff = my_subtract(x_p, x)
    dilated = dilate(diff)
    thresholded = img_threshold(dilated)
    label = label_components(thresholded)
    boxes = component_boxes(label)
    boxes_img = zeros(UInt8, size(x))
    for i in 2:length(boxes)
        boxes_img[
            1,
            boxes[i][1][2]:boxes[i][2][2],
            boxes[i][1][3]:boxes[i][2][3]
        ] .= 255
    end
    boxes_img
end



# WITH OPENCV
function motion_objects(x, x_p)
    diff = OpenCV.subtract(x_p, x)
    dilated = OpenCV.dilate(
        diff,
        OpenCV.getStructuringElement(
            OpenCV.MORPH_ELLIPSE,
            OpenCV.Size{Int32}(8, 8)
        )
    )
    n_labels, labels_img, stats, centroids = OpenCV.connectedComponentsWithStats(dilated)
    # Compute colored_labels_img
    colored_labels_img = zeros(UInt8, size(labels_img))
    norm = convert(UInt8, floor(255 / (n_labels - 1)))
    for i in eachindex(labels_img[1, :, 1])
        for j in eachindex(labels_img[1, 1, :])
            colored_labels_img[1, i, j] = labels_img[1, i, j] * norm
        end
    end
    return colored_labels_img
end

function motion_distances_to_center(x, x_p)
    diff = OpenCV.subtract(x, x_p)
    dilated = OpenCV.dilate(
        diff,
        OpenCV.getStructuringElement(
            OpenCV.MORPH_ELLIPSE,
            OpenCV.Size{Int32}(8, 8)
        )
    )
    n_labels, labels_img, stats, centroids = OpenCV.connectedComponentsWithStats(dilated)
    # Compute distances_to_center_img
    center = collect(size(x)[2:3] ./ 2)
    max_distance = norm(center)
    distances_to_center_img = zeros(UInt8, size(labels_img))
    distances_to_center = zeros(UInt8, n_labels)
    for i in 1:n_labels
        distances_to_center[i] = floor(255 * norm(centroids[1,:,i] - center) / max_distance)
    end
    for i in eachindex(labels_img[1, :, 1])
        for j in eachindex(labels_img[1, 1, :])
            distances_to_center_img[1, i, j] = distances_to_center[labels_img[1, i, j] + 1]
        end
    end
    return distances_to_center_img
end

# out3 = motion_objects(r1, r2)

out1 = motion_distances_to_center_julia(r1, r2)
# 1.542 ms (1054 allocations: 1.52 MiB)
out2 = motion_distances_to_center(r1, r2)
# 17.729 ms (71044 allocations: 2.52 MiB)

out3 = motion_objects_julia(r1, r2)
# 546.036 μs (656 allocations: 388.33 KiB)

out4 = motion_boxes_julia(r1, r2)
# 1.951 ms (883 allocations: 992.11 KiB)

my_imshow(out1)
my_imshow(out2)
my_imshow(out3)
my_imshow(out4)

## Connected components

# TODO

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

## Maximum row/col wise

a = [
    1.0 2.0 3.0 0.0;
    4.0 5.0 6.0 0.0;
    7.0 8.0 9.0 0.0
]



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

using IICGP
using OpenCV
using LinearAlgebra

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
