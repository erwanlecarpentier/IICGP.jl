using IICGP
using Dates

min_date = DateTime(2021, 09, 01)
max_date = DateTime(2021, 09, 02)
# DateTime(2013,7,1,12,30,59,1)
# games = Array{String,1}()
games = ["assault"] # ["freeway"]  # pong kung_fu_master freeway assault
reducers = Array{String,1}() # ["pooling"]

fetch_backup()

exp_dirs, games = get_exp_dir(min_date=min_date, max_date=max_date, games=games,
                              reducers=reducers)
# exp_dirs = [exp_dirs[2], exp_dirs[1]]
process_results(exp_dirs, games, ma=1, save=true)

#=
exp_dirs = get_exp_dir()
games = Array{String,1}()
process_results(exp_dirs, games, ma=1)
=#
