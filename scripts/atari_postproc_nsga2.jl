using IICGP
using Dates


rootdir = joinpath(homedir(), "Documents/git/ICGP-results/")
# rootdir = dirname(@__DIR__)
resdir = joinpath(rootdir, "results/")
#fetch_backup(rootdir, clean=true)

# Filters parameters
min_date = DateTime(2021, 11, 01)
max_date = DateTime(2021, 12, 31)
#savedir_index = 1
labels = Vector{String}()
colors = Vector{Symbol}()
rom_names = ["space_invaders"]
reducers = ["pooling"]
dotime = false
dosave = true
baselines = true

exp_dirs, games = get_exp_dir(
    resdir, min_date=min_date, max_date=max_date, games=rom_names,
    reducers=reducers
)

log = process_nsga2_results(
    exp_dirs, games
)


##
logfile = joinpath(exp_dirs[1], "logs", "logs.csv")
newlogfile = joinpath(exp_dirs[1], "logs", "logs_new.csv")
log = open(logfile)
lines = readlines(log)


##
using Formatting
log_gen = 200
sep = ";"
output = ["date,lib,type,gen_number,rank,fitness,normalized_fitness,reached_frames,dna_id"]
dna_id_int = 1
current_gen = 1

for i in 2:20#length(lines)
    line = lines[i]
    splitted = split(line, ",")
    ngen = splitted[4]
    n_gen = parse(Int64, ngen)
    if n_gen > current_gen
        current_gen = n_gen
        dna_id_int = 1
    end
    if n_gen == 1 || mod(n_gen, log_gen) == 0
        date = splitted[1]
        libr = splitted[2]
        type = splitted[3]
        rank = splitted[5]
        fram = splitted[10]
        splitted = split(line, "[")
        fitn = string('[', split(splitted[2], "]")[1], ']')
        nofi = string('[', split(splitted[3], "]")[1], ']')
        echr = split(splitted[4], "]")[1]
        cchr = split(splitted[5], "]")[1]

        dna_id = Formatting.format("{1:04d}", dna_id_int)
        dna_id_int += 1

        newline = string(date, sep, libr, sep, type, sep, ngen, sep, rank, sep,
                         fitn, sep, nofi, sep, fram, sep, dna_id)
        push!(output, newline)
    end
end

#=
for i in eachindex(pop)
    f = open(Formatting.format("{1}/{2:04d}.dna", path, i), "w+")
    write(f, string(pop[i]))
    close(f)
end
=#

println()
for l in output
    println(l)
end
