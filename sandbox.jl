using IICGP
using TiledIteration
using BenchmarkTools

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

function bar(x::X, y::Y) where {X <: Union{Float64, Int64}, Y <: Union{Float64, Int64}}
    x + y
end
function foo(x::X, y::X) where {X <: Union{Float64, Int64}}
    x + y
end


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
