export process_results

using Plots
using ImageFiltering
using OffsetArrays
using BenchmarkTools
using TimerOutputs

BASELINES = Dict(
    "assault"=>Dict("MTCGP"=>(890.4, 255), "A3C LSTM"=>14497.9),
    "asteroids"=>Dict("MTCGP"=>(9412,1818)),
    "boxing"=>Dict("MTCGP"=>(38.4,4), "Dueling"=>77.3),
    "breakout"=>Dict("MTCGP"=>(13.2,2), "A3C LSTM"=>766.8),
    "defender"=>Dict("MTCGP"=>(993010,2739)),
    "freeway"=>Dict("MTCGP"=>(28.2,0), "HyperNEAT"=>29),
    "frostbite"=>Dict("MTCGP"=>(782,795), "TPG"=>8144.4),
    "gravitar"=>Dict("MTCGP"=>(2350,50)),
    "private_eye"=>Dict("MTCGP"=>(12702.2,4337), "TPG"=>15028.3),
    "riverraid"=>Dict("MTCGP"=>(2914,90), "Prioritized"=>18184.4),
    "solaris"=>Dict("MTCGP"=>(8324,2250)),
    "space_invaders"=>Dict("MTCGP"=>(1001,25), "A3C LSTM"=>23846)
)

"""
    function time_monocgp_ms(
        reducer::Reducer,
        cont::CGPInd,
        game_name::String
    )

Time forward pass of complete architecture.
Return time in ms.
"""
function time_monocgp_ms(
    reducer::Reducer,
    cont::CGPInd,
    game_name::String,
    grayscale::Bool,
    downscale::Bool
)
    # Generate input
    g = Game(game_name, 0)
    inp = get_state(g, grayscale, downscale)
    close!(g)
    # Pre-compile
    process(reducer, cont, inp)
    n_iter = 1000
    # Time
    redu_time = 0.0
    flat_time = 0.0
    cont_time = 0.0
    for _ in 1:n_iter
        redu_time += @elapsed features = reducer.reduct(inp, reducer.parameters)
        flat_time += @elapsed features_flatten = collect(Iterators.flatten(Iterators.flatten(features)))
        cont_time += @elapsed cont_out = CartesianGeneticProgramming.process(cont, features_flatten)
    end
    to_ms = 1000 / n_iter
    redu_time *= to_ms
    flat_time *= to_ms
    cont_time *= to_ms
    redu_time, flat_time, cont_time
end

"""
    function time_dualcgp_ms(
        enco::CGPInd,
        reducer::Reducer,
        cont::CGPInd,
        game_name::String
    )

Time forward pass of complete architecture.
Return time in ms.
"""
function time_dualcgp_ms(
    enco::CGPInd,
    reducer::Reducer,
    cont::CGPInd,
    game_name::String,
    grayscale::Bool,
    downscale::Bool
)
    # Generate input
    g = Game(game_name, 0)
    inp = get_state(g, grayscale, downscale)
    close!(g)
    # Pre-compile
    process(enco, reducer, cont, inp)
    n_iter = 1000
    # Time
    enco_time = 0.0
    redu_time = 0.0
    flat_time = 0.0
    cont_time = 0.0
    for _ in 1:n_iter
        enco_time += @elapsed enco_out = CartesianGeneticProgramming.process(enco, inp)
        redu_time += @elapsed features = reducer.reduct(enco_out, reducer.parameters)
        flat_time += @elapsed features_flatten = collect(Iterators.flatten(Iterators.flatten(features)))
        cont_time += @elapsed cont_out = CartesianGeneticProgramming.process(cont, features_flatten)
    end
    to_ms = 1000 / n_iter
    enco_time *= to_ms
    redu_time *= to_ms
    flat_time *= to_ms
    cont_time *= to_ms
    enco_time, redu_time, flat_time, cont_time
end

function add_baselines(graphs::Vector{Plots.Plot{Plots.GRBackend}}, game::String)
    if haskey(BASELINES, game)
        baselines = BASELINES[game]
        for g in graphs
            for k in keys(baselines)
                if k == "MTCGP"
                    score = baselines[k][1]
                    var = baselines[k][2]
                    hline!(g, [score], ribbon=([var]), color=:gray, label=false)
                else
                    score = baselines[k]
                end
                hline!(g, [score], linestyle=:dash, color=:black, label=false)
                annotate!(0, score, text(k, 7, :bottom, :left), :black)
            end
        end
    end
