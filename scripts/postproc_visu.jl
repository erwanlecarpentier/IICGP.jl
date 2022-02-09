using ArcadeLearningEnvironment
using CartesianGeneticProgramming
using Dates
using IICGP
using Images
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

function save_rgb(game::Game, dir::String, frame::Int64)
    fname = joinpath(dir, string(frame, "_rgb.png"))
    save_screen_png(game, fname)
end

function save_state(s::Vector{Matrix{UInt8}}, dir::String, frame::Int64)
    for i in eachindex(s)
        fname = joinpath(dir, string(frame, "_s", i, ".png"))
        save(fname, transpose(s[i]))
    end
end

function save_enco_buffer(enco::CGPInd, dir::String, frame::Int64)
    for i in eachindex(enco.buffer)
        if i < enco.n_in + 1 || enco.nodes[i].active
            fname = joinpath(dir, string(frame, "_e", i, ".png"))
            save(fname, transpose(enco.buffer[i]))
        end
    end
end

function save_features(f::Vector{Matrix{Float64}}, dir::String, frame::Int64,
                       outputs::Vector{Int16})
    for i in eachindex(f)
        fname = joinpath(dir, string(frame, "_f", outputs[i], ".png"))
        save(fname, transpose(f[i]))
    end
end

function save_cont_buffer(cont::CGPInd, dir::String, frame::Int64)
    data = Dict()
    for i in eachindex(cont.buffer)
        if i < cont.n_in + 1 || cont.nodes[i].active
            data[string(i)] = cont.buffer[i]
        end
    end
    fname = joinpath(dir, string(frame, "_c.yaml"))
    YAML.write_file(fname, data)
end

function save_metadata(metadata::Dict, dir::String, frame::Int64)
    fname = joinpath(dir, string(frame, "_m.yaml"))
    YAML.write_file(fname, metadata)
end

function get_metadata(
    action::T,
    is_sticky::Bool,
    score::Float64,
    e_activated::Vector{Int16},
    e_output::Vector{Int16},
    c_activated::Vector{Int16},
    c_output::Int16
) where {T <: Union{Int32, Int64}}
    metadata = Dict(
        "action"=>action,
        "is_sticky"=>is_sticky,
        "score"=>score,
        "encoder"=>Dict("activated"=>e_activated, "outputs"=>e_output),
        "controller"=>Dict("activated"=>c_activated, "outputs"=>[c_output])
    )
    metadata
end

function recur_activated!(ind, n, activated)
    if !activated[n] # first time seeing this node
        activated[n] = true
        is_input = ind.nodes[n].f == CartesianGeneticProgramming.f_null
        if !is_input
            recur_activated!(ind, ind.nodes[n].x, activated)
            fname = String(Symbol(ind.nodes[n].f))
            arity = IICGP.CGPFunctions.arity[fname]
            if arity > 1
                recur_activated!(ind, ind.nodes[n].y, activated)
            end
        end
    end
end

function find_activated_nodes(ind::CGPInd, out_node::Int16)
    activated = falses(length(ind.nodes))
    recur_activated!(ind, out_node, activated)
    activated_nodes = Vector{Int16}()
    for i in eachindex(activated)
        if activated[i]
            push!(activated_nodes, convert(Int16, i))
        end
    end
    activated_nodes
end

function find_activated_encoder_outputs(
    enco::CGPInd,
    redu::Reducer,
    cont::CGPInd,
    c_activated::Vector{Int16}
)
    @assert redu.parameters["type"] == "pooling"
    fsize = redu.parameters["size"]^2
    e_activated = Vector{Int16}()
    for node in c_activated
        if node < cont.n_in+1 # activated node is a controller input
            activated_enco_output_index = convert(Int64, ceil(node/fsize))
            push!(e_activated, enco.outputs[activated_enco_output_index])
        end
    end
    e_activated
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
    do_display::Bool,
    buffer_path::String
)
    Random.seed!(seed)
    mt = MersenneTwister(seed)
    g = Game(game, seed)
    img_size = size(get_state(g, grayscale, downscale)[1])
    IICGP.reset!(redu) # zero the buffers
    reward = 0.0
    frames = 1
    prev_action = Int32(0)
    prev_chosen_output = 1
    features = Vector{Matrix{Float64}}()
    active = [enco.nodes[i].active for i in eachindex(enco.nodes)]

    # Init rendering buffer
    if do_display
        visu = []
    end

    while ~game_over(g.ale)
        s = get_state(g, grayscale, downscale)
        rgb = get_rgb(g)
        is_sticky = rand(mt) < stickiness
        if frames == 1
            is_sticky = false
        end
        if !is_sticky
            features, output = IICGP.process_f(enco, redu, cont, s)
            chosen_output = argmax(output)
            action = g.actions[chosen_output]
        else
            chosen_output = prev_chosen_output
            action = prev_action
        end

        # Scan which nodes were activated
        c_output = cont.outputs[chosen_output]
        c_activated = find_activated_nodes(cont, c_output)
        e_output = find_activated_encoder_outputs(enco, redu, cont, c_activated)
        e_activated = Vector{Int16}()
        for node in e_output
            push!(e_activated, find_activated_nodes(enco, node)...)
        end

        # Saving
        if do_save
            metadata = get_metadata(action, is_sticky, reward, e_activated,
                                    e_output, c_activated, c_output)
            save_metadata(metadata, buffer_path, frames)
            save_rgb(g, buffer_path, frames)
            save_enco_buffer(enco, buffer_path, frames)
            save_features(features, buffer_path, frames, enco.outputs)
            save_cont_buffer(cont, buffer_path, frames)
        end

        # Rendering
        if do_display
            snap = buffer_snapshot(enco, active)
            if frames == 1
                visu = snap
            else
                visu = cat(visu, snap, dims=3)
            end
        end
        reward += act(g.ale, action)
        frames += 1
        prev_action = action
        prev_chosen_output = chosen_output
        if frames > max_frames
            break
        end
    end
    close!(g)
    if do_display
        plot_pipeline(visu)
    end

    println()
    println("-"^20)
    println("Game             : ", game)
    println("Seed             : ", seed)
    println("Total return     : ", reward)
    println("Number of frames : ", frames)
    println("-"^20)
    reward
