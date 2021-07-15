using IICGP
using Dates

min_date = DateTime(2021, 07, 13)
max_date = DateTime(2021, 07, 14)
reducers = ["pooling"]
exp_dirs, games = exp_dir(min_date=min_date, max_date=max_date, reducers=reducers)
