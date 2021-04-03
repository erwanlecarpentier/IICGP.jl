using BenchmarkTools


# global buffer
# buffer = 0

function foobar()
    if @isdefined foobar_buffer
        global foobar_buffer
        foobar_buffer += 1
    else
        global buffer
        foobar_buffer = 1
    end
end

foobar()

@btime foobar()



f(state=0) = ()->state+=1


let state = Ref{Union{Int, Nothing}}(nothing)
    global bar
    function bar()
        if state[] !== nothing
            state[] += 1
        else
            state[] = 1
        end
        state[]
    end
 end

Base.@kwdef mutable struct F
    state = nothing
end

function (o::F)()
    if o.state == nothing
        o.state = 1
    else
        o.state += 1
    end
end
fi = F()
