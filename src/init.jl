export get_cstind

"""
    test_cstind(
        ind::NSGA2ECInd,
        ecfg::NamedTuple,
        ccfg::NamedTuple,
        test_action::Int32
    )

Test that this individual only outputs this action.
"""
function test_cstind(
    ind::NSGA2ECInd,
    ecfg::NamedTuple,
    ccfg::NamedTuple,
    test_action::Int32
)
    game = Game(rom_name, 0)
    enco = IPCGPInd(ecfg, ind.e_chromosome)
    cont = CGPInd(ccfg, ind.c_chromosome)
    for i in 1:100
        s = get_state(game, grayscale, downscale)
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
        mcfg::NamedTuple,
        ecfg::NamedTuple,
        ccfg::NamedTuple,
        actions::Vector{Int32}
    )

Build individuals constantly outputing the same actions.
"""
function get_cstind(
    mcfg::NamedTuple,
    ecfg::NamedTuple,
    ccfg::NamedTuple,
    actions::Vector{Int32}
)
    @assert ccfg.n_cst_inputs > 1
    cstinds = Vector{NSGA2ECInd}()
    for i in eachindex(actions)
        enco = IPCGPInd(ecfg)
        cont = CGPInd(ccfg)
        for j in eachindex(cont.outputs)
            if j != i
                cont.outputs[j] = ccfg.n_in - ccfg.n_cst_inputs + 1
            else
                cont.outputs[j] = ccfg.n_in
            end
        end
        new_ind = IICGP.NSGA2ECInd(mcfg, enco.chromosome, cont.chromosome)
        test_cstind(new_ind, ecfg, ccfg, actions[i])
        push!(cstinds, new_ind)
    end
    cstinds
end
