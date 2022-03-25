using ArcadeLearningEnvironment
using CartesianGeneticProgramming
using IICGP
using Dates
using Plots
#using LaTeXStrings

IType = Union{Int16,Int32,Int64}

function plot_histograms(
    d::Dict{Any,Any};
    bins::UnitRange{Int64}=0:15,
    xticks::Vector{Int64}=[0,15],
    yticks::Vector{Int64}=[0,8],
    enco_color::Symbol=:firebrick1,
    cont_color::Symbol=:paleturquoise3,
    linecolor::Symbol=:white,
    linewidth::Int64=2,
    legend::Bool=false,
    xtickfontsize::Int64=20,
    ytickfontsize::Int64=20,
    do_display::Bool=true,
    do_save::Bool=true
)
    games = keys(d)
    hs = []
    for g in games
        ids = keys(d[g])
        n_enco_op = Vector{Int64}()
        n_cont_op = Vector{Int64}()
        for id in ids
            n_op_per_action = d[g][id]["n_op_per_action"]
            println(n_op_per_action)
            for a in keys(n_op_per_action)
                push!(n_enco_op, n_op_per_action[a]["enco"])
                push!(n_cont_op, n_op_per_action[a]["cont"])
            end
        end
        max_n_op = max(maximum(n_enco_op), maximum(n_cont_op))
        @assert maximum(bins) > max_n_op
        max_freq = 0
        for n in 0:max_n_op
            max_freq = max(max_freq, count(==(n), n_enco_op)+count(==(n), n_cont_op))
        end
        h = histogram()
        for elt in [
            [n_enco_op, "enco", enco_color],
            [n_cont_op, "cont", cont_color]
        ]
            title = titlecase(replace(g,"_"=>" "))
            yticks = :sparse # ([0,max_freq], [0,max_freq])
            histogram!(h, elt[1], bins=bins, label=elt[2], color=elt[3],
                linecolor=linecolor, linewidth=linewidth, legend=legend,
                xtickfontsize=xtickfontsize, ytickfontsize=ytickfontsize,
                xticks=xticks, yticks=yticks)#, title=title)
        end
        push!(hs, h)
        if do_display
            display(h)
        end
        if do_save
            fname = string("n_op_", g, ".pdf")
            savefig(h, fname)
        end
    end
    #legend = plot([0 0], showaxis=false, grid=false, label=["Encoder operators" "Controller operators"])
    #plot(hs..., layout = (2, 6)) #, legend)
end

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

function scrap_data!(
    d::Dict{Any,Any},
    rom_name::String,
    id::Int64,
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
    d[rom_name][id] = Dict("n_op_per_action"=>n_op_per_action)
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

function get_exp3_dirs(rootdir::String, resdir::String)
    ids = [1,2,3]
    reducers = ["pooling"]
    min_date = DateTime(2022, 02, 23)
    max_date = DateTime(2022, 02, 24)
    games = ["alien", "bowling", "enduro", "pong", "riverraid", "seaquest"]
    exp_dirs, ids, rom_names = get_exp_dir(resdir, min_date=min_date, max_date=max_date,
        games=games, reducers=reducers, ids=ids)
    min_date = DateTime(2022, 02, 08, 15)
    max_date = DateTime(2022, 02, 08, 17)
    games = ["boxing", "asteroids", "solaris", "freeway", "gravitar", "space_invaders"]
    e, i, r = get_exp_dir(resdir, min_date=min_date, max_date=max_date,
        games=games, reducers=reducers, ids=ids)
    push!(exp_dirs, e...)
    push!(ids, i...)
    push!(rom_names, r...)
    exp_dirs, ids, rom_names
end

rootdir = joinpath(homedir(), "Documents/git/ICGP-results/")
resdir = joinpath(rootdir, "results/")
exp_dirs, ids, rom_names = get_exp3_dirs(rootdir, resdir)

#=
min_date = DateTime(2022, 02, 23) # DateTime(2022, 02, 08, 15)
max_date = DateTime(2022, 02, 24) # DateTime(2022, 02, 08, 16)
games = ["pong", "enduro"]
ids = [1,2,3]
reducers = ["pooling"]
exp_dirs, ids, rom_names = get_exp_dir(resdir, min_date=min_date, max_date=max_date,
    games=games, reducers=reducers, ids=ids)
=#

d = Dict() # Contains all the data
for g in rom_names
    d[g] = Dict()
end

# 1. Scrap data for each individual
for i in eachindex(exp_dirs)
    # Fetch best individual
    exp_dir = exp_dirs[i]
    id = ids[i]
    rom_name = rom_names[i]
    cfg = cfg_from_exp_dir(exp_dir)
    enco, redu, cont = get_best_lucie_ind(exp_dir)
    # Get analysis
    scrap_data!(d, rom_name, id, enco, redu, cont, cfg, verbose=false)
end

# 2. Plot data
plot_histograms(d)
