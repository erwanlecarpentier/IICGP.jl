using IICGP
using Dates

min_date = DateTime(2021, 07, 12)
max_date = DateTime(2021, 07, 16)
# games = Array{String,1}()
games = ["freeway"]  # pong kung_fu_master freeway
reducers = Array{String,1}() # ["pooling"]

exp_dirs, games = exp_dir(min_date=min_date, max_date=max_date, games=games, reducers=reducers)
# exp_dirs, games = exp_dir()
process_results(exp_dirs, games, ma=10)
