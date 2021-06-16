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

"""
    get_two_arity(nodes::Array{Node,1}, arity_dict::Dict)

Creates a boolean array tracking two-arity of the functions in the provied
nodes list.
"""
function get_two_arity(nodes::Array{Node,1}, arity_dict::Dict)
    two_arity = Bool[]
    for n in nodes
        if arity_dict[String(Symbol(n.f))] == 1
            push!(two_arity, false)
        else
            push!(two_arity, true)
        end
    end
    two_arity
end

"default function for nodes, will cause error if used as a function node"
function f_null(args...)::Nothing
    nothing
end

"""
    play_atari(encoder::CGPInd, controller::CGPInd; seed=0, max_frames=18000)

Fitness function.
"""
function play_atari(encoder::CGPInd, controller::CGPInd; seed=0,
                    max_frames=18000, rendering=true, sleep_time=0.0)
    game = Game(args["game"], seed)
    reward = 0.0
    frames = 0
    # First image for visu
    if rendering
        rawscreen = getScreenRGB(game.ale)
        rgb = reshape(rawscreen, (3, game.width, game.height))
        guidict = ImageView.imshow(img)
        canvas = guidict["gui"]["canvas"]
    end
    while ~game_over(game.ale)
        # Replace the get_rgb method to
        rawscreen = getScreenRGB(game.ale)
        rgb = reshape(rawscreen, (3, game.width, game.height))
        if rendering
            img = transpose(colorview(RGB, normedview(rgb)))
            # display(img)
            imshow(canvas, img)
        end
        sleep(sleep_time)
        rgb = [Array{UInt8}(rgb[i,:,:]) for i in 1:3]
        output = IICGP.process(encoder, controller, rgb,
                               encoder_cfg.features_size)
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
out = get_rgb(game)
n_in = 3  # RGB images
n_out = length(getMinimalActionSet(game.ale))  # One output per legal action
img_size = size(out[1])
close!(game)

# Encoder configuration
encoder_cfg = get_config(
    args["encoder_cfg"];
    function_module=IICGP.CGPFunctions,
    n_in=n_in,
    img_size=img_size
)
logid = string(Dates.now(), "_", args["game"], "_", args["seed"])

# Controller configuration
n_in_controller = encoder_cfg.n_out * encoder_cfg.features_size^2
controller_cfg = get_config(
    args["controller_cfg"];
    n_in=n_in_controller,
    n_out=n_out
)

# Create 2 individuals
enco = IPCGPInd(encoder_cfg)
cont = CGPInd(controller_cfg)

enco_nodes = Node[]
push!(enco_nodes, Node(1, 2, IICGP.CGPFunctions.f_subtract, [0.5], false))
push!(enco_nodes, Node(1, 2, IICGP.CGPFunctions.f_erode, [0.5], false))
push!(enco_nodes, Node(3, 3, IICGP.CGPFunctions.f_erode, [0.5], false))
two_arity = get_two_arity(enco_nodes, IICGP.CGPFunctions.arity)


###
nodes = enco_nodes
###
R = 1
C = length(enco_nodes)
all_nodes = Array{Node}(undef, n_in)
p = Float64[]
for i in 1:n_in
    all_nodes[i] = Node(0, 0, f_null, p, false)
end
push!(all_nodes, nodes...)


###

function CGPInd(n_in::Int64, nodes::Array{Node,1}, outputs::Array{Int16}, two_arity::BitArray)
    #cfg::NamedTuple, chromosome::Array{Float64}, nodes::Array{Node,1}, genes::Array{Float64}, outputs::Array{Int16}; kwargs...)::CGPInd
    R = 1
    C = length(nodes)
    all_nodes = Array{Node}(undef, n_in)
    p = Float64[]
    for i in 1:n_in
        all_nodes[i] = Node(0, 0, f_null, p, false)
    end
    push!(all_nodes, nodes...)

    i = cfg.n_in
    active = find_active(cfg, genes, outputs)
    for y in 1:C
        for x in 1:R
            i += 1
            if cfg.n_parameters > 0
                p = genes[x, y, 4:end]
            end
            nodes[i] = Node(Int16(genes[x, y, 1]), Int16(genes[x, y, 2]),
                            cfg.functions[Int16(genes[x, y, 3])], p,
                            active[x, y])
        end
    end
    kwargs_dict = Dict(kwargs)
    # Use given input buffer or default to Array{Float64, 1} type
    if haskey(kwargs_dict, :buffer)
        buffer = kwargs_dict[:buffer]
    else
        buffer = zeros(R * C + cfg.n_in)
    end
    fitness = -Inf .* ones(cfg.d_fitness)
    CGPInd(cfg.n_in, cfg.n_out, cfg.n_parameters, chromosome, genes, outputs,
           nodes, buffer, fitness)
end

# Play game
play_atari(enco, cont, max_frames=300, sleep_time=0.1)
