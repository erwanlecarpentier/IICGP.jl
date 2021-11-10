using BenchmarkTools
using Random

function foo() # 40.461 μs (2 allocations: 78.20 KiB)
    n = 10000
    v = Vector{Float64}(undef, n)
    for i in eachindex(v)
        v[i] = rand()
    end
    v
end

function bar() # 35.241 μs (2 allocations: 78.20 KiB)
    n = 10000
    v = Vector{Float64}(undef, n)
    @inbounds for i in eachindex(v)
        v[i] = rand()
    end
    v
end
