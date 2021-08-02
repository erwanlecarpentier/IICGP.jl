export get_exp_dir, get_exp_path, get_bootstrap_paths, get_best_individuals_paths
export init_backup, fetch_backup
export find_yaml, cfg_from_exp_dir, log_from_exp_dir

using CSV
using YAML
# using DataFrames
using Dates
using Plots

# Global variables, never changed
RES_DIR = string(string(@__DIR__)[1:end-length("src/")], "/results/")
LOG_HEADER = ["date", "lib", "type", "gen_number", "best", "mean", "std"]


function init_backup(logid::String, cfg_path::String)
    println("init")
end


"""
Fetch the saved results and reorganise them.
"""
function fetch_backup(logid::String, cfg_path::String)
    ind_log = string(logid, ".csv")
    log_path = joinpath("logs", ind_log)
    gens_dir = joinpath("gens", logid)

    new_resu_dir = joinpath(RES_DIR, logid)
    new_log_dir = joinpath(new_resu_dir, "logs")
    new_gens_dir = joinpath(new_resu_dir, "gens/")
    mkdir(new_resu_dir)
    mkdir(new_log_dir)
    mkdir(new_gens_dir)
    new_cfg_path = joinpath(new_resu_dir, cfg_path[length("cfg/")+1:end])
    cp(cfg_path, new_cfg_path, force=true)
    new_log_path = joinpath(new_log_dir, "controller.csv")
    cp(log_path, new_log_path, force=true)
    for g in readdir(gens_dir)
        g_dir = joinpath(new_gens_dir, string("controller_", g))
        mkdir(g_dir)
        mv(joinpath(gens_dir, g), g_dir, force=true)
    end
end

"""
Fetch the saved results and reorganise them.
"""
function fetch_backup(logid::String, ind_name::String, cfg_path::String)
    ind_log = string(ind_name, ".csv")
    logs_path = joinpath("logs", logid, ind_log)
    gens_path = joinpath("gens", logid)
    new_resu_dir = joinpath(RES_DIR, logid)
    new_logs_dir = joinpath(new_resu_dir, "logs")
    new_gens_dir = joinpath(new_resu_dir, "gens/")
    mkdir(new_resu_dir)
    mkdir(new_logs_dir)
    mkdir(new_gens_dir)
    new_logs_path = joinpath(new_logs_dir, ind_log)
    new_cfg_path = joinpath(new_resu_dir, cfg_path[length("cfg/")+1:end])
    cp(cfg_path, new_cfg_path, force=true)
    mv(logs_path, new_logs_path, force=true)
    for g in readdir(gens_path)
        if g[1:length(ind_name)] == ind_name
            g_dir = joinpath(new_gens_dir, g)
            mkdir(g_dir)
            mv(joinpath(gens_path, g), g_dir, force=true)
        end
    end
end

"""
    get_exp_dir(game_name::String)

Get a new experiment directory.
"""
function get_exp_path(game_name::String)
    exp_dir = string(Dates.now(), "_", game_name)
    joinpath(RES_DIR, exp_dir)
end

"""
    function get_exp_dir(
        res_dir::String=RES_DIR;
        min_date::DateTime=DateTime(0),
        max_date::DateTime=DateTime(0),
        games::Array{String,1}=Array{String,1}(),
        reducers::Array{String,1}=Array{String,1}()
    )

Fetch the experiments directories corresponding to a time lapse, specific
games and specific reducers. If no game list / no reducers list / no dates are
provided, return everything.

Example:

    using Dates
    exp_dirs, games = exp_dir(
        min_date=DateTime(2021, 07, 12),
        max_date=DateTime(2021, 07, 15),
        games=["freeway"],
        reducers=["pooling"]
    )
"""
function get_exp_dir(
    res_dir::String=RES_DIR;
    min_date::DateTime=DateTime(0),
    max_date::DateTime=DateTime(0),
    games::Array{String,1}=Array{String,1}(),
    reducers::Array{String,1}=Array{String,1}()
)
    no_time_lapse = min_date == max_date == DateTime(0)
    no_specified_games = length(games) == 0
    no_specified_reducers = length(reducers) == 0
    existing_res = readdir(res_dir)
    filtered_res = Array{String,1}()
    filtered_games = Array{String,1}()
    for exp_dir in existing_res
        exp_date = DateTime(exp_dir[1:23])
        exp_game = exp_dir[25:end]
        if no_time_lapse || (min_date < exp_date < max_date)
            if no_specified_games || (exp_game in games)
                exp_full_path = string(res_dir, exp_dir)
                cfg = cfg_from_exp_dir(exp_full_path)
                if no_specified_reducers || (cfg["reducer"]["type"] in reducers)
                    push!(filtered_res, exp_full_path)
                    push!(filtered_games, exp_game)
                end
            end
        end
    end
    filtered_res, filtered_games
