using Random

function job()
    Random.seed!(0)
    out = rand(100000)
    println("Thread: ", Threads.threadid(), " out: ", out[end-2:end])
end

n_th = Threads.nthreads()
println()
@sync for i in 1:n_th
    Threads.@spawn begin
        job()
    end
end
