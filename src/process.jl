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
    inp::AbstractArray,
    features_size::Int64
)
    out = CartesianGeneticProgramming.process(encoder, inp)
    features = Array{Array{Float64}}(undef, length(encoder.outputs))
    for i in eachindex(out)
        features[i] = ReducingFunctions.max_pool_reduction(out[i], features_size)
    end
    features_flatten = collect(Iterators.flatten(features))
    CartesianGeneticProgramming.process(controller, features_flatten)
end
