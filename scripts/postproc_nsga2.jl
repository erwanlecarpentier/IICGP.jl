using IICGP
using Dates


rootdir = joinpath(homedir(), "Documents/git/ICGP-results/")
# rootdir = dirname(@__DIR__)
resdir = joinpath(rootdir, "results/")
#fetch_backup(rootdir, clean=true)

# Filters parameters
min_date = DateTime(2021, 11, 30, 14)
max_date = DateTime(2021, 11, 30, 15)
#savedir_index = 1
labels = Vector{String}()
colors = Vector{Symbol}()
rom_names = ["boxing"]
reducers = ["pooling"]
dotime = false
dosave = true
baselines = true

objectives_names = ["Atari score", "Atari score (≠ seed)"]
pareto_gen = [1, 9000, 17000, 25000]
pareto_xlim = (0, 1)
pareto_ylim = (0, 1)

colors = [:skyblue3]
labels = ["NSGA2"]

for rom_name in rom_names
    exp_dirs, games = get_exp_dir(resdir, min_date=min_date, max_date=max_date,
        games=[rom_name], reducers=reducers)
    process_nsga2_results(exp_dirs, games, objectives_names, colors,
        labels, pareto_gen=pareto_gen, pareto_xlim=pareto_xlim,
        pareto_ylim=pareto_ylim)
end
