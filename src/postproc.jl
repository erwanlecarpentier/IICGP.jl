export exp_dir, find_yaml, cfg_from_exp_dir, log_from_exp_dir, process_results

using CSV
using YAML
# using DataFrames
using Dates
using Plots
using ImageFiltering
using OffsetArrays

# Global variables: never changed
RES_DIR = string(string(@__DIR__)[1:end-length("src/")], "/results/")
LOG_HEADER = ["date", "lib", "type", "gen_number", "best", "mean", "std"]

"""
    function exp_dir(
        res_dir::String=RES_DIR;
        min_date::DateTime=DateTime(0),
        max_date::DateTime=DateTime(0),
        games::Array{String,1}=Array{String,1}()
    )

Fetch the experiments directories corresponding to a time lapse, specific
games and specific reducers. If no game list / no reducers list / no dates are
provided, return everything.
"""
function exp_dir(
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

"""
Find first `.yaml` file at given path.
"""
function find_yaml(path::String)
    for d in readdir(path)
        if d[end-4:end] == ".yaml"
            return d
        end
    end
end

function cfg_from_exp_dir(exp_dir::String)
    yaml = find_yaml(exp_dir)
    cfg_path = string(exp_dir, "/", yaml)
    YAML.load_file(cfg_path)
end

function log_from_exp_dir(exp_dir::String)
    log_file = joinpath(exp_dir, "logs/encoders.csv")
    CSV.File(log_file, header=LOG_HEADER)
end

"""
    function process_results(
        exp_dirs::Array{String,1},
        games::Array{String,1};
        ma::Int64=1
    )

Main results plot/print method.
"""
function process_results(
    exp_dirs::Array{String,1},
    games::Array{String,1};
    ma::Int64=1
)
    # Init graphs
    xl = "Generation"
    plt_best = plot(ylabel="Best score", xlabel=xl)
    plt_mean = plot(ylabel="Mean score", xlabel=xl)

    for i in eachindex(exp_dirs)
        cfg = cfg_from_exp_dir(exp_dirs[i])
        log = log_from_exp_dir(exp_dirs[i])

        # Plots
        reducer_type = cfg["reducer"]["type"]
        label_i = string(games[i], ' ',reducer_type)
        kernel = OffsetArray(fill(1/(2*ma+1), 2*ma+1), -ma:ma)
        best = (ma == 1) ? log.best : imfilter(log.best, kernel)
        mean = (ma == 1) ? log.mean : imfilter(log.mean, kernel)
        std = (ma == 1) ? log.std : imfilter(log.std, kernel)
        println(best == log.best)
        plot!(plt_best, best, label=label_i)
        plot!(plt_mean, mean, ribbon=std, label=label_i)

        # Print everything
        p = []
        push!(p, ["Game", games[i]])
        push!(p, ["Number gen", length(log) * cfg["save_gen"]])
        push!(p, ["1st gen", ""])
        push!(p, ["  - best", log[1].best])
        push!(p, ["  - mean", log[1].mean])
        push!(p, ["  - std", log[1].std])
        push!(p, ["end gen", ""])
        push!(p, ["  - best", log[end].best])
        push!(p, ["  - mean", log[end].mean])
        push!(p, ["  - std", log[end].std])
        push!(p, ["Reducer", reducer_type])
        if cfg["reducer"]["type"] == "centroid"
            push!(p, ["  - n_centroids", cfg["reducer"]["n_centroids"]])
        else
            push!(p, ["  - features_size", cfg["reducer"]["features_size"]])
            push!(p, ["  - pooling_function", cfg["reducer"]["pooling_function"]])
        end
        l = maximum([length(k) for k in [pr[1] for pr in p]])
        println()
        for k in p
            println(string(k[1], " "^(l-length(k[1])), " : ", k[2]))
        end
    end
    display(plt_best)
    display(plt_mean)
end
