using ArcadeLearningEnvironment
using CartesianGeneticProgramming
using IICGP
using Dates
using Plots

function recur_count_operation!(
    n_op_per_action::Dict{Any,Any},
    ind::CGPInd,
    action_index::Union{Int16,Int32,Int64},
    node_index::Union{Int16,Int32,Int64}
)
    is_active = ind.nodes[node_index].active
    if is_active
        fname = String(Symbol(ind.nodes[node_index].f))
        arity = IICGP.CGPFunctions.arity[fname]
        n_op_per_action[action_index] += 1
        x = ind.nodes[node_index].x
        y = ind.nodes[node_index].y
        #recur_count_operation!(n_op_per_action, ind, action_index, x)
        #if arity == 2
        #    recur_count_operation!(n_op_per_action, ind, action_index, y)
        #end
    end
end


function archi_analysis(
    rom_name::String,
    enco::CGPInd,
    redu::Reducer,
    cont::CGPInd;
    seed::Int64=0,
    verbose::Bool=true
)
    @assert redu.parameters["type"] == "pooling"
    g = Game(rom_name, seed)
    n_op_per_action = Dict()
    println() # TRM
    for i in eachindex(g.actions)
        a = g.actions[i]
        n_op_per_action[a] = 0
        output_index = cont.outputs[i]
        println(a, " ", output_index) # TRM
        recur_count_operation!(n_op_per_action, cont, a, output_index)
    end
    n_op_per_action
    if verbose
        println()
        for k in keys(n_op_per_action)
            println(k, (k>9 ? " " : "  "), ": ", n_op_per_action[k])
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
    enco, redu, cont = get_best_lucie_ind(exp_dir)
    # Get analysis
    archi_analysis(rom_name, enco, redu, cont)
end
