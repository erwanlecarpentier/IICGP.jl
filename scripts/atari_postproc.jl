using IICGP
using Dates

min_date = DateTime(2021, 07, 12)
max_date = DateTime(2021, 07, 16)
# games = Array{String,1}()
games = ["freeway"]  # pong kung_fu_master freeway
reducers = Array{String,1}() # ["pooling"]

exp_dirs, games = get_exp_dir(min_date=min_date, max_date=max_date, games=games,
                             reducers=reducers)
process_results(exp_dirs, games, ma=100)

##
exp_dirs = get_exp_dir()
games = Array{String,1}()
process_results(exp_dirs, games, ma=1)
