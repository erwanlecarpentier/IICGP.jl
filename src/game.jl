# The following was inspired by AtariAlgos.jl
# Modifications by Dennis Wilson @d9w and Erwan Lecarpentier

using ArcadeLearningEnvironment
using Colors
using ImageCore
using ImageTransformations
export
    Game,
    close!,
    draw,
    get_inputs,
    get_rgb

struct Game
    ale::ALEPtr
    width::Int
    height::Int
    actions::Array{Int32}
end

function Game(romfile::String, seed::Int64; kwargs...)
    ale = ALE_new()
    setInt(ale, "random_seed", Cint(seed))
    kwargs_dict = Dict(kwargs)
    if haskey(kwargs_dict, :lck)  # Thread safe
        lock(kwargs_dict[:lck]) do
            loadROM(ale, romfile)
        end
    else
        loadROM(ale, romfile)
    end
    w = getScreenWidth(ale)
    h = getScreenHeight(ale)
    actions = getMinimalActionSet(ale)
    Game(ale, w, h, actions)
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

function get_rgb(game::Game)
    rawscreen = getScreenRGB(game.ale)
    #=
    # Slower
    rgb = reshape(rawscreen, (3, game.width, game.height));
    [Array{UInt8}(rgb[i,:,:]) for i in 1:3]
    =#
    [convert(Array{UInt8,2}, reshape(@view(rawscreen[i:3:length(rawscreen)]), (game.width, game.height))) for i in 1:3]
end

function get_ram(game::Game)
    getRAM(game.ale) ./ typemax(UInt8)
end
