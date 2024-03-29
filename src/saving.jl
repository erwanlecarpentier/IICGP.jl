export get_exp_dir, get_exp_path, get_bootstrap_paths
export get_last_dualcgp_paths, get_last_ind_path
export get_ec_dna_paths
export parse_log_entry
export init_backup, fetch_backup
export find_yaml, cfg_from_exp_dir, log_from_exp_dir

export LOG_HEADER, NSGA2_LOG_HEADER

using CSV
using YAML
# using DataFrames
using Dates
using Plots


LOG_HEADER = ["date", "lib", "type", "gen_number", "best", "mean", "std"]
NSGA2_LOG_HEADER = ["date", "lib", "type", "gen_number", "rank", "fitness",
                    "normalized_fitness", "reached_frames", "dna_id"]


function init_backup(logid::String, resdir::String, cfg_path::String)
    #new_resu_dir = joinpath(resdir, "results", logid)
    #new_logs_dir = joinpath(new_resu_dir, "logs")
    #new_gens_dir = joinpath(new_resu_dir, "gens")
    #mkdir(new_resu_dir)
    #mkdir(new_logs_dir)
    #mkdir(new_gens_dir)
    #new_cfg_path = joinpath(new_resu_dir, cfg_path[length("cfg/")+1:end])
    expdir = joinpath(resdir, logid)
    mkpath(joinpath(expdir, "logs"))
    mkpath(joinpath(expdir, "gens"))
    new_cfg_path = joinpath(expdir, "logs", basename(cfg_path))
    cp(cfg_path, new_cfg_path, force=true)
end

logsdir_from_logid(logid::String, resdir::String) = joinpath(resdir, "results", logid, "logs")
gensdir_from_logid(logid::String, resdir::String) = joinpath(resdir, "results", logid, "gens")

"""
    fetch_backup(rootdir::String)

Fetch all the data in `logs/` and `gens/` and copy them to `results/`.
Assumes the function `init_backup` to be run previously to the evolution.
Corresponding files are found using unique logid.
"""
function fetch_backup(rootdir::String; clean::Bool=false)
    each_log_name = Array{String,1}()
    each_log_id = Array{String,1}()
    each_log_dir = Array{String,1}()
    each_gen_dir = Array{String,1}()
    each_log_new_name = Array{String,1}()
    logsdir = joinpath(rootdir, "logs")
    gensdir = joinpath(rootdir, "gens")
    for l in setdiff(readdir(logsdir), ["placeholder.txt"])
        is_csv = endswith(l, ".csv")
        id = is_csv ? l[1:end-length(".csv")] : l
        if is_csv
            push!(each_log_name, l)
            push!(each_log_id, id)
            push!(each_log_new_name, "controller.csv")
        else
            log_dir = joinpath(logsdir, l)
            push!(each_log_dir, log_dir)
            for p in readdir(log_dir)
                push!(each_log_name, joinpath(l, p))
                push!(each_log_id, id)
                push!(each_log_new_name, p)
            end
        end
    end
    # Move all logs
    for i in eachindex(each_log_name)
        old_logfile = joinpath(logsdir, each_log_name[i])
        new_logdir = logsdir_from_logid(each_log_id[i], rootdir)
        new_logfile = joinpath(new_logdir, each_log_new_name[i])
        mkpath(new_logdir)  # Make path if not created
        cp(old_logfile, new_logfile, force=true)
    end
    # Delete all log files
    if clean
        for d in each_log_dir
            rm(d, recursive=true, force=true)
        end
    end

    for id in setdiff(readdir(gensdir), ["placeholder.txt"])
        gen_dir = joinpath(gensdir, id)
        push!(each_gen_dir, gen_dir)
        for g in readdir(gen_dir)
            old_genpath = joinpath(gensdir, id, g)
            if startswith(g, "encoder_") || startswith(g, "controller_")
                new_filename = g
            else
                new_filename = string("controller_", g)
            end
            new_gendir = gensdir_from_logid(id, rootdir)
            mkpath(new_gendir)  # Make path if not created
            new_genpath = joinpath(new_gendir, new_filename)
            cp(old_genpath, new_genpath, force=true)
        end
    end
    # Delete all gen files
    if clean
        for d in each_gen_dir
            rm(d, recursive=true, force=true)
        end
    end
end

"""
    get_exp_dir(game_name::String)

Get a new experiment directory.
"""
function get_exp_path(game_name::String, resdir::String)
    exp_dir = string(Dates.now(), "_", game_name)
    joinpath(resdir, exp_dir)
end

function parse_log_entry(exp_dir::String)
    dir = basename(exp_dir)
    splt1 = findnext('_', dir, 1)
    splt2 = findnext('_', dir, splt1+1)
    exp_date = DateTime(dir[1:splt1-1])
    exp_id = parse(Int64, dir[splt1+1:splt2-1])
    exp_game = dir[splt2+1:end]
    exp_date, exp_id, exp_game
