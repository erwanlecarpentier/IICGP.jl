using CSV
using DataFrames

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
log_header = ["date", "lib", "type", "gen_number", "best", "mean", "std"]

for i in 1:n_games
    file = CSV.File(logs_filenames[i], header=log_header)

    println("Parsing ", rom_names[i])
    println("Number of generations : ", length(file))
    println("Best score 1st generation  :", file[1].best)
    println("Best score end generation  :", file[end].best)
    println()
end