end

"""
    function process_results(
        exp_dirs::Array{String,1},
        games::Array{String,1},
        dotime::Bool,
        dosave::Bool;
        ma::Int64=1
    )

Main results plot/print method.
"""
function process_results(
    exp_dirs::Array{String,1},
    games::Array{String,1},
    dotime::Bool,
    dosave::Bool;
    ma::Int64=1
)
    # Init graphs
    xl = "Generation"
    plt_best = plot(ylabel="Best score", xlabel=xl)
    plt_mean = plot(ylabel="Mean score", xlabel=xl)

    for i in eachindex(exp_dirs)
        exp_dir = exp_dirs[i]
        # exp_date = basename(exp_dir)[1:10]
        cfg = cfg_from_exp_dir(exp_dir)
        log = log_from_exp_dir(exp_dir)

        # Plots
        reducer_type = cfg["reducer"]["type"]
        label_i = string(games[i], ' ',reducer_type)
        kernel = OffsetArray(fill(1/(2*ma+1), 2*ma+1), -ma:ma)
        best = (ma == 1) ? log.best : imfilter(log.best, kernel)
        mean = (ma == 1) ? log.mean : imfilter(log.mean, kernel)
        std = (ma == 1) ? log.std : imfilter(log.std, kernel)
        save_gen = cfg["save_gen"]
        x = 1:save_gen:save_gen*length(best)
        plot!(plt_best, x, best, label=label_i)
        plot!(plt_mean, x, mean, ribbon=std, label=label_i)

        # Append info to print
        p = []
        push!(p, ["Game", games[i]])
        push!(p, ["Number gen", length(log) * cfg["save_gen"]])
        push!(p, ["1st gen", ""])
        push!(p, ["  - best", log[1].best])
        push!(p, ["  - mean", log[1].mean])
        push!(p, ["  - std", log[1].std])
        push!(p, ["end gen", ""])
        push!(p, ["  - best", log[end].best])
        push!(p, ["  - mean", log[end].mean])
        push!(p, ["  - std", log[end].std])
        push!(p, ["Reducer", reducer_type])
        if cfg["reducer"]["type"] == "centroid"
            push!(p, ["  - n_centroids", cfg["reducer"]["n_centroids"]])
        else
            push!(p, ["  - features_size", cfg["reducer"]["features_size"]])
            push!(p, ["  - pooling_function", cfg["reducer"]["pooling_function"]])
        end
        push!(p, ["Forward pass timing (ms)", ""])


        # Timer
        if dotime
            is_dual = isfile(joinpath(exp_dirs[i], "logs/encoder.csv"))
            total_time = 0.0
            grayscale = cfg["grayscale"]
            downscale = cfg["downscale"]
            if is_dual
                enco, reducer, cont = get_last_dualcgp(exp_dirs[i], games[i], cfg)
                enco_time, redu_time, flat_time, cont_time = time_dualcgp_ms(
                    enco, reducer, cont, games[i], grayscale, downscale
                )
                push!(p, ["  - Encoder", enco_time])
                total_time += enco_time
            else
                reducer, cont = get_last_monocgp(exp_dirs[i], games[i], cfg)
                redu_time, flat_time, cont_time = time_monocgp_ms(
                    reducer, cont, games[i], grayscale, downscale
                )
            end
            total_time += redu_time
            total_time += flat_time
            total_time += cont_time
            push!(p, ["  - Reducer", redu_time])
            push!(p, ["  - Flattening", flat_time])
            push!(p, ["  - Controller", cont_time])
            push!(p, ["  - Total", total_time])
        end

        # Finish push and print
        l = maximum([length(k) for k in [pr[1] for pr in p]])
        println()
        for k in p
            println(string(k[1], " "^(l-length(k[1])), " : ", k[2]))
        end
    end
    add_baselines([plt_best, plt_mean], games[1])
    display(plt_best)
    display(plt_mean)

    if dosave
        exp_name = string(basename(exp_dirs[1])[1:10], "_", games[1])
        graph_dir = joinpath(dirname(dirname(exp_dirs[1])), "graphs", exp_name)
        mkpath(graph_dir)
        savefig(plt_best, joinpath(graph_dir, "best.png"))
        savefig(plt_mean, joinpath(graph_dir, "mean.png"))
    end
end
