using IICGP
using TiledIteration
using BenchmarkTools

## maxpool

function max_pool(img::Array{UInt8}; s::Int64=5)
    n_cols = s
    n_rows = s
    tile_width = convert(Int64, ceil(size(img)[2] / n_cols))
    tile_heigt = convert(Int64, ceil(size(img)[3] / n_rows))
    out = map(TileIterator(axes(img[1, :, :]), (tile_width, tile_heigt))) do tileaxs maximum(img[1, tileaxs...]) end
    reshape(out, 1, n_cols, n_rows)
end
inp = rand(collect(UInt8, 0:255), (1, 100, 100))
out = max_pool(inp)


IICGP.imshow(inp, 10.0)
IICGP.imshow(out, 100.0)

## distance between boxes and center
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

function motion_objects(x, x_p)
    diff = OpenCV.subtract(x, x_p)
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

out1 = motion_objects(r1, r2)
out2 = motion_distances_to_center(r1, r2)

IICGP.imshow(out1, 2)
IICGP.imshow(out2, 2)

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

##



foo(1, 2)
foo(1.0, 2.0)
foo(0.5, 2.5)
bar(1, 2.0)




function foobar(; kwargs...)
    kwargs_dict = Dict(kwargs)

    println("\ntypeof kwargs      : ", typeof(kwargs))
    println("typeof kwargs_dict : ", typeof(kwargs_dict))
    println("kwargs_dict        : ", kwargs_dict)
    println(haskey(kwargs_dict, :a))
end

foobar(a=1, b="hola")





function foobar(x, y=2*x)
    x + y
end
function bar(x, y=2*x)
    x + y
end

function foobar(x; kwargs...)
    kwargs_dict = Dict(kwargs)
    if haskey(kwargs_dict, :y)
        y = kwargs_dict[:y]
    else
        y = 2 * x
    end
    x + y
end

foobar(1, y=2)
foobar(1, 2)



struct foo
    a
    b
end

function bar(a, b; kwargs...)
    kwargs_dict = Dict(kwargs)
    if haskey(kwargs_dict, :buffer)
        a = kwargs_dict[:buffer]
    end
    foo(a, b)
end

function bar(a; kwargs...)
    b = a + 1
    bar(a, b, kwargs...)
end

bar(1)
bar(1, 3)
bar(1, 3; buffer=33)



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
