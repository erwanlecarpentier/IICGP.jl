using IICGP
using Dates

min_date = DateTime(2021, 07, 13)
max_date = DateTime(2021, 07, 14)
reducers = ["pooling"]
games = ["pong"]
exp_dirs, _ = exp_dir(min_date=min_date, max_date=max_date, games=games,
                      reducers=reducers)
# exp_dirs, _ = exp_dir()

function maxgen(dir::String)
    inddir = readdir(dir)
    filter!(i->(i[1] == 'e'), inddir)
    maxg = maximum([parse(Int64, i[length("encoder_")+1:end]) for i in inddir])
    if maxg < 100
        return string("00", maxg)
    elseif maxg < 1000
        return string("0", maxg)
    else
        return string(maxg)
    end
end


for dir in exp_dirs
    maxg = maxgen(joinpath(dir, "gens"))
    enco_path = joinpath(dir, "gens", string("encoder_", maxg))
    cont_path = joinpath(dir, "gens", string("controller_", maxg))

    println(enco_path)
    println(cont_path)
end
