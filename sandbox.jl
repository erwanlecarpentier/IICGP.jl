bar(x::Int64, y::Int64) = x + y

function foobar(n::Int64=3)
    for i in 1:n
        println(bar(i, i))
    end
end
