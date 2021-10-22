using ArcadeLearningEnvironment
using ArgParse
using Cambrian
using CartesianGeneticProgramming
using Dates
using IICGP
using Random

import Cambrian.mutate # function extension

rom = "gravitar"
seed = 0
rootdir = dirname(@__DIR__)
resdir = joinpath(rootdir, "results/")
cfg_name = "cfg/dualcgpga_atari_pooling.yaml"
mcfg, ecfg, ccfg, reducer, bootstrap = IICGP.dualcgp_config(cfg_name, rom)
Random.seed!(seed)
n_iter = 10

# Extend Cambrian mutate function
function mutate(ind::CGPInd, ind_type::String)
    if ind_type == "encoder"
        return goldman_mutate(ecfg, ind, init_function=IPCGPInd)
    elseif ind_type == "controller"
        return goldman_mutate(ccfg, ind)
    end
end

function fit(e::CGPInd, c::CGPInd, seed::Int64)
    lmin = min(length(e.chromosome), length(c.chromosome))
    lmin = Int64(round(0.05*lmin)) # Only a fractin is counted
    res = 0.0
    for i in 1:lmin
        if abs(e.chromosome[i] - c.chromosome[i]) < 0.001
            res += 1
        end
    end
    return res
end

colors = Vector{Symbol}()
for doem in [false, true]
    for i in 1:n_iter
        mcfg, ecfg, ccfg, reducer, bootstrap = IICGP.dualcgp_config(cfg_name, rom)
        mcfg["eval_mutant"] = doem
        logid = mcfg["id"]
        evo = IICGP.DualCGPGAEvo(mcfg, ecfg, ccfg, fit, logid, rootdir)
        init_backup(logid, rootdir, cfg_name)
        run!(evo)

        if doem
            push!(colors, :red)
        else
            push!(colors, :green)
        end
    end
end





# Postproc

fetch_backup(rootdir, clean=true)

# Filters parameters
min_date = DateTime(2021, 10, 20)
max_date = DateTime(2021, 10, 23)
savedir_index = 1
labels = Vector{String}()
# colors = Vector{Symbol}()
games = ["gravitar"]
reducers = ["pooling"]# Vector{String}()
dotime = false
dosave = true
baselines = false

for g in games
    exp_dirs, games = get_exp_dir(
        resdir, min_date=min_date, max_date=max_date, games=[g],
        reducers=reducers
    )
    process_results(
        exp_dirs, games, dotime, dosave, ma=1, baselines=baselines,
        labels=labels, colors=colors, savedir_index=savedir_index
    )
end
