using ArcadeLearningEnvironment
using CartesianGeneticProgramming
using IICGP
using Random
using Test

const cfg_filename = string(@__DIR__, "/dualcgp_test.yaml")
const game = "assault"
const seed = 0
Random.seed!(seed)
main_cfg, enc_cfg, con_cfg, red, _ = IICGP.dualcgp_config(
    cfg_filename, game
)
main_cfg["max_frames"] = 3500
const max_frames = main_cfg["max_frames"]
const stickiness = main_cfg["stickiness"]
const grayscale = main_cfg["grayscale"]
const downscale = main_cfg["downscale"]
const logid = enc_cfg.id
const state_ref = get_state_ref(game, seed)
const lck = ReentrantLock()

global STTS = Vector{Vector{Matrix{UInt8}}}(undef, max_frames)
global ACTS = Vector{Int32}(undef, max_frames)
global REWS = Vector{Int64}(undef, max_frames)
global STKS = Vector{Float64}(undef, max_frames)


function play_atari(
    encoder::CGPInd,
    reducer::Reducer,
    controller::CGPInd,
    lck::ReentrantLock,
    is_ref::Bool;
    rom=game,
    seed=seed,
    rom_state_ref=state_ref,
    max_frames=max_frames,
    grayscale=grayscale,
    downscale=downscale,
    stickiness=stickiness
)
    # Random.seed!(seed)
    mt = MersenneTwister(seed)
    game = Game(rom, seed, lck=lck, state_ref=rom_state_ref)
    IICGP.reset!(reducer) # clean buffer
    # reward = 0.0
    frames = 0
    prev_action = 0
    # Buffers
    stts = Vector{Vector{Matrix{UInt8}}}(undef, max_frames)
    acts = Vector{Int32}(undef, max_frames)
    rews = Vector{Int64}(undef, max_frames)
    stks = Vector{Float64}(undef, max_frames)
    while ~game_over(game.ale)
        s = get_state(game, grayscale, downscale)
        stickydraw = rand(mt)
        if stickydraw > stickiness || frames == 0
            output = IICGP.process(encoder, reducer, controller, s)
            action = game.actions[argmax(output)]
        else
            action = prev_action
        end
        r = act(game.ale, action)
        # reward += r
        frames += 1
        if frames > max_frames
            break
        end
        # Buffers
        stts[frames] = s
        acts[frames] = action
        rews[frames] = r
        stks[frames] = stickydraw
    end
    close!(game)
    # Test
    global STTS
    global ACTS
    global REWS
    global STKS
    if is_ref
        STTS .= stts
        ACTS .= acts
        REWS .= rews
        STKS .= stks
    else
        println()
        println(stts == STTS)
        println(acts == ACTS)
        println(rews == REWS)
        println(stks == STKS)
        #=
        @test stts == STTS
        @test acts == ACTS
        @test rews == REWS
        @test stks == STKS
        =#
    end
    # [reward]
end


enc = IPCGPInd(enc_cfg)
con = CGPInd(con_cfg)
play_atari(enc, red, con, lck, true)

# Recreate individuals for buffer initialization testing
enc = IPCGPInd(enc_cfg, enc.chromosome)
con = CGPInd(con_cfg, con.chromosome)
play_atari(enc, red, con, lck, false)

##

@testset "Determinism on single encoder-controller pair" begin
    enc = IPCGPInd(enco_cfg)
    con = CGPInd(cont_cfg)
    play_atari(enc, red, con, lck, true)

    # Recreate individuals for buffer initialization testing
    enc = IPCGPInd(enc_cfg, enc.chromosome)
    con = CGPInd(con_cfg, con.chromosome)
    play_atari(enc, red, con, lck, false)
end
