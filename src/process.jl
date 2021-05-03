export process

# using CartesianGeneticProgramming  # TODO remove

"""
    function process(encoder::CGPInd, controller::CGPInd, inputs::AbstractArray)

Process function chaining encoder and controller CGP individuals
"""
function process(encoder::CGPInd, controller::CGPInd, inputs::AbstractArray, out_size::Int64)
    output = CartesianGeneticProgramming.process(encoder, inputs)
    for i in eachindex(output)
        output[i] = ReducingFunctions.max_pool_reduction(output[i], out_size)
    end
    inp = collect(Iterators.flatten(output))
    return output
    # reduce(vcat, output[1])
end
