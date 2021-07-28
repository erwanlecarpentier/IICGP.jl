export process_results

using Plots
using ImageFiltering
using OffsetArrays

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
