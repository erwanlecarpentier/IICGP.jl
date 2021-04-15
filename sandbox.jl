
function foo(x::String="Ehoy"; kwargs...)
    println()
    println(x)
    println(typeof(kwargs))

    for (k, v) in kwargs
        println(k, " ", v)
    end

    return kwargs
end

out = foo(y=2, z="Hola")
println(out)

module AFoo
function foo()
    println("A foo")
end
end

module B
function foo()
    println("B foo")
end
end

function bar(m::Module)
    m.foo()
    println("Used module: ", string(:($m)))
end

bar(AFoo)
bar(B)
