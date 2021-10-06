using IICGP
using Dates

rootdir = joinpath(homedir(), "Documents/git/ICGP-results/")
resdir = joinpath(rootdir, "results/")
fetch_backup(rootdir, clean=true)

# Filters parameters
min_date = DateTime(2021, 09, 01)
max_date = DateTime(2021, 10, 02)
games = ["boxing"]
games_12 = ["boxing" "assault" "freeway" "solaris" "defender" "gravitar" "space_invaders" "private_eye" "asteroids" "breakout" "frostbite" "riverraid"]
reducers = Array{String,1}()
dotime = false
dosave = true

for g in games_12
    exp_dirs, games = get_exp_dir(resdir, min_date=min_date, max_date=max_date,
                                  games=[g], reducers=reducers)
    process_results(exp_dirs, games, dotime, dosave, ma=1)
end
