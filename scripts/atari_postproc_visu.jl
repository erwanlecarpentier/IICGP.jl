using ArcadeLearningEnvironment
using CartesianGeneticProgramming
using Dates
using IICGP
using Random
using YAML


function fill_width_with_zeros(x::Matrix{UInt8}, width::Int64)
    if size(x)[2] < width
        x = cat(x, zeros(UInt8, size(x)[1], width-size(x)[2]), dims=2)
    end
    x
end

function width_equalize(v::Matrix{UInt8}, w::Matrix{UInt8})
    width = max(size(v)[2], size(w)[2])
    fill_width_with_zeros(v, width), fill_width_with_zeros(w, width)
end

function cat_along_dim(v::Vector{Matrix{UInt8}}, dim::Int64=2)
    v_cat = v[1]
    if length(v) > 1
        for i in 2:length(v)
            v_cat = cat(v_cat, v[i], dims=dim)
        end
    end
    v_cat
end

function rotate!(v::Vector{Matrix{UInt8}})
    for i in eachindex(v)
        v[i] = transpose(v[i])
    end
end

function buffer_snapshot(enco::CGPInd, active::Vector{Bool})
    s = enco.buffer[1:enco.n_in]
    b = enco.buffer[enco.n_in+1:end][active[enco.n_in+1:end]]
    rotate!(s)
    rotate!(b)
    n_col = max(length(s), length(b))
    s_cat = cat_along_dim(s)
    b_cat = cat_along_dim(b)
    s_cat, b_cat = width_equalize(s_cat, b_cat)
    cat(s_cat, b_cat, dims=1)
end

function visu_dualcgp_ingame(
    enco::CGPInd,
    redu::Reducer,
    cont::CGPInd,
    game::String,
    seed::Int64,
    max_frames::Int64,
    grayscale::Bool,
    downscale::Bool,
    stickiness::Float64;
    do_save::Bool,
    do_display::Bool
)
    Random.seed!(seed)
    mt = MersenneTwister(seed)
    g = Game(game, seed)
    img_size = size(get_state(g, grayscale, downscale)[1])
    IICGP.reset!(redu) # zero the buffers
    reward = 0.0
    frames = 0
    prev_action = 0
    active = [enco.nodes[i].active for i in eachindex(enco.nodes)]

    # Init rendering buffer
    if do_display
        visu = []
    end

    while ~game_over(g.ale)
        s = get_state(g, grayscale, downscale)
        if rand(mt) > stickiness || frames == 0
            output = IICGP.process(enco, redu, cont, s)
            action = g.actions[argmax(output)]
        else
            action = prev_action
        end

        # Rendering
        if do_display
            snap = buffer_snapshot(enco, active)
            if frames == 0
                visu = snap
            else
                visu = cat(visu, snap, dims=3)
            end
        end

        reward += act(g.ale, action)
        frames += 1
        if frames > max_frames
            break
        end
    end
    close!(g)
    if do_display
        plot_pipeline(visu)
    end
    [reward]
end

function save_graph_struct(
    inds::Array{CGPInd,1},
    saving_dir::String
)
    for ind in inds
        data = Dict()
        data["n_in"] = ind.n_in
        data["n_out"] = ind.n_out
        data["nodes"] = []
        data["fs"] = []
        data["edges"] = []
        data["outputs"] = ind.outputs
        for i in eachindex(ind.nodes)
            is_active = ind.nodes[i].active
            if is_active
                x = ind.nodes[i].x
                fname = String(Symbol(ind.nodes[i].f))
                arity = IICGP.CGPFunctions.arity[fname]
                push!(data["nodes"], i)
                push!(data["fs"], fname)
                push!(data["edges"], (x, i))
                if arity == 2
                    y = ind.nodes[i].y
                    push!(data["edges"], (y, i))
                end
            end
        end
        is_controller = typeof(ind.buffer[1]) == Float64
        graph_name = is_controller ? "controller_graph.yaml" : "encoder_graph.yaml"
        graph_path = joinpath(saving_dir, graph_name)
        YAML.write_file(graph_path, data)
    end
end

function visu_ingame(
    exp_dir::String,
    game::String,
    max_frames::Int64;
    do_save::Bool,
    do_display::Bool
)
    cfg = cfg_from_exp_dir(exp_dir)
    seed = cfg["seed"]
    stickiness = cfg["stickiness"]
    grayscale = cfg["grayscale"]
    downscale = cfg["downscale"]
    is_dualcgp = haskey(cfg, "encoder")
    if is_dualcgp
        enco, redu, cont = get_last_dualcgp(exp_dir, game, cfg)

        if do_save
            save_graph_struct([enco, cont], exp_dir)
        end

        visu_dualcgp_ingame(enco, redu, cont, game, seed, max_frames, grayscale,
                            downscale, stickiness, do_save=do_save,
                            do_display=do_display)
    end
end


min_date = DateTime(2021, 09, 01)
max_date = DateTime(2021, 09, 02)
games = ["boxing"] # ["freeway"]  # pong kung_fu_master freeway assault
reducers = ["pooling"] # Array{String,1}() # ["pooling"]
exp_dirs, games = get_exp_dir(min_date=min_date, max_date=max_date, games=games,
                              reducers=reducers)
max_frames = 10

for i in eachindex(exp_dirs)
    # Generate images
    visu_ingame(exp_dirs[i], games[i], max_frames,
                do_save=true, do_display=false)

    # Launch python script
    # run(`python graphgen.py "$"exp_dir"["i"]"`)
end
