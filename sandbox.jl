### MWE for assignment of fitnesses in population

using Random

struct Bar
    v::Array{Float64}
end

mutable struct Foo
    bar_vec::Array{Bar}
end

Bar() = Bar([-Inf]) # Default constructor with a length one vector of -Inf
Foo() = Foo([Bar() for _ in 1:3]) # Default constructor with 3 Bar

function evaluate(foo::Foo)
    nbar = length(foo.bar_vec)
    values = Array{Float64}(undef, nbar, nbar)
    @sync for i in 1:nbar
        for j in 1:nbar
            Threads.@spawn begin
                values[i,j] = rand() + i
            end
        end
    end

    println("values: ")
    for i in 1:nbar
        println(values[i,:])
    end

    for i in eachindex(foo.bar_vec)
        foo.bar_vec[i].v[1] = maximum(values[i,:])

        println("\nsetting ", values[i], " for bar ", i)
        println("bar fitnesses are:")
        for bar in foo.bar_vec
            println(bar.v)
        end
    end
end

f = Foo()
for _ in 1:10
    evaluate(f)
    println("-"^100)
end



##
### MWE for multithreading with same RNG / seeding

using Random

# Job to be parallelized, each thread using the same random numbers sequence
function job()
    # Random.seed!(0) # Does not work
    mt = MersenneTwister(0) # Does work
    for i in 1:2
        println("Random number n° $i in the sequence = $(rand(mt))")
    end
end

@sync for i in 1:Threads.nthreads()+1
    Threads.@spawn begin
        job()
    end
end