end

function save_graph_struct(
    inds::Array{CGPInd,1},
    saving_dir::String,
    actions::Vector{Int32}
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
        if is_controller
            data["actions"] = actions
        end
        graph_name = is_controller ? "controller.yaml" : "encoder.yaml"
        graph_path = joinpath(saving_dir, graph_name)
        YAML.write_file(graph_path, data)
    end
end

function get_minimal_actions_set(game::String)
    g = Game(game, 0)
    actions = g.actions
    close!(g)
    actions
end

function visu_ingame(
    exp_dir::String,
    game::String,
    enco::CGPInd,
    redu::Reducer,
    cont::CGPInd,
    max_frames::Int64;
    do_save::Bool,
    do_display::Bool,
    seed::Int64
)
    cfg = cfg_from_exp_dir(exp_dir)
    # seed = cfg["seed"]
    stickiness = cfg["stickiness"]
    grayscale = cfg["grayscale"]
    downscale = cfg["downscale"]
    is_dualcgp = haskey(cfg, "encoder")
    @assert is_dualcgp
    mini_actions = get_minimal_actions_set(game)
    if do_save
        graph_path = joinpath(exp_dir, "graphs")
        mkpath(graph_path)
        buffer_path = joinpath(exp_dir, "buffers")
        rm(buffer_path, recursive=true, force=true)
        mkpath(buffer_path)
        save_graph_struct([enco, cont], graph_path, mini_actions)
    end
    reward = visu_dualcgp_ingame(
        enco, redu, cont, game, seed, max_frames, grayscale,
        downscale, stickiness, do_save=do_save,
        do_display=do_display, buffer_path=buffer_path
    )
    reward
end

function test_manyvis(
    exp_dir::String,
    game::String,
    max_frames::Int64;
    do_save::Bool,
    do_display::Bool
)
    max_reward = -Inf
    for t = 1:1000
        seed = t
        reward = visu_ingame(exp_dir, game, max_frames, do_save=do_save,
                             do_display=do_display, seed=seed)
        max_reward = max(max_reward, reward)
        if reward > 21
            break
        end
        println("Max total return: ", max_reward)
    end
end

rootdir = joinpath(homedir(), "Documents/git/ICGP-results/")
resdir = joinpath(rootdir, "results/")
min_date = DateTime(2022, 01, 27)
max_date = DateTime(2022, 01, 28)
games = ["boxing", "asteroids", "breakout", "freeway", "gravitar", "riverraid", "space_invaders"]
games = ["boxing"]
ids = [1]
reducers = ["pooling"] # Array{String,1}() # ["pooling"]
exp_dirs, ids, games = get_exp_dir(resdir, min_date=min_date, max_date=max_date,
                              games=games, reducers=reducers, ids=ids)
max_frames = 18000
render_graph = false
seed = 0






enco, redu, cont = get_best_lucie_ind(exp_dirs[1])



##

for i in eachindex(exp_dirs)
    # Fetch individuals
    #enco, redu, cont = get_last_dualcgp(exp_dirs[i])
    enco, redu, cont = get_best_lucie_ind(exp_dirs[i])
    # Generate images (may display / save)
    visu_ingame(exp_dirs[i], games[i], enco, redu, cont, max_frames,
                do_save=true, do_display=false, seed)
    #test_manyvis(exp_dirs[i], games[i], max_frames, do_save=true, do_display=false)

    # Launch python script
    if render_graph
        exp_dir = exp_dirs[i]
        run(`python3.8 pytexgraph.py $exp_dir`)
    end
end
