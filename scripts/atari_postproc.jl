using IICGP
using Dates

min_date = DateTime(2021, 07, 13)
max_date = DateTime(2021, 07, 14)
games = Array{String,1}()
reducers = ["pooling"]
exp_dirs, games = exp_dir(min_date=min_date, max_date=max_date, games=games,
                          reducers=reducers)
print_results(exp_dirs, games)
