using Random

function job()
    Random.seed!(0)
    n = 10000
    out = Array{Float64,1}(undef, n)
    for i in 1:n
        out[i] = rand()
    end
    out
end

n_th = Threads.nthreads()
n_out = 2 * n_th
res = Array{Array{Float64,1},1}(undef, n_out)
println()
@sync for i in 1:n_out
    Threads.@spawn begin
        res[i] = job()
    end
end

all_same  = true
for i in eachindex(res)
    all_same *= res[i] == res[1]
end
println("All same: ", all_same)
