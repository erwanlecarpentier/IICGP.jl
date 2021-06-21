using ArcadeLearningEnvironment
using ArgParse
using CartesianGeneticProgramming
using Dates
using IICGP
using Random
using MappedArrays
using BenchmarkTools
using Images
using ImageView
using Plots
using PlotThemes

theme(:dark)


"""
    get_two_arity(nodes::Array{Node,1}, arity_dict::Dict)

Creates a BitArray tracking two-arity of the functions in the provied
nodes list.
"""
function get_two_arity(nodes::Array{Node}, arity_dict::Dict)
    two_arity = falses(length(nodes))
    for i in eachindex(nodes)
        if arity_dict[String(Symbol(nodes[i].f))] == 2
            two_arity[i] = true
        end
    end
    two_arity
end

function recur_active(nodes::Array{Node}, i::Int16, active::BitArray,
                      two_arity::BitArray)
    active[i] = true
    if nodes[i].x > 0
        recur_active(nodes, nodes[i].x, active, two_arity)
    end
    if nodes[i].y > 0 && two_arity[i]
        recur_active(nodes, nodes[i].y, active, two_arity)
    end
end

function find_active(nodes::Array{Node}, outputs::Array{Int16},
                     two_arity::BitArray)
    active = falses(length(nodes))
    for o in outputs
        recur_active(nodes, o, active, two_arity)
    end
    active
end

"default function for nodes, will cause error if used as a function node"
function f_null(args...)::Nothing
    nothing
end

"""
    play_atari(encoder::CGPInd, controller::CGPInd; seed=0, max_frames=18000)

Fitness function.
"""
function play_atari(encoder::CGPInd, controller::CGPInd; features_size=5, seed=0,
                    max_frames=18000, rendering=true, sleep_time=0.0)
    game = Game(args["game"], seed)
    reward = 0.0
    frames = 0
    # Rendering first image for visu
    #=
    if rendering
        rawscreen = getScreenRGB(game.ale)
        rgb = reshape(rawscreen, (3, game.width, game.height))
        img = colorview(RGB, normedview(rgb))
        guidict = imshow(img, axes=(2, 1))
        canvas = guidict["gui"]["canvas"]
    end
    =#
    while ~game_over(game.ale)
        # Replace get_rgb method to integrate visu
        rawscreen = getScreenRGB(game.ale)
        rgb = permutedims(reshape(rawscreen, (3, game.width, game.height)), [1, 3, 2])
        rgb = [Array{UInt8}(rgb[i,:,:]) for i in 1:3]
        features, output = IICGP.process_f(encoder, controller, rgb, features_size)

        if rendering
            # display(img)
            # img = colorview(RGB, normedview(rgb))
            # imshow(canvas, img, axes=(2, 1))
            display(plot_encoding(n_in, enco.buffer, features))
        end
        sleep(sleep_time)

        action = game.actions[argmax(output)]
        reward += act(game.ale, action)
        frames += 1
        game.ale
        if frames > max_frames
            break
        end
    end
    close!(game)
    [reward]
end

s = ArgParseSettings()
@add_arg_table! s begin
    "--encoder_cfg"
    help = "configuration script"
    default = "cfg/atari_encoder.yaml"
    "--controller_cfg"
    help = "configuration script"
    default = "cfg/atari_controller.yaml"
    "--game"
    help = "game rom name"
    default = "centipede"
    "--seed"
    help = "random seed for evolution"
    arg_type = Int
    default = 0
    "--ind"
    help = "individual for evaluation"
    arg_type = String
    default = ""
end
args = parse_args(ARGS, s)
Random.seed!(args["seed"])

# Temporarily open a game to retrieve parameters
game = Game(args["game"], 0)
rawscreen = getScreenRGB(game.ale)
rgb = permutedims(reshape(rawscreen, (3, game.width, game.height)), [1, 3, 2])
n_in = 3  # RGB images
n_out = length(getMinimalActionSet(game.ale))  # One output per legal action
img_size = size(rgb)[2:3]
close!(game)

##
# Create custom individuals

enco_nodes = [
    Node(1, 1, IICGP.CGPFunctions.f_motion_capture, [0.5], false),
    Node(3, 3, IICGP.CGPFunctions.f_dilate, [1.0], false),
    Node(3, 3, IICGP.CGPFunctions.f_erode, [0.6], false)
]
enco_outputs = Int16[4]
enco_cfg = cfg_from_info(enco_nodes, n_in, enco_outputs, IICGP.CGPFunctions, 1)
enco = IPCGPInd(enco_nodes, enco_cfg, enco_outputs, img_size)
features_size = 5


cont_nodes = [
    Node(1, 2, IICGP.CGPFunctions.f_subtract, [0.5], false),
    Node(1, 2, IICGP.CGPFunctions.f_add, [0.5], false),
    Node(3, 3, IICGP.CGPFunctions.f_cos, [0.6], false)
]
cont_outputs = Int16[3, 4, 5]
cont_n_in = length(enco_outputs) * features_size^2
cont_cfg = cfg_from_info(cont_nodes, cont_n_in, cont_outputs, IICGP.CGPFunctions, 1)
cont = CGPInd(cont_nodes, cont_cfg, cont_outputs)



##

# Play game
play_atari(enco, cont, max_frames=10, sleep_time=0.1, features_size=features_size)



##

game = Game(args["game"], 0)
reward = 0.0
frames = 0

# Rendering first image for visu
rawscreen = getScreenRGB(game.ale)
rgb = permutedims(reshape(rawscreen, (3, game.width, game.height)), [1, 3, 2])
img = colorview(RGB, normedview(rgb))
guidict = imshow(img)
canvas = guidict["gui"]["canvas"]



rgb_split = [Array{UInt8}(rgb[i,:,:]) for i in 1:3]
features, output = IICGP.process_f(enco, cont, rgb_split, features_size)
action = game.actions[argmax(output)]


b = enco.buffer[1]
for i in 2:length(enco.buffer)
    b = hcat(b, enco.buffer[i])
end


plot(rand(100, 4), layout = 4)

heatmap(b, yflip=true, color=:grays, legend=:none, axis=nothing, ratio=:equal, framestyle=:none)


##
#gr(leg = false, bg = :lightgrey)


n_rows = 3
w = 2 * n_cols * img_size[2]
h = n_rows * img_size[1]

theme(:dark)
p = plot(size=(w, h), legend=:none, axis=nothing, framestyle=:none)


heatmap!(zeros(w, h))

heatmap!(b, yflip=true, color=:grays, legend=:none, axis=nothing, ratio=:equal,
    inset = (1, bbox(0.0, 0.0, 0.5, 0.25, :bottom, :right)),
    subplot=1, size=img_size,
    framestyle=:none)




##

guidict = imshow(b)


close!(game)
