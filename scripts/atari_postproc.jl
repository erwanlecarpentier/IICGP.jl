using IICGP
using Dates

min_date = DateTime(2021, 08, 05)
max_date = DateTime(2021, 08, 11)
# games = Array{String,1}()
games = ["riverraid"] # ["freeway"]  # pong kung_fu_master freeway assault
reducers = Array{String,1}() # ["pooling"]

fetch_backup()

exp_dirs, games = get_exp_dir(min_date=min_date, max_date=max_date, games=games,
                              reducers=reducers)

process_results(exp_dirs, games, ma=1)

#=
exp_dirs = get_exp_dir()
games = Array{String,1}()
process_results(exp_dirs, games, ma=1)
=#
