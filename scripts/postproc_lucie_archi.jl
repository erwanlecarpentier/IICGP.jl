using ArcadeLearningEnvironment
using CartesianGeneticProgramming
using IICGP
using Dates
using Plots

IType = Union{Int16,Int32,Int64}

function recur_count_operation!(
    n_op_per_action::Dict{Any,Any},
    ind_type::String,
    cfg::Dict{Any,Any},
    ind::CGPInd,
    action_index::IType,
    node_index::IType,
    seen_node_indexes::Vector{Any}
)
    # Check if reached enco output
    if ind_type == "cont"
        n_enco_out = cfg["encoder"]["n_out"] * cfg["reducer"]["features_size"]^2
        is_enco_output = node_index < n_enco_out + 1
        if is_enco_output
            n_op_per_action[action_index]["reached_enco_out"] = true
        end
    end
    # Count operation and recur
    is_active = ind.nodes[node_index].active
    fname = String(Symbol(ind.nodes[node_index].f))
    if is_active & (node_index ∉ seen_node_indexes) & (fname != "f_null")
        push!(seen_node_indexes, node_index)
        arity = IICGP.CGPFunctions.arity[fname]
        n_op_per_action[action_index][ind_type] += 1
        x = ind.nodes[node_index].x
        y = ind.nodes[node_index].y
        recur_count_operation!(n_op_per_action, ind_type, cfg, ind,
            action_index, x, seen_node_indexes)
        if arity == 2
            recur_count_operation!(n_op_per_action, ind_type, cfg, ind,
                action_index, y, seen_node_indexes)
        end
    end
end


function archi_analysis(
    rom_name::String,
    enco::CGPInd,
    redu::Reducer,
    cont::CGPInd,
    cfg::Dict{Any,Any};
    seed::Int64=0,
    verbose::Bool=true
)
    @assert redu.parameters["type"] == "pooling"
    g = Game(rom_name, seed)
    n_op_per_action = Dict()
    println() # TRM
    for i in eachindex(g.actions)
        a = g.actions[i]
        output_node_index = cont.outputs[i]
        outenc_node_index = enco.outputs[1]
        n_op_per_action[a] = Dict([("cont", 0), ("enco", 0), ("reached_enco_out", false)])
        seen_node_indexes = []
        recur_count_operation!(n_op_per_action, "cont", cfg, cont, a, output_node_index, seen_node_indexes)
        if n_op_per_action[a]["reached_enco_out"]
            recur_count_operation!(n_op_per_action, "enco", cfg, enco, a, outenc_node_index, seen_node_indexes)
        end
    end
    if verbose
        println("\nNumber of operations per actions:")
        for k in keys(n_op_per_action)
            println(
                k, (k>9 ? " " : "  "),
                ": enco: ", n_op_per_action[k]["enco"],
                "   cont: ", n_op_per_action[k]["cont"],
                "   reached enco: ", n_op_per_action[k]["reached_enco_out"]
            )
        end
    end
end

rootdir = joinpath(homedir(), "Documents/git/ICGP-results/")
resdir = joinpath(rootdir, "results/")
min_date = DateTime(2022, 02, 23) # DateTime(2022, 02, 08, 15)
max_date = DateTime(2022, 02, 24) # DateTime(2022, 02, 08, 16)
#games = ["boxing", "asteroids", "breakout", "freeway", "gravitar", "riverraid", "space_invaders"]
games = ["bowling"]
ids = [1]
reducers = ["pooling"]
exp_dirs, ids, games = get_exp_dir(resdir, min_date=min_date, max_date=max_date,
    games=games, reducers=reducers, ids=ids)
max_frames = 18000 # 18000
render_graph = false
seed = 0

# 1. Process each ind
for i in eachindex(exp_dirs)
    # Fetch best individual
    exp_dir = exp_dirs[i]
    rom_name = games[i]
    cfg = cfg_from_exp_dir(exp_dir)
    enco, redu, cont = get_best_lucie_ind(exp_dir)
    # Get analysis
    archi_analysis(rom_name, enco, redu, cont, cfg)
end
