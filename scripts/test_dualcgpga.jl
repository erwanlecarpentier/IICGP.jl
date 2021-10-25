using ArcadeLearningEnvironment
using ArgParse
using Cambrian
using CartesianGeneticProgramming
using Dates
using IICGP
using Random

import Cambrian.mutate # function extension

function fit(e::CGPInd, c::CGPInd, seed::Int64)
	p = 1.0
	lmin = min(length(e.chromosome), length(c.chromosome))
	lmin = Int64(round(p*lmin))
    res = 0.0
    for i in 1:lmin
        if abs(e.chromosome[i] - c.chromosome[i]) < 0.00001
            res += 1.0
        end
    end
    return res
end

# Settings
rom = "gravitar"
seed = 0
rootdir = dirname(@__DIR__)
resdir = joinpath(rootdir, "results/")
cfg_names = [
    "cfg/dualcgpga_atari_pooling.yaml",
    "cfg/dualcgpga_atari_pooling_evalmut_test.yaml"
]
n_iter = 10

mcfg, ecfg, ccfg, reducer, bootstrap = IICGP.dualcgp_config(cfg_names[1], rom)
function mutate(ind::CGPInd, ind_type::String)
    if ind_type == "encoder"
        return goldman_mutate(ecfg, ind, init_function=IPCGPInd)
    elseif ind_type == "controller"
        return goldman_mutate(ccfg, ind)
    end
end

# Iter over configs
labels = Vector{String}()
colors = Vector{Symbol}()
for cfg_name in cfg_names
    # Runs
    for i in 1:n_iter
        # Random.seed!(seed)
        mcfg, ecfg, ccfg, reducer, bootstrap = IICGP.dualcgp_config(cfg_name, rom)
        eval_mutant = mcfg["eval_mutant"]
        clr = eval_mutant ? :darkorange1 : :slategrey
        lbl = eval_mutant ? "Evaluate mutants" : "Random evaluation"
        push!(colors, clr)
        push!(labels, lbl)
        logid = mcfg["id"]
        evo = IICGP.DualCGPGAEvo(mcfg, ecfg, ccfg, fit, logid, rootdir)
        init_backup(logid, rootdir, cfg_name)
        run!(evo)
    end
end

## Postproc
fetch_backup(rootdir, clean=true)

# Filters parameters
min_date = DateTime(2021, 10, 24)
max_date = DateTime(2021, 10, 26)
savedir_index = 1
games = ["gravitar"]
reducers = ["pooling"]# Vector{String}()
dotime = false
dosave = true
baselines = false

cilabels = ["Random evaluation", "Evaluate mutants"]
cicolors = [:slategrey, :darkorange1]

for g in games
    exp_dirs, games = get_exp_dir(
        resdir, min_date=min_date, max_date=max_date, games=[g],
        reducers=reducers
    )
    process_results(
        exp_dirs, games, dotime, dosave, ma=1, baselines=baselines,
        labels=labels, colors=colors, savedir_index=savedir_index,
        plotci=true, cilabels=cilabels, cicolors=cicolors
    )
end

doclean = false
if doclean
    graphdir = joinpath(rootdir, "graphs", "2021-10-25_gravitar")
    rm(resdir, recursive=true, force=true)
    rm(graphdir, recursive=true, force=true)
end
