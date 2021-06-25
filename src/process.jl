export process, process_f

"""
DEPRECATED

    process(encoder::CGPInd, controller::CGPInd, inputs::AbstractArray, features_size::Int64)

Process function chaining encoder and controller CGP individuals.
Mean pooling layer is used in between both individuals.
"""
function process(encoder::CGPInd, controller::CGPInd, inp::AbstractArray,
                 features_size::Int64)
    process_f(encoder, controller, inp, features_size)[2]
end

"""
DEPRECATED

    process(encoder::CGPInd, controller::CGPInd, inputs::AbstractArray, features_size::Int64)

Process function chaining encoder and controller CGP individuals.
Mean pooling layer is used in between both individuals.
Return both the processed output and the computed feature images.
"""
function process_f(encoder::CGPInd, controller::CGPInd, inp::AbstractArray,
                 features_size::Int64)
    out = CartesianGeneticProgramming.process(encoder, inp)
    features = Array{Array{Float64}}(undef, length(encoder.outputs))
    for i in eachindex(out)
        features[i] = ReducingFunctions.mean_pool_reduction(out[i], features_size)
    end
    features_flatten = collect(Iterators.flatten(features))
    return features, CartesianGeneticProgramming.process(controller, features_flatten)
end

"""
    function process(
        encoder::CGPInd,
        reducer::AbstractReducer,
        controller::CGPInd,
        inp::AbstractArray
    )

Process function chaining encoder, features projection and controller.
Both the encoder and the controller are CGP individuals.
"""
function process(
    encoder::CGPInd,
    reducer::AbstractReducer,
    controller::CGPInd,
    inp::AbstractArray
)
    process_f(encoder, reducer, controller, inp)[2]
end

"""
    function process_f(
        encoder::CGPInd,
        reducer::AbstractReducer,
        controller::CGPInd,
        inp::AbstractArray
    )

Process function chaining encoder, features projection and controller.
Both the encoder and the controller are CGP individuals.
Return both the created feature vector and the output.
"""
function process_f(
    encoder::CGPInd,
    reducer::AbstractReducer,
    controller::CGPInd,
    inp::AbstractArray
)
    out = CartesianGeneticProgramming.process(encoder, inp)
    features = reducer.reduct(out, reducer.parameters)
    # features_flatten = collect(Iterators.flatten(features))
    features_flatten = collect(Iterators.flatten(Iterators.flatten(features)))
    return features, CartesianGeneticProgramming.process(controller, features_flatten)
end

"""
    function process_full(
        encoder::CGPInd,
        reducer::AbstractReducer,
        controller::CGPInd,
        inp::AbstractArray
    )

Process function chaining encoder, features projection and controller.
Both the encoder and the controller are CGP individuals.
Return the encoder output, the created feature vector and the output.
"""
function process_full(
    encoder::CGPInd,
    reducer::AbstractReducer,
    controller::CGPInd,
    inp::AbstractArray
)
    enco_out = CartesianGeneticProgramming.process(encoder, inp)
    features = reducer.reduct(enco_out, reducer.parameters)
    # features_flatten = collect(Iterators.flatten(features))
    features_flatten = collect(Iterators.flatten(Iterators.flatten(features)))
    cont_out = CartesianGeneticProgramming.process(controller, features_flatten)
    return enco_out, features, cont_out
end
