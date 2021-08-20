using Random

# Job to be parallelized
function job(mt)
    # Random.seed!(0)
    for i in 1:2
        println(i, " ", rand(mt))
    end
end

@sync for i in 1:Threads.nthreads()+1
    Threads.@spawn begin
        # Random.seed!(0)
        mt = MersenneTwister(0)
        job(mt)
    end
end


##

Random.seed!(0)
mt = MersenneTwister(0)
println(rand(mt))
println(rand(mt))
