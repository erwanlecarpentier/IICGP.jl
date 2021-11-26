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
rom_names = ["boxing"]#, "space_invaders"]
reducers = ["pooling"]
dotime = false
dosave = true
baselines = true

objectives_names = ["Atari score", "Sparsity"]
pareto_gen = [1, 9000, 17000, 25000]
pareto_xlim = (-1, 1)
pareto_ylim = (0, 1)

colors = [:skyblue3]
labels = ["NSGA2"]

for rom_name in rom_names
    exp_dirs, games = get_exp_dir(resdir, min_date=min_date, max_date=max_date,
        games=[rom_name], reducers=reducers)
    process_nsga2_results(exp_dirs, games, objectives_names, colors, labels,
        pareto_gen=pareto_gen, pareto_xlim=pareto_xlim, pareto_ylim=pareto_ylim)
end

#=
exp_dir = exp_dirs[1]
rom_name = games[1]
logfile = joinpath(exp_dir, "logs", "logs.csv")
newlogfile = joinpath(exp_dir, "logs", "logs_new.csv")
log = open(logfile)
lines = readlines(log)

cfg_dir = joinpath(exp_dir, "logs")
yaml = find_yaml(cfg_dir)
if yaml == nothing
    cfg_dir = exp_dir
    yaml = find_yaml(cfg_dir)
end
cfg_path = joinpath(cfg_dir, yaml)
#cfg = cfg_from_exp_dir(exp_dirs[1])
mcfg, ecfg, ccfg, reducer, bootstrap = IICGP.dualcgp_config(cfg_path, rom_name)

using Formatting
using CartesianGeneticProgramming

log_gen = 200
sep = ";"
newlog = ["date,lib,type,gen_number,rank,fitness,normalized_fitness,reached_frames,dna_id"]
dna_id_int = 1
current_gen = 1

for i in 2:length(lines)
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
        fitn = replace(fitn, " " => "")
        nofi = replace(nofi, " " => "")
        echr = split(splitted[4], "]")[1]
        cchr = split(splitted[5], "]")[1]
        dna_id = Formatting.format("{1:04d}", dna_id_int)
        dna_id_int += 1
        newline = string(date, sep, libr, sep, type, sep, ngen, sep, rank, sep,
                         fitn, sep, nofi, sep, fram, sep, dna_id)
        push!(newlog, newline)

        echr = [parse(Float64, chr) for chr in split(echr, ",")]
        cchr = [parse(Float64, chr) for chr in split(cchr, ",")]

        enco = IPCGPInd(ecfg, echr)
        cont = CGPInd(ccfg, cchr)

        myfit = [parse(Float64, split(nofi, ",")[1][2:end]),
                 parse(Float64, split(nofi, ",")[2][1:end-1])]
        enco.fitness .= myfit
        cont.fitness .= myfit

        enco_path = joinpath(exp_dir, Formatting.format("gens/encoder_{1:04d}", n_gen))
        cont_path = joinpath(exp_dir, Formatting.format("gens/controller_{1:04d}", n_gen))
        mkpath(enco_path)
        mkpath(cont_path)

        f = open(string(enco_path, "/", dna_id, ".dna"), "w+")
        write(f, string(enco))
        close(f)

        f = open(string(cont_path, "/", dna_id, ".dna"), "w+")
        write(f, string(cont))
        close(f)
    end
end

# Gather all lines in a single string
println()
output = ""
for i in eachindex(newlog)
    println(newlog[i])
    lb = i > 1 ? '\n' : ""
    output = string(output, lb, newlog[i])
end

# Output to file
f = open(newlogfile, "w+")
write(f, output)
close(f)
=#
