using CSV
using DataFrames
using Dates


# Global variables: never changed
RES_DIR = string(@__DIR__, "/../results/")
LOG_HEADERS = ["date", "lib", "type", "gen_number", "best", "mean", "std"]

"""
Fetch the experiments directories corresponding to a time lapse and specific
games.
"""
function exp_dir(;
    min_date::DateTime=DateTime(0),
    max_date::DateTime=DateTime(0),
    games::Array{String,1}=Array{String,1}()
)
    no_time_lapse = min_date == max_date == DateTime(0)
    no_specified_game = length(games) == 0
    existing_res = readdir(RES_DIR)
    filtered_res = Array{String,1}()
    for exp_dir in existing_res
        exp_date = DateTime(exp_dir[1:23])
        exp_game = exp_dir[25:end]
        if no_time_lapse || (min_date < exp_date < max_date)
            if no_specified_game || (exp_game in games)
                push!(filtered_res, exp_dir)
            end
        end
    end
    filtered_res
end


min_date = DateTime(2021, 07, 13)
max_date = DateTime(2021, 07, 14)
exp_dirs = exp_dir(min_date=min_date, max_date=max_date)

##

function gen_filenames(repo_name, rom_names, seed_value::Int64=0)
    logs_filenames = String[]
    gens_filenames = String[]
    for n in rom_names
        pref = string(@__DIR__, "/../")
        n_f = string(repo_name, n, "_", seed_value)
        log_f = string(pref, "logs/", n_f, "/encoders.csv")
        gen_f = string(pref, "gens/", n_f)
        push!(logs_filenames, log_f)
        push!(gens_filenames, gen_f)
    end
    return logs_filenames, gens_filenames
end


repo_name = "20210526-atari9/"
rom_names = ["boxing", "centipede", "demon_attack", "enduro", "freeway",
             "kung_fu_master", "space_invaders", "riverraid", "pong"]
n_games = length(rom_names)
logs_filenames, gens_filenames = gen_filenames(repo_name, rom_names)

for i in 1:n_games
    file = CSV.File(logs_filenames[i], header=log_header)

    println("Parsing ", rom_names[i])
    println("Number of generations : ", length(file))
    println("Best score 1st generation  :", file[1].best)
    println("Best score end generation  :", file[end].best)
    println()
end
