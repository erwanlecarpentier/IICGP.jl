# The following was inspired by AtariAlgos.jl
# Modifications by Dennis Wilson @d9w and Erwan Lecarpentier @erwanlecarpentier

using ArcadeLearningEnvironment
using Colors
using ImageCore
using ImageTransformations
using Interpolations
export
    Game,
    close!,
    reset!,
    draw,
    get_inputs,
    get_state_buffer,
    get_observation_buffer,
    get_state!,
    get_observation!,
    get_state,
    get_screen,
    get_rgb,
    get_grayscale,
    get_state_ref,
    get_ram,
    save_screen_png

struct Game
    ale::ALEPtr
    width::Int
    height::Int
    actions::Array{Int32}
end

function Game(romfile::String, seed::Int64; kwargs...)
    ale = ALE_new()
    setInt(ale, "random_seed", Cint(seed))
    setInt(ale, "repeat_action_probability", Cint(0))
    # setBool(ale, "color_averaging", true)
    # setInt(ale, "frame_skip", Int32(1)) # 1 means no frame skip
    setFloat(ale, "repeat_action_probability", Float32(0.0))
    kwargs_dict = Dict(kwargs)
    if haskey(kwargs_dict, :lck)  # Thread safe
        lock(kwargs_dict[:lck]) do
            loadROM(ale, romfile)
        end
        # unlock(kwargs_dict[:lck])
    else
        loadROM(ale, romfile)
    end
    if haskey(kwargs_dict, :state_ref)  # Initial state
        ArcadeLearningEnvironment.restoreSystemState(ale, kwargs_dict[:state_ref])
    end
    w = getScreenWidth(ale)
    h = getScreenHeight(ale)
    actions = getMinimalActionSet(ale)
    #=
    for _ in 1:3 # 1st actions are noop
        act(ale, 0)
    end
    =#
    Game(ale, w, h, actions)
end

function reset!(game::Game)
    reset_game(game.ale)
end

function get_state_ref(romfile::String, seed::Int64)
    ale = ALE_new()
    setInt(ale, "random_seed", Cint(seed))
    loadROM(ale, romfile)
    state_ref = ArcadeLearningEnvironment.cloneSystemState(ale)
    ALE_del(ale)
    state_ref
end

function close!(game::Game)
    ALE_del(game.ale)
end

function draw(game::Game)
    rawscreen = getScreenRGB(game.ale)
    colorview(RGB, Float64.(reshape(rawscreen/256.,
                                    (3, game.width, game.height))))';
end

function get_inputs(game::Game)
    screen = getScreen(game.ale)/(0xff*1.0)
    screen = reshape(screen, (game.width, game.height))'
    # imresize(screen, (42, 32))/256.
    screen
end

function scale(x::Array{UInt8,2}; factor::Int64=2)
    outsz = ceil.(Int, size(x)./factor)
    tilesz = (factor,factor)
    out = Array{UInt8,2}(undef, outsz)
    R = TileIterator(axes(x), tilesz)
    i = 1
    for tileaxs in R
       out[i] = maximum(view(x, tileaxs...))
       i += 1
    end
    out
end

function get_state_buffer(game::Game, grayscale::Bool)
    size = grayscale ? game.width * game.height : game.width * game.height * 3
    Vector{UInt8}(undef, size)
end

function get_observation_buffer(game::Game, grayscale::Bool, downscale::Bool)
    n_obs = grayscale ? 1 : 3
    if downscale
        # (l+1)÷2 for odd l, and l÷2 + 1 for even l
        w = isodd(game.width) ? (game.width + 1) ÷ 2 : game.width ÷ 2 + 1
        h = isodd(game.height) ? (game.height + 1) ÷ 2 : game.height ÷ 2 + 1
        obs_size = (w, h)
    else
        obs_size = (game.width, game.height)
    end
    [Array{UInt8, 2}(undef, obs_size) for _ in 1:n_obs]
end

function get_state!(
    s::Vector{UInt8},
    game::Game,
    grayscale::Bool
)
    if grayscale
        ArcadeLearningEnvironment.getScreenGrayscale!(game.ale, s)
    else
        ArcadeLearningEnvironment.getScreenRGB!(game.ale, s)
    end
end

"""
grayscale downscale - @btime
1 1 - 41.143 μs (16 allocations: 276.27 KiB)
1 0 - 77.752 ns (3 allocations: 192 bytes)
0 0 - 54.647 μs (7 allocations: 98.97 KiB)
0 1 - 158.778 μs (43 allocations: 828.58 KiB)
"""
function get_observation!(
    o::Vector{Matrix{UInt8}},
    s::Vector{UInt8},
    game::Game,
    grayscale::Bool,
    downscale::Bool
)
    if grayscale
        if downscale
            o .= [convert(Matrix{UInt8},
                floor.(imresize(reshape(s, (game.width, game.height)),
                ratio=0.5, method=BSpline(Linear()))))]
            #    convert(Matrix{UInt8},
            #    imresize(reshape(s, (game.width, game.height)),
            #    ratio=0.5, method=BSpline(Constant())))]
        else
            o .= [reshape(s, (game.width, game.height))]
        end
    else
        if downscale
            o .= [
                convert(Matrix{UInt8},
                    floor.(imresize(
                        reshape(
                            @view(s[i:3:length(s)]),
                            (game.width, game.height)
                        ),
                        ratio=0.5,
                        method=BSpline(Linear())
                    ))
                ) for i in 1:3
            ]
        else
            o .= [
                convert(
                    Array{UInt8,2},
                    reshape(
                        @view(s[i:3:length(s)]),
                        (game.width, game.height)
                    )
                ) for i in 1:3
            ]
        end
    end
end

function get_state(
    game::Game,
    grayscale::Bool,
    downscale::Bool
)
    s = grayscale ? get_grayscale(game) : get_rgb(game)
    if downscale
        @inbounds for i in eachindex(s)
            # s[i] = scale(s[i])
            #s[i] = convert(Matrix{UInt8}, imresize(s[i], ratio=0.5, method=BSpline(Constant())))
            s[i] = convert(Matrix{UInt8}, floor.(imresize(s[i], ratio=0.5, method=BSpline(Linear()))))
            #s[i] = convert(Matrix{UInt8}, floor.(restrict(s[i]))) # Memory issues ?
        end
    end
    s
end

function save_screen_png(game::Game, filename::String)
    saveScreenPNG(game.ale, filename)
end

function get_screen(game::Game)
    rawscreen = getScreen(game.ale)
    convert(Array{UInt8,2}, reshape(@view(rawscreen[1:length(rawscreen)]), (game.width, game.height)))
end

function get_rgb(game::Game)
    rawscreen = getScreenRGB(game.ale)
    [convert(Array{UInt8,2}, reshape(@view(rawscreen[i:3:length(rawscreen)]), (game.width, game.height))) for i in 1:3]
end

function get_grayscale(game::Game)
    gs = getScreenGrayscale(game.ale)
    gs = reshape(gs, (game.width, game.height))
    [gs]
end

function get_ram(game::Game)
    getRAM(game.ale) ./ typemax(UInt8)
end
