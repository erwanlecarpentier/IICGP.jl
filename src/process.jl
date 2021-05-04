export process

"""
    function process(
        encoder::CGPInd,
        controller::CGPInd,
        inputs::AbstractArray,
        features_size::Int64
    )

Process function chaining encoder and controller CGP individuals.
Max pooling layer is used in between both individuals.
"""
function process(
    encoder::CGPInd,
    controller::CGPInd,
    inputs::AbstractArray,
    features_size::Int64
)
    output = CartesianGeneticProgramming.process(encoder, inputs)
    features = Array{Array{UInt8}}(undef, length(encoder.outputs))
    for i in eachindex(output)
        # output[i] = ReducingFunctions.max_pool_reduction(output[i], features_size)
        features[i] = ReducingFunctions.max_pool_reduction(output[i], features_size)
    end
    features_flatten = collect(Iterators.flatten(features))
    CartesianGeneticProgramming.process(controller, features_flatten)
end
