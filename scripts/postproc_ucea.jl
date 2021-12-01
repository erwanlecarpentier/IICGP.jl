using IICGP
using Dates


rootdir = joinpath(homedir(), "Documents/git/ICGP-results/")
# rootdir = dirname(@__DIR__)
resdir = joinpath(rootdir, "results/")
#fetch_backup(rootdir, clean=true)

# Filters parameters
min_date = DateTime(2021, 11, 30, 15)
max_date = DateTime(2021, 11, 31)
#savedir_index = 1
labels = Vector{String}()
colors = Vector{Symbol}()
rom_names = ["boxing"]
reducers = ["pooling"]
dotime = false
dosave = true
baselines = true


colors = [:skyblue3]
labels = ["UCEA"]

for rom_name in rom_names
    exp_dirs, games = get_exp_dir(resdir, min_date=min_date, max_date=max_date,
        games=[rom_name], reducers=reducers)
    exp_dirs = [exp_dirs[2]]
    games = [games[2]]
    process_ucea_results(exp_dirs, games, objectives_names, colors, labels,
        pareto_gen=pareto_gen, pareto_xlim=pareto_xlim, pareto_ylim=pareto_ylim)
end
