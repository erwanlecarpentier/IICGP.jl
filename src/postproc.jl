export process_results

using Plots
using ImageFiltering
using OffsetArrays
using BenchmarkTools
using TimerOutputs


"""
    function time_individuals_ms(
        enco::CGPInd,
        reducer::Reducer,
        cont::CGPInd,
        game_name::String
    )

Time forward pass of complete architecture.
Return time in ms.
"""
function time_individuals_ms(
    enco::CGPInd,
    reducer::Reducer,
    cont::CGPInd,
    game_name::String
)
    # Generate input
    game = Game(game_name, 0)
    rgb = get_rgb(game)
    # Pre-compile
    process(enco, reducer, cont, rgb)
    n_iter = 100
    # Time
    enco_time = 0.0
    redu_time = 0.0
    flat_time = 0.0
    cont_time = 0.0
    for _ in 1:n_iter
        enco_time += @elapsed enco_out = CartesianGeneticProgramming.process(enco, rgb)
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

"""
    function process_results(
        exp_dirs::Array{String,1},
        games::Array{String,1};
        ma::Int64=1
    )

Main results plot/print method.
"""
function process_results(
    exp_dirs::Array{String,1},
    games::Array{String,1};
    ma::Int64=1
)
    # Init graphs
    xl = "Generation"
    plt_best = plot(ylabel="Best score", xlabel=xl)
    plt_mean = plot(ylabel="Mean score", xlabel=xl)

    for i in eachindex(exp_dirs)
        cfg = cfg_from_exp_dir(exp_dirs[i])
        log = log_from_exp_dir(exp_dirs[i])

        # Plots
        reducer_type = cfg["reducer"]["type"]
        label_i = string(games[i], ' ',reducer_type)
        kernel = OffsetArray(fill(1/(2*ma+1), 2*ma+1), -ma:ma)
        best = (ma == 1) ? log.best : imfilter(log.best, kernel)
        mean = (ma == 1) ? log.mean : imfilter(log.mean, kernel)
        std = (ma == 1) ? log.std : imfilter(log.std, kernel)
        println(best == log.best)
        plot!(plt_best, best, label=label_i)
        plot!(plt_mean, mean, ribbon=std, label=label_i)

        # Get last best individuals
        enco, reducer, cont = get_best_individuals(exp_dirs[i], games[i], cfg)
        enco_time, redu_time, flat_time, cont_time = time_individuals_ms(enco, reducer, cont, games[i])

        # Print everything
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
        push!(p, ["Forward pass timing (ms):", ""])
        push!(p, ["  - Encoder", enco_time])
        push!(p, ["  - Reducer", redu_time])
        push!(p, ["  - Flattening", flat_time])
        push!(p, ["  - Controller", cont_time])
        l = maximum([length(k) for k in [pr[1] for pr in p]])
        println()
        for k in p
            println(string(k[1], " "^(l-length(k[1])), " : ", k[2]))
        end
    end
    display(plt_best)
    display(plt_mean)

    savefig(plt_best, "best.png")
    savefig(plt_mean, "mean.png")
end
