global buffer
buffer = 0

function foo()
    global buffer
    buffer += 1
end

foo()
