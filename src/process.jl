export process, process_f

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


function process(
    reducer::AbstractReducer,
    controller::CGPInd,
    inp::AbstractArray
)
    features = reducer.reduct(inp, reducer.parameters)
    features_flatten = collect(Iterators.flatten(Iterators.flatten(features)))
    CartesianGeneticProgramming.process(controller, features_flatten)
end
