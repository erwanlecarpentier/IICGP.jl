export process, process_ind, process_f

function process_ind(ind::CGPInd, inputs::AbstractArray)
    # Set inputs
    @inbounds for i in eachindex(inputs)
        ind.buffer[i] = inputs[i]
    end
    # Process
    @inbounds for i in eachindex(ind.nodes)
        if ind.nodes[i].active
            ind.buffer[i] = ind.nodes[i].f(
                ind.buffer[ind.nodes[i].x],
                ind.buffer[ind.nodes[i].y],
                ind.nodes[i].p
            )
        end
    end
    # Get outputs
    [ind.buffer[i] for i in ind.outputs]
end

"""
    function process(
        encoder::CGPInd,
        reducer::AbstractReducer,
        controller::CGPInd,
        controller_config::NamedTuple,
        inp::AbstractArray
    )

Process function chaining encoder, features projection and controller.
Both the encoder and the controller are CGP individuals.
"""
function process(
    encoder::CGPInd,
    reducer::AbstractReducer,
    controller::CGPInd,
    controller_config::NamedTuple,
    inp::AbstractArray
)
    out = CartesianGeneticProgramming.process(encoder, inp)
    features = reducer.reduct(out, reducer.parameters)
    features_flatten = collect(Iterators.flatten(Iterators.flatten(features)))
    if controller_config.n_cst_inputs > 1
        push!(features_flatten, 0:1.0/(controller_config.n_cst_inputs-1):1.0...)
    end
    CartesianGeneticProgramming.process(controller, features_flatten)
end

"""
    function process_f(
        encoder::CGPInd,
        reducer::AbstractReducer,
        controller::CGPInd,
        controller_config::NamedTuple,
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
    controller_config::NamedTuple,
    inp::AbstractArray
)
    out = CartesianGeneticProgramming.process(encoder, inp)
    features = reducer.reduct(out, reducer.parameters)
    # features_flatten = collect(Iterators.flatten(features))
    features_flatten = collect(Iterators.flatten(Iterators.flatten(features)))
    if controller_config.n_cst_inputs > 1
        push!(features_flatten, 0:1.0/(controller_config.n_cst_inputs-1):1.0...)
    end
    return features, CartesianGeneticProgramming.process(controller, features_flatten)
end

"""
    function process_full(
        encoder::CGPInd,
        reducer::AbstractReducer,
        controller::CGPInd,
        controller_config::NamedTuple,
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
    controller_config::NamedTuple,
    inp::AbstractArray
)
    enco_out = CartesianGeneticProgramming.process(encoder, inp)
    features = reducer.reduct(enco_out, reducer.parameters)
    # features_flatten = collect(Iterators.flatten(features))
    features_flatten = collect(Iterators.flatten(Iterators.flatten(features)))
    if controller_config.n_cst_inputs > 1
        push!(features_flatten, 0:1.0/(controller_config.n_cst_inputs-1):1.0...)
    end
    cont_out = CartesianGeneticProgramming.process(controller, features_flatten)
    return enco_out, features, cont_out
end

function process(
    reducer::AbstractReducer,
    controller::CGPInd,
    inp::AbstractArray,
)
    features = reducer.reduct(inp, reducer.parameters)
    features_flatten = collect(Iterators.flatten(Iterators.flatten(features)))
    CartesianGeneticProgramming.process(controller, features_flatten)
end
