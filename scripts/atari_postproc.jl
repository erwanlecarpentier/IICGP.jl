using IICGP
using Dates

rootdir = joinpath(homedir(), "Documents/git/ICGP-results/")
# rootdir = dirname(@__DIR__)
resdir = joinpath(rootdir, "results/")
fetch_backup(rootdir, clean=true)

# Filters parameters
min_date = DateTime(2021, 09, 01)
max_date = DateTime(2021, 10, 02)
savedir_index = 1
labels = Vector{String}()
colors = Vector{Symbol}()
games_12 = ["boxing" "assault" "freeway" "solaris" "defender" "gravitar" "space_invaders" "private_eye" "asteroids" "breakout" "frostbite" "riverraid"]
games = games_12# ["gravitar"]
reducers = ["pooling"]# Vector{String}()
dotime = false
dosave = true

baselines = true

#=
labels = ["1 + λ (\"deterministic\" game)", "GA (stochastic games)"] # Vector{String}()
colors = [:skyblue3, :limegreen] # Vector{Symbol}()
# https://juliagraphics.github.io/Colors.jl/stable/namedcolors/
savedir_index = 2
=#

for g in games
    exp_dirs, games = get_exp_dir(
        resdir, min_date=min_date, max_date=max_date, games=[g],
        reducers=reducers
    )
    process_results(
        exp_dirs, games, dotime, dosave, ma=1, baselines=baselines,
        labels=labels, colors=colors, savedir_index=savedir_index
    )
end
