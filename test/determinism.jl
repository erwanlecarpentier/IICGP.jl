using ArcadeLearningEnvironment
using CartesianGeneticProgramming
using IICGP
using Random
using Test

const cfg_filename = string(@__DIR__, "/dualcgp_test.yaml")
const rom = "assault"
const roms = ["assault", "atlantis", "centipede", "tennis", "pong"]
const all_roms = setdiff(getROMList(), ["pacman", "surround"])
const seed = 0
Random.seed!(seed)

const max_frames = 10
const stickiness = 0.25 # main_cfg["stickiness"]
const grayscale = true # main_cfg["grayscale"]
const downscale = true # main_cfg["downscale"]
const lck = ReentrantLock()

global STTS = [] # Vector{Vector{Matrix{UInt8}}}(undef, max_frames)
global RGBS = []
global GRSS = []
global ACTS = [] # Vector{Int32}(undef, max_frames)
global REWS = [] # Vector{Int64}(undef, max_frames)
global STKS = [] # Vector{Float64}(undef, max_frames)
global RAMS = [] # Vector{Float64}(undef, max_frames)

function play_atari(
    encoder::CGPInd,
    reducer::Reducer,
    controller::CGPInd,
    lck::ReentrantLock,
    is_ref::Bool,
    rom::String,
    rom_state_ref::Ptr{Nothing};
    seed=seed,
    max_frames=max_frames,
    grayscale=grayscale,
    downscale=downscale,
    stickiness=stickiness,
    verbose=false
)
    # Random.seed!(seed)
    mt = MersenneTwister(seed)
    g = Game(rom, seed, lck=lck, state_ref=rom_state_ref)
    IICGP.reset!(reducer) # clean buffer
    # reward = 0.0
    frames = 0
    prev_action = 0
    # Buffers
    stts = []
    rgbs = []
    grss = []
    acts = []
    rews = []
    stks = []
    rams = []
    while ~game_over(g.ale)
        s = get_state(g, grayscale, downscale)
        rgb = get_rgb(g)
        gs = get_grayscale(g)
        ram = get_ram(g)
        stickydraw = rand(mt)
        if stickydraw > stickiness || frames == 0
            output = IICGP.process(encoder, reducer, controller, s)
            action = g.actions[argmax(output)]
            # action = g.actions[rand(mt, 1:length(g.actions))]
        else
            action = prev_action
        end
        frames += 1
        # action = a_seq[frames]
        r = act(g.ale, action)
        # reward += r
        if frames > max_frames
            break
        end
        # Fill buffers
        push!(stts, s)
        push!(rgbs, rgb)
        push!(grss, gs)
        push!(acts, action)
        push!(rews, r)
        push!(stks, stickydraw)
        push!(rams, ram)
    end
    close!(g)
    # Test
    global STTS
    global RGBS
    global GRSS
    global ACTS
    global REWS
    global STKS
    global RAMS
    if is_ref
        STTS = stts
        RGBS = rgbs
        GRSS = grss
        ACTS = acts
        REWS = rews
        STKS = stks
        RAMS = rams
    else
        @test stts == STTS
        @test rgbs == RGBS
        @test grss == GRSS
        @test acts == ACTS
        @test rews == REWS
        @test stks == STKS
        @test rams == RAMS
    end
end

@testset "Determinism on all Atari games for dualCGP" begin
    for r in all_roms
        main_cfg, enc_cfg, con_cfg, red, _ = IICGP.dualcgp_config(cfg_filename, r)
        state_ref = get_state_ref(r, seed)

        # Reference
        enc = IPCGPInd(enc_cfg)
        con = CGPInd(con_cfg)
        play_atari(enc, red, con, lck, true, r, state_ref)

        # Test if same individuals produce the same trajectories
        for _ in 1:2
            enc = IPCGPInd(enc_cfg, enc.chromosome)
            con = CGPInd(con_cfg, con.chromosome)
            play_atari(enc, red, con, lck, false, r, state_ref)
        end
    end
end

function act_for(e::Ptr{Nothing}, as::Vector{Int64}; verbose::Bool=false)
    gs = []
    w = getScreenWidth(e)
    h = getScreenHeight(e)
    for i in 1:length(as)
        act(e, as[i])
        gs_i = reshape(getScreenGrayscale(e), (w,h))
        push!(gs, gs_i)
        if game_over(e)
            if verbose
                println("\nReached frame number : ", i)
            end
            break
        end
    end
    gs
end

@testset "Determinism on ALE only" begin
    n_a = 50000
    for romfile in roms
        ale = ALE_new()
        loadROM(ale, romfile)
        actions = getMinimalActionSet(ale)
        w = getScreenWidth(ale)
        h = getScreenHeight(ale)
        ast = cloneSystemState(ale)
        a_seq = actions[rand(1:length(actions), n_a)]
        ags = act_for(ale, a_seq)
        # ags = reshape(getScreenGrayscale(ale), (w,h))
        # display(IICGP.implot(ags))

        for _ in 1:2
            ble = ALE_new()
            loadROM(ble, romfile)
            restoreSystemState(ble, ast)
            bst = cloneSystemState(ble)
            bgs = act_for(ble, a_seq)
            # bgs = reshape(getScreenGrayscale(ble), (w,h))
            # display(IICGP.implot(bgs))
            # println()
            # println("Same gs : ", bgs == ags)
            @test bgs == ags
            ALE_del(ble)
        end
        ALE_del(ale)
    end
end
