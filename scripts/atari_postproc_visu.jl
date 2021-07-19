using IICGP
using Dates
using CartesianGeneticProgramming

min_date = DateTime(2021, 07, 13)
max_date = DateTime(2021, 07, 14)
reducers = ["pooling"]
games = ["pong"]
exp_dirs, games = exp_dir(min_date=min_date, max_date=max_date, games=games,
                      reducers=reducers)

function get_maxgen(dir::String)
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

function get_dualcgp_paths(dir::String)
    maxg = get_maxgen(joinpath(dir, "gens"))
    enco_path = joinpath(dir, "gens", string("encoder_", maxg))
    cont_path = joinpath(dir, "gens", string("controller_", maxg))
    enco_path, cont_path
end


function get_best_dualcgp_paths(dir::String)
    enco_path, cont_path = get_dualcgp_paths(dir)
    encos = readdir(enco_path)
    conts = readdir(cont_path)
    enco_path = joinpath(enco_path, encos[end])
    cont_path = joinpath(cont_path, conts[end])
    enco_path, cont_path
end

function namedtuple(d::Dict{Any,Any})
    NamedTuple{Tuple(Symbol.(keys(d)))}(values(d))
end

##
i = 1

println()  # TODO remove
#for i in eachindex(exp_dirs)
dir = exp_dirs[i]
best_enco_path, best_cont_path = get_best_dualcgp_paths(dir)
cfg = cfg_from_exp_dir(dir)



###
# Get enco redu cont from config path and DNA
encoder_path = best_enco_path
controller_path = best_cont_path
###
enco_cfg = namedtuple(cfg["encoder"])
cont_cfg = namedtuple(cfg["controller"])

println(best_enco_path)
println(best_cont_path)

# cont = CGPInd(cont_cfg, read(controller_path, String))
###




#end
