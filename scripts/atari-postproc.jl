
function gen_filenames(repo_name, rom_names, seed_value::Int64=0)
    logs_filenames = String[]
    gens_filenames = String[]
    for n in rom_names
        n_f = string(repo_name, n, "_", seed_value)
        log_f = string("logs/", n_f)
        gen_f = string("gens/", n_f)
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
