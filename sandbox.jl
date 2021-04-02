# global buffer
# buffer = 0

function foo()
    if @isdefined buffer
        global buffer
        buffer += 1
    else
        global buffer
        buffer = 1
    end
end

foo()
