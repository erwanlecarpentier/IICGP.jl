using IICGP
using Dates

rootdir = "/home/wahara/Documents/git/ICGP-results/"
#rootdir = "/home/opaweynch/Documents/git/ICGP-results/"
resdir = joinpath(rootdir, "results/")
# fetch_backup(rootdir, clean=true)

min_date = DateTime(2021, 09, 01)
max_date = DateTime(2021, 09, 30)
# DateTime(2013,7,1,12,30,59,1)
# games = Array{String,1}()
games = ["breakout"] # ["freeway"]  # pong kung_fu_master freeway assault
reducers = Array{String,1}() # ["pooling"]

exp_dirs, games = get_exp_dir(resdir, min_date=min_date, max_date=max_date,
                              games=games, reducers=reducers)
dotime = false
dosave = true
process_results(exp_dirs, games, dotime, dosave, ma=1)
