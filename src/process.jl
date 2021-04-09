export process

using OpenCV
using CartesianGeneticProgramming

function set_inputs(ind::CGPInd, inputs::Array{T})::Nothing where {T <:OpenCV.InputArray}
    for i in eachindex(inputs)
        ind.buffer[i] = inputs[i]
    end
end

function get_outputs(ind::CGPInd)::T where {T <:OpenCV.InputArray}
    # doesn't re-process, just gives outputs
    # TODO
    """
    outputs = Array{Float64}(undef, length(ind.outputs))
    for i in eachindex(outputs)
        outputs[i] = ind.buffer[ind.outputs[i]]
    end
    outputs
    """
end

function process(ind::CGPInd)::T where {T <:OpenCV.InputArray}
    for i in eachindex(ind.nodes)
        n = ind.nodes[i]
        if n.active
            ind.buffer[i] = n.f(ind.buffer[n.x], ind.buffer[n.y])
        end
    end
    get_outputs(ind)
end

function process(ind::CGPInd, inputs::Array{T}) where {T <:OpenCV.InputArray}
    set_inputs(ind, inputs)
    # process(ind)
end
