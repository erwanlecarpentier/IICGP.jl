using ArgParse
using Cambrian
using CartesianGeneticProgramming
using Dates
using IICGP
using Random
using UnicodePlots
using LinearAlgebra

import Cambrian.mutate

out(plt) = println(IOContext(stdout, :color=>true), plt)
default_resdir = joinpath(dirname(@__DIR__), "results")
default_cfgdir = joinpath(dirname(@__DIR__), "cfg")

s = ArgParseSettings()
@add_arg_table! s begin
    "--cfg"
    help = "configuration script"
    default = joinpath(default_cfgdir, "nsgaii_example.yaml")
    "--seed"
    help = "random seed"
    default = 0
    "--out"
    help = "output directory"
    arg_type = String
    default = default_resdir
end

args = parse_args(ARGS, s)
const cfg_path = args["cfg"]
const seed = args["seed"]
const resdir = args["out"]
const cfg = get_config(cfg_path)

# Specific functions for this example of learning two functions
x = [i for i in 0:0.05:1]
f1(x) = 0.2 * (2.0 + cos(2.0*π*x))
f2(x) = 0.25 * (2.0 + cos(4*π*x))
y1 = f1.(x)
y2 = f2.(x)
out(lineplot([f1, f2], 0, 1, border=:dotted))
function display_paretto(e::NSGA2Evo)
    o1 = [ind.fitness[1] for ind in e.population]
    o2 = [ind.fitness[2] for ind in e.population]
    out(scatterplot(o1, o2, title = "Paretto front"))#, xlim=[0,1], ylim=[0,1]))
end

# User-defined fitness function (normalized)
function my_fitness(ind::NSGA2Ind)
    cgp_ind = CGPInd(cfg, ind.chromosome)
    y_hat = zeros(length(y1))
    @inbounds for i in eachindex(y1)
        y_hat[i] = CartesianGeneticProgramming.process(cgp_ind, [x[i]])[1]
    end
    o1 = - norm(y1 - y_hat) / length(x)
    o2 = - norm(y2 - y_hat) / length(x)
    o1, o2
end

# User-defined mutation function
function mutate(ind::NSGA2Ind)
    cgpind = CGPInd(cfg, ind.chromosome)
    child = goldman_mutate(cfg, cgpind)
    NSGA2Ind(cfg, child.chromosome)
end

# User-defined population initialization function
function my_init(cfg::NamedTuple)
    [NSGA2Ind(cfg, CGPInd(cfg).chromosome) for _ in 1:cfg.n_population]
end

e = NSGA2Evo(cfg, resdir, my_fitness, my_init)

init_backup(cfg.id, resdir, cfg_path)
#run!(evo)
for i in 1:2#e.config.n_gen
    e.gen += 1
    if e.gen > 1
        populate(e)
    end
    evaluate(e)
    display_paretto(e)
    new_population = generation(e)
    if ((e.config.log_gen > 0) && mod(e.gen, e.config.log_gen) == 0)
        log_gen(e)
    end
    #=if ((e.config.save_gen > 0) && mod(e.gen, e.config.save_gen) == 0)
        save_gen(e)
    end=#
end

# Display one of the elite (Pareto efficient) individuals
ind = CGPInd(cfg, e.population[1].chromosome)
f(x) = CartesianGeneticProgramming.process(ind, [x])[1]
out(lineplot([f1, f2, f], 0, 1, border=:dotted))