
module A
function foo()
    println("A.foo()")
end
end

module B
function foo()
    println("B.foo()")
end
end

function bar(m::Module)
    m.foo()
end

bar(A)
bar(B)

function foo(x::T, y::T) where {T <: Union{Int64, Int32}}
    x + y
end

function bar(f::Function)
    println(f)
end



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
