using IICGP
using Dates
using Plots


rootdir = joinpath(homedir(), "Documents/git/ICGP-results/")
# rootdir = dirname(@__DIR__)
resdir = joinpath(rootdir, "results/")
#fetch_backup(rootdir, clean=true)

# Filters parameters
min_date = DateTime(2022, 02, 08, 14, 20)
max_date = DateTime(2022, 02, 08, 14, 40)
#savedir_index = 1
labels = Vector{String}()
colors = Vector{Symbol}()
rom_names = ["boxing", "gravitar", "freeway", "solaris", "space_invaders", "asteroids"]
rom_names = ["freeway"]
reducers = ["pooling"]
dotime = false
dosave = true
baselines = true

#colors = [:skyblue3]
#labels = ["LUCIE"]
theme(:ggplot2) # :default
for rom_name in rom_names
    exp_dirs, ids, games = get_exp_dir(resdir, min_date=min_date, max_date=max_date,
        games=[rom_name], reducers=reducers)
    process_lucie_results(exp_dirs, games, colors, labels, do_display=true,
        do_save=true)
end
