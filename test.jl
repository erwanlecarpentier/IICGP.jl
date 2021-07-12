# using Distributed
using BenchmarkTools
using ImageSegmentation

function remote_computation()
    thid = Threads.threadid()
    println("Remote computation with thread $thid")
    for i in 1:50
        felzenszwalb(img, 0.5)
    end
    rand()
end

function remote_computation_mwe()
   thid = Threads.threadid()
   println("Remote computation with thread $thid")
   start = rand();
   for i in 1:10000000
      start += 1.0
   end
   return start
end

function remote_computation_sleep()
    thid = Threads.threadid()
    println("Remote computation with thread $thid")
    sleep(5)  # Long computation: to be parallelized
    # (usually I would put some real computation here but for reproducibility I used sleep)
    rand()
end

##

img = convert(Array{UInt8}, ceil.(255*rand(200,300)))

for t in 1:10  # Say we want to do the full parallelized process 10 times
    results_matrix = zeros(2,2)
    tasks_matrix = Array{Task,2}(undef,2,2)
    @sync for i in 1:2
        for j in 1:2
            # tasks_matrix[i,j] =
            Threads.@spawn begin
                results_matrix[i, j] = remote_computation()
            end
        end
    end
    #=
    for i in 1:2
        for j in 1:2
            wait(tasks_matrix[i,j])
        end
    end
    =#
    @assert all(r -> typeof(r) == Float64, results_matrix)
    println("Completed parallelized process number: $t")
    println(results_matrix)
end
