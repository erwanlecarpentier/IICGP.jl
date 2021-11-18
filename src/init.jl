export get_cstind

"""
    test_cstind(
        rom_name::String,
        ind::NSGA2ECInd,
        ecfg::NamedTuple,
        ccfg::NamedTuple,
        test_action::Int32
    )

Test that this individual only outputs this action.
"""
function test_cstind(
    rom_name::String,
    ind::NSGA2ECInd,
    mcfg::NamedTuple,
    ecfg::NamedTuple,
    ccfg::NamedTuple,
    test_action::Int32,
    reducer::Reducer
)
    game = Game(rom_name, 0)
    enco = IPCGPInd(ecfg, ind.e_chromosome)
    cont = CGPInd(ccfg, ind.c_chromosome)
    for i in 1:100
        s = get_state(game, mcfg.grayscale, mcfg.downscale)
        output = IICGP.process(enco, reducer, cont, ccfg, s)
        action = game.actions[argmax(output)]
        @assert action == test_action
        act(game.ale, action)
        if game_over(game.ale)
            break
        end
    end
    close!(game)
end

"""
    get_cstind(
        rom_name::String,
        mcfg::NamedTuple,
        ecfg::NamedTuple,
        ccfg::NamedTuple
    )

Build individuals constantly outputing the same actions.
"""
function get_cstind(
    rom_name::String,
    mcfg::NamedTuple,
    ecfg::NamedTuple,
    ccfg::NamedTuple,
    reducer::Reducer
)
    game = Game(rom_name, 0)
    actions = game.actions
    close!(game)
    @assert ccfg.n_cst_inputs > 1
    cstinds = Vector{NSGA2ECInd}()
    R = ccfg.rows
    C = ccfg.columns
    P = ccfg.n_parameters
    M = R * C + ccfg.n_in
    for i in eachindex(actions)
        enco = IPCGPInd(ecfg)
        cont = CGPInd(ccfg)
        for j in eachindex(cont.outputs)
            if j != i
                #cont.outputs[j] = ccfg.n_in - ccfg.n_cst_inputs + 1
                cont.chromosome[R*C*(3+P)+j] = (ccfg.n_in - ccfg.n_cst_inputs + 1) / M
            else
                #cont.outputs[j] = ccfg.n_in
                cont.chromosome[R*C*(3+P)+j] = (ccfg.n_in) / M
            end
        end
        new_ind = IICGP.NSGA2ECInd(mcfg, enco.chromosome, cont.chromosome)
        test_cstind(rom_name, new_ind, mcfg, ecfg, ccfg, actions[i], reducer)
        push!(cstinds, new_ind)
    end
    cstinds
end
