using CSV
using YAML
using DataFrames
using Dates


# Global variables: never changed
RES_DIR = string(string(@__DIR__)[1:end-length("scripts/")], "/results/")
LOG_HEADER = ["date", "lib", "type", "gen_number", "best", "mean", "std"]

"""
    function exp_dir(
        res_dir::String=RES_DIR;
        min_date::DateTime=DateTime(0),
        max_date::DateTime=DateTime(0),
        games::Array{String,1}=Array{String,1}()
    )

Fetch the experiments directories corresponding to a time lapse and specific
games. If no game list or no dates are provided, return everything.
"""
function exp_dir(
    res_dir::String=RES_DIR;
    min_date::DateTime=DateTime(0),
    max_date::DateTime=DateTime(0),
    games::Array{String,1}=Array{String,1}()
)
    no_time_lapse = min_date == max_date == DateTime(0)
    no_specified_game = length(games) == 0
    existing_res = readdir(res_dir)
    filtered_res = Array{String,1}()
    filtered_games = Array{String,1}()
    for exp_dir in existing_res
        exp_date = DateTime(exp_dir[1:23])
        exp_game = exp_dir[25:end]
        if no_time_lapse || (min_date < exp_date < max_date)
            if no_specified_game || (exp_game in games)
                push!(filtered_res, string(res_dir, exp_dir))
                push!(filtered_games, exp_game)
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

function print_results(exp_dirs::Array{String,1}, games::Array{String,1})
    for i in eachindex(exp_dirs)
        yaml = find_yaml(exp_dirs[i])
        cfg_path = string(exp_dirs[i], "/", yaml)
        cfg = YAML.load_file(cfg_path)
        log_file = string(exp_dirs[i], "/logs/encoders.csv")
        log = CSV.File(log_file, header=LOG_HEADER)

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
        push!(p, ["Reducer", cfg["reducer"]["type"]])
        if cfg["reducer"]["type"] == "centroid"
            push!(p, ["  - n_centroids", cfg["reducer"]["n_centroids"]])
        else
            push!(p, ["  - features_size", cfg["reducer"]["features_size"]])
            push!(p, ["  - pooling_function", cfg["reducer"]["pooling_function"]])
        end
        println()
        l = maximum([length(k) for k in [pr[1] for pr in p]])
        for k in p
            println(string(k[1], " "^(l-length(k[1])), " : ", k[2]))
        end
    end
end

min_date = DateTime(2021, 07, 13)
max_date = DateTime(2021, 07, 14)
exp_dirs, games = exp_dir(min_date=min_date, max_date=max_date)
exp_dirs, games = exp_dir()
print_results(exp_dirs, games)
