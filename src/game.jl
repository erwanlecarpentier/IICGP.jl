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
    draw,
    get_inputs,
    get_state,
    get_rgb,
    get_grayscale,
    get_state_ref

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
    # setFloat(ale, "repeat_action_probability", Float32(0.))
    kwargs_dict = Dict(kwargs)
    if haskey(kwargs_dict, :lck)  # Thread safe
        lock(kwargs_dict[:lck]) do
            loadROM(ale, romfile)
        end
    else
        loadROM(ale, romfile)
    end
    if haskey(kwargs_dict, :state_ref)  # Initial state
        ArcadeLearningEnvironment.restoreSystemState(ale, kwargs_dict[:state_ref])
    end
    w = getScreenWidth(ale)
    h = getScreenHeight(ale)
    actions = getMinimalActionSet(ale)
    Game(ale, w, h, actions)
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

function get_state(game::Game, grayscale::Bool, downscale::Bool)
    s = grayscale ? get_grayscale(game) : get_rgb(game)
    if downscale
        out = Array{Array{UInt8,2},1}(undef, length(s))
        for i in 1:length(s)
            # out[i] = scale(s[i])
            # out[i] = imresize(s[i], ratio=0.5, method=BSpline(Constant()))
            # out[i] = convert(Array{UInt8,2}, floor.(imresize(s[i], ratio=0.5, method=BSpline(Linear()))))
            out[i] = convert(Array{UInt8,2}, floor.(restrict(s[i])))
        end
        return out
    else
        return s
    end
end

function get_rgb(game::Game)
    rawscreen = getScreenRGB(game.ale)
    #=
    # Slower
    rgb = reshape(rawscreen, (3, game.width, game.height));
    [Array{UInt8}(rgb[i,:,:]) for i in 1:3]
    =#
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
