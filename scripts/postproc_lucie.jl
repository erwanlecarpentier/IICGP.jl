using IICGP
using Dates


rootdir = joinpath(homedir(), "Documents/git/ICGP-results/")
# rootdir = dirname(@__DIR__)
resdir = joinpath(rootdir, "results/")
#fetch_backup(rootdir, clean=true)

# Filters parameters
min_date = DateTime(2022, 01, 27)
max_date = DateTime(2022, 01, 28)
#savedir_index = 1
labels = Vector{String}()
colors = Vector{Symbol}()
rom_names = ["boxing"]
reducers = ["pooling"]
dotime = false
dosave = true
baselines = true

colors = [:skyblue3]
labels = ["LUCIE"]

for rom_name in rom_names
    exp_dirs, games = get_exp_dir(resdir, min_date=min_date, max_date=max_date,
        games=[rom_name], reducers=reducers)
    process_lucie_results(exp_dirs, games, colors, labels)
end
