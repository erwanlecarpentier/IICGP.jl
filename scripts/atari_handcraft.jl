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
using Statistics

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
    function play_atari(
        encoder::CGPInd,
        reducer::AbstractReducer,
        controller::CGPInd;
        reducer_type::String="pooling",
        seed::Int64=0,
        max_frames::Int64=18000,
        sleep_time::Float64=0.0,
        render::Bool=true,
        save::Bool=false
    )

Play Atari and display individual's encoding.
"""
function play_atari(
    encoder::CGPInd,
    reducer::AbstractReducer,
    controller::CGPInd,
    reducer_type::String;
    seed::Int64=0,
    max_frames::Int64=1000,
    sleep_time::Float64=0.0,
    render::Bool=true,
    save::Bool=false,
    save_repo::String=string("gifs/", args["game"], "/")
)
    game = Game(args["game"], seed)
    reward = 0.0
    frames = 1
    a_prev = nothing
    c_prev = nothing
    while ~game_over(game.ale)
        # Replace get_rgb method to integrate visu
        rawscreen = getScreenRGB(game.ale)
        rgb = permutedims(reshape(rawscreen, (3, game.width, game.height)), [1, 3, 2])
        rgb = [Array{UInt8}(rgb[i,:,:]) for i in 1:3]

        # Process
        enco_out, features, out = IICGP.process_full(
            encoder,
            reducer,
            controller,
            rgb
        )

        # Render and save
        if reducer_type == "pooling"
            plt = plot_encoding(n_in, enco.buffer, features)
        elseif reducer_type == "centroid"
            plt = plot_centroids(enco_out, features)
        end
        if render
            display(plt)
        end
        if save
            savefig(plt, string(save_repo, "$frames.png"))
            # println(frames)
        end

        sleep(sleep_time)
        action = game.actions[argmax(out)]
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

##

s = ArgParseSettings()
@add_arg_table! s begin
    "--game"
    help = "game rom name"
    default = "freeway"
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
d_fitness = 1
close!(game)

# Encoder
enco_nodes = [
    Node(1, 1, IICGP.CGPFunctions.f_motion_capture, [0.5], false)
]
enco_outputs = Int16[1, 4]
enco_cfg = cfg_from_info(enco_nodes, n_in, enco_outputs, IICGP.CGPFunctions,
                         d_fitness)
enco = IPCGPInd(enco_nodes, enco_cfg, enco_outputs, img_size)

# Reducer
reducer_cfg = Dict(
    "type" => "pooling",
    "pooling_function" => "mean",
    "features_size" => 5,
    "n_centroids" => 20
)
redu = Reducer(reducer_cfg, n_in=enco_cfg.n_out, img_size=img_size)
if reducer_cfg["type"] == "pooling"
    features_size = reducer_cfg["features_size"]^2
elseif reducer_cfg["type"] == "centroid"
    features_size = 2 * reducer_cfg["n_centroids"]
end

# Controller
cont_nodes = [
    Node(1, 2, IICGP.CGPFunctions.f_subtract, [0.5], false),
    Node(1, 2, IICGP.CGPFunctions.f_add, [0.5], false),
    Node(3, 3, IICGP.CGPFunctions.f_cos, [0.6], false)
]
cont_outputs = Int16[1, 2, 3]
cont_n_in = length(enco_outputs) * features_size^2
cont_cfg = cfg_from_info(cont_nodes, cont_n_in, cont_outputs, IICGP.CGPFunctions, 1)
cont = CGPInd(cont_nodes, cont_cfg, cont_outputs)

##

# Play game
play_atari(
    enco, redu, cont,
    reducer_type=reducer_cfg["type"],
    max_frames=2,
    sleep_time=0.0,
    render=true,
    save_repo="gifs/",
    save=true
)

##
using Plots.PlotMeasures

# Temporarily open a game to retrieve parameters
game = Game(args["game"], 0)
rawscreen = getScreenRGB(game.ale)
rgb = permutedims(reshape(rawscreen, (3, game.width, game.height)), [1, 3, 2])
img_size = size(rgb)[2:3]
rgb = [Array{UInt8}(rgb[i,:,:]) for i in 1:3]
n_in = 3  # RGB images
n_out = length(getMinimalActionSet(game.ale))  # One output per legal action
d_fitness = 1
close!(game)

x = rgb[1]
mult = 2
sz = (mult*size(x)[2], mult*size(x)[1])
plt = heatmap(
    x, color=:grays, ratio=:equal,
    yflip=true,
    leg=false,
    framestyle=:none,
    padding=(0.0, 0.0),
    margin=-100mm,
    size=sz
)