end
"""
    function get_exp_dir(
        resdir::String;
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
        resdir,
        min_date=DateTime(2021, 07, 12),
        max_date=DateTime(2021, 07, 15),
        games=["freeway"],
        reducers=["pooling"]
    )
"""
function get_exp_dir(
    resdir::String;
    min_date::DateTime=DateTime(0),
    max_date::DateTime=DateTime(0),
    games::Vector{String}=Vector{String}(),
    reducers::Vector{String}=Vector{String}(),
    ids::Vector{Int64}=Vector{Int64}()
)
    no_time = min_date == max_date == DateTime(0)
    no_specified_games = length(games) == 0
    no_specified_ids = length(ids) == 0
    no_specified_reducers = length(reducers) == 0
    existing_res = readdir(resdir)
    filtered_res = Array{String,1}()
    filtered_id = Array{Int64,1}()
    filtered_games = Array{String,1}()
    for exp_dir in existing_res
        exp_date, exp_id, exp_game = parse_log_entry(exp_dir)
        if no_time || (min_date < exp_date < max_date)
            if no_specified_games || (exp_game in games)
                exp_full_path = string(resdir, exp_dir)
                cfg = cfg_from_exp_dir(exp_full_path)
                if no_specified_reducers || (cfg["reducer"]["type"] in reducers)
                    if no_specified_ids || exp_id ∈ ids
                        push!(filtered_res, exp_full_path)
                        push!(filtered_id, exp_id)
                        push!(filtered_games, exp_game)
                    end
                end
            end
        end
    end
    if length(filtered_res) == 0
        throw(ArgumentError("No experiment matching your criteria found."))
    end
    filtered_res, filtered_id, filtered_games
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
    get_last_ind_path(exp_dir::String, indname::String)

Given the experiment directory, return the path of the last saved individual.
The argument `indname` specifies the name of the individual, which should have
the following form: `string(indname, "_", max_gen_str)``.
"""
function get_last_ind_path(exp_dir::String, indname::String)
    gens_dir = joinpath(exp_dir, "gens")
    max_gen = 0
    max_gen_str = ""
    for g in readdir(gens_dir)
        if startswith(g, indname)
            gen_str = g[length(indname)+2:end]
            gen = parse(Int64, gen_str)
            if gen > max_gen
                max_gen = gen
                max_gen_str = gen_str
            end
        end
    end
    dna_dir = joinpath(gens_dir, string(indname, "_", max_gen_str))
    n_ind = length(readdir(dna_dir))
    dna_filename_length = maximum([length(p) for p in readdir(dna_dir)]) - length(".dna")
    dna_file = string(lpad(n_ind, dna_filename_length, "0"), ".dna")
    dna_path = joinpath(dna_dir, dna_file)
    dna_path
end

function get_ind_dna_path(
    exp_dir::String,
    ind_name::String,
    gen::String,
    dna_id::String
)
    folder = string(ind_name, "_", gen)
    file = string(dna_id, ".dna")
    joinpath(exp_dir, "gens", folder, file)
end

function get_ec_dna_paths(exp_dir::String, gen::String, dna_id::String)
    enco_dna_path = get_ind_dna_path(exp_dir, "encoder", gen, dna_id)
    cont_dna_path = get_ind_dna_path(exp_dir, "controller", gen, dna_id)
    enco_dna_path, cont_dna_path
end

"""
    get_best_individuals_paths(exp_dir::String)

Given the experiment directory, return the paths of the last saved encoder and
controller.
"""
function get_last_dualcgp_paths(exp_dir::String)
    enco_dna_path = get_last_ind_path(exp_dir, "encoder")
    cont_dna_path = get_last_ind_path(exp_dir, "controller")
    enco_dna_path, cont_dna_path
end

"""
    get_bootstrap_paths(
        resdir::String,
        enco_cfg::NamedTuple,
        cont_cfg::NamedTuple,
        game::String
    )

Deprecated.
Get path to bootstrap individuals for re-starting evolution from a previously
reached stage.
"""
function get_bootstrap_paths(
    resdir::String,
    enco_cfg::NamedTuple,
    cont_cfg::NamedTuple,
    game::String
)
    enco_bs_path = resdir
    cont_bs_path = resdir

    dirs = readdir(resdir)
    filter!(e -> e[end-length("nobootstrap")+1:end] != "nobootstrap", dirs)

    for dir in dirs
        exp_dir = joinpath(resdir, dir)
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
        if endswith(d, ".yaml")
            return d
        end
    end
end

"""
    cfg_from_exp_dir(exp_dir::String)

Get configuration file at specified experiment directory.
"""
function cfg_from_exp_dir(exp_dir::String)
    cfg_dir = joinpath(exp_dir, "logs")
    yaml = find_yaml(cfg_dir)
    if yaml == nothing
        cfg_dir = exp_dir
        yaml = find_yaml(cfg_dir)
    end
    cfg_path = joinpath(cfg_dir, yaml)
    YAML.load_file(cfg_path)
end

"""
    log_from_exp_dir(
        exp_dir::String;
        log_file::String="logs/controller.csv",
        log_header::Vector{String}=LOG_HEADER
    )

Get log file at specified experiment directory.
Default: return the controller's log file.
"""
function log_from_exp_dir(
    exp_dir::String;
    log_file::String="logs/controller.csv",
    header::Union{Int64,Vector{String}}=LOG_HEADER,
    sep::String=","
)
    log_file = joinpath(exp_dir, log_file)
    CSV.File(log_file, header=header, delim=sep)
end
