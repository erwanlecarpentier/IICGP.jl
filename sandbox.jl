using ThreadPools

function heavy_task(n_iter::Float64)
    x = 1.0
    for _ in 1:n_iter
        x += rand()
    end
end

function mytask()
    println(Threads.threadid())
    heavy_task(1e10)
end

function mytask(i::Int64, j::Int64)
    n_max = 1e10
    n_iter = floor(rand() * n_max)
    println("$(Threads.threadid()) on $i $j for $n_iter")
    heavy_task(n_iter)
end

n = Threads.nthreads()

for k in 1:2 # Say we do two iterations
    println("Iteration $k")
    n_enco = 2
    n_cont = 2
    indexes = [(i, j) for i in 1:n_enco for j in 1:n_cont]
    Threads.@threads for l in 1:(n_enco + n_cont)
        i, j = indexes[l]
        mytask(i, j)
    end
end