end

function are_same_cfg(cfg_a::NamedTuple, cfg_b::NamedTuple)
    if keys(cfg_a) != keys(cfg_b)
        false
    else
        for k in keys(cfg_a)
            if (k != :id) && (cfg_a[k] != cfg_b[k])
                false
            end
        end
    end
    true
end

"""
    get_best_individuals_paths(exp_dir::String)

Given the experiment directory, return the paths of the last saved encoder and
controller.
"""
function get_best_individuals_paths(exp_dir::String)
    gens_dir = joinpath(exp_dir, "gens")
    n_gen = readdir(gens_dir)[end]  # Last subdir in alphabetical order
    n_gen = n_gen[length("encoder_")+1:end]  # Gen number as a String
    enco_dna_path = joinpath(exp_dir, "gens", string("encoder_", n_gen))
    cont_dna_path = joinpath(exp_dir, "gens", string("controller_", n_gen))
    n_indiv = length(readdir(enco_dna_path))
    dna_file_length = maximum([length(p) for p in readdir(enco_dna_path)]) - length(".dna")
    dna_file = string(lpad(n_indiv, dna_file_length, "0"), ".dna")
    enco_dna_path = joinpath(enco_dna_path, dna_file)
    cont_dna_path = joinpath(cont_dna_path, dna_file)
    enco_dna_path, cont_dna_path
end

"""
TODO
"""
function get_bootstrap_paths(
    enco_cfg::NamedTuple,
    cont_cfg::NamedTuple,
    game::String
)
    enco_bs_path = RES_DIR
    cont_bs_path = RES_DIR

    dirs = readdir(RES_DIR)
    filter!(e -> e[end-length("nobootstrap")+1:end] != "nobootstrap", dirs)

    for dir in dirs
        exp_dir = joinpath(RES_DIR, dir)
        cfg_dir = cfg_from_exp_dir(exp_dir)
        _, ecfg, ccfg, _, _ = dualcgp_config(cfg_dir, game)
        println()
        println("________________________________________________")
        println(are_same_cfg(enco_cfg, ecfg))
        println(are_same_cfg(cont_cfg, ccfg))
        println("________________________________________________")
        println(exp_dir)
        println("________________________________________________")
    end
    enco_bs_path, cont_bs_path
end

"""
    find_yaml(path::String)

Find first `.yaml` file at given path.
"""
function find_yaml(path::String)
    for d in readdir(path)
        if d[end-4:end] == ".yaml"
            return d
        end
    end
end

"""
    cfg_from_exp_dir(exp_dir::String)

Get configuration file at specified experiment directory.
"""
function cfg_from_exp_dir(exp_dir::String)
    yaml = find_yaml(exp_dir)
    cfg_path = string(exp_dir, "/", yaml)
    YAML.load_file(cfg_path)
end

"""
    cfg_from_exp_dir(exp_dir::String)

Get log file at specified experiment directory. Precisely, return the encoder's
log file.
"""
function log_from_exp_dir(exp_dir::String)
    log_file = joinpath(exp_dir, "logs/encoder.csv")
    CSV.File(log_file, header=LOG_HEADER)
end
