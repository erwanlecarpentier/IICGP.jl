export implot, plot_encoding, plot_centroids
export plot_buffer, plot_active_buffer, plot_pipeline

using Plots
using Plots.PlotMeasures
# using ImageView

"""
    function implot(img::AbstractArray; kwargs...)

Plot input image using heatmap.
Magnitude parameter may be precised using the `clim` keyword. The default value
is set to `clim=(0,255)`. Using `clim="auto"` amounts to take the maximum of
the input image as maximum magnitude.

Examples:

    implot(m)
    implot(m, clim="auto")
    implot(m, clim=(1, 10))
"""
function implot(img::AbstractArray; kwargs...)
    kwargs_dict = Dict(kwargs)
    if haskey(kwargs_dict, :clim)
        if kwargs_dict[:clim] == "auto"
            clim = (0, maximum(img))
        else
            clim = kwargs_dict[:clim]
        end
    else
        clim = (0, 255)
    end
    if ndims(img) == 3
        img = img[1,:,:]
    end
    heatmap(transpose(img), yflip=true, color=:grays, clim=clim,
            ratio=:equal)
end

"""
    function display_buffer(
        ind::CGPInd,
        enlargement::E=1;
        indexes=eachindex(ind.buffer)
    ) where {E <: Union{Int64, Float64}}

Display the images contained in each node in the input IPCGP individual.

Examples:

    IICGP.display_buffer(ind)
    IICGP.display_buffer(ind, 2)
    IICGP.display_buffer(ind, indexes=1:3)
    IICGP.display_buffer(ind, 2, indexes=1:3)
"""
function plot_buffer(
    ind::CGPInd, # enlargement::E=1;
    indexes=eachindex(ind.buffer)
) where {E <: Union{Int64, Float64}}
    for i in indexes
        implot(ind.buffer[i]) # , enlargement)
    end
end

"""
    plot_pipeline

Generic pipeline plotting function.
"""
function plot_pipeline(s::Array{UInt8,3}) #, enco::CGPInd)
    # display(implot(s[1]))
    imshow(s, canvassize=(500, 500))
end

"""
    plot_active_buffer(
        ind::CGPInd,
        enlargement::E=1
    ) where {E <: Union{Int64, Float64}}

Display the images contained in each active node in the given IPCGP individual.
"""
function plot_active_buffer(ind::CGPInd)
    for i in eachindex(ind.buffer)
        if ind.nodes[i].active
            #plt = implot(ind.buffer[i]) # , enlargement)
            #=plt = plot(
                ind.buffer[i], seriestype=:heatmap, flip=true,
                ratio=:equal, color=:grays, leg=false, framestyle=:none
            )=#
            plt = heatmap(
                ind.buffer[i], yflip=true, color=:grays, clim=(0,255),
                ratio=:equal, leg=false, framestyle=:none,
                padding = (0.0, 0.0) # , margin=-5mm
            )
            # println(ind.buffer[i][1:3])
            display(plt)
            savefig(plt, "buffer.png")
        end
    end
end

"""
    plot_encoding(
        n_in::Int64,
        buffer::Array{Array{UInt8,2},1},
        features::AbstractArray
    )

Plot the complete encoding pipeline from input to projection on feature space.
"""
function plot_encoding(
        n_in::Int64,
        buffer::Array{Array{UInt8,2},1},
        features::AbstractArray
    )
    n_cols = max(n_in, length(features), length(buffer)-n_in)
    mrg = -4mm
    pdg = (0.0, 0.0)
    p = plot(layout=grid(3, n_cols), leg=false, framestyle=:none, margin=mrg) #axis=nothing)
    for i in 1:n_in
        plot!(p[i], buffer[i], seriestype=:heatmap, flip=true, ratio=:equal,
              color=:grays)
    end
    for i in n_in+1:length(buffer)
        plot!(p[2,i-n_in], buffer[i], seriestype=:heatmap, flip=true, ratio=:equal, color=:grays)
    end
    for i in eachindex(features)
        plot!(p[3,i], features[i], seriestype=:heatmap, flip=true, ratio=:equal, color=:grays)
    end
    p
end

"""
    plot_centroids(
        images::Array{Array{UInt8,2},1},
        centroids::Array{Array{Tuple{Float64,Float64},1},1}
    )

Given an image and a set of centroids, plot the image as a heatmap along with
the centroids.
"""
function plot_centroids(
        images::Array{Array{UInt8,2},1},
        centroids::Array{Array{Tuple{Float64,Float64},1},1}
    )
    x = images[1]
    img_size = size(x)
    mlt = 1
    mrg = -100mm
    pdg = (0.0, 0.0)
    final_size = (mlt*img_size[2], mlt*img_size[1])
    centro = IICGP.scaled_centroids(centroids[1], img_size)

    xs = [c[1] for c in centro]
    ys = [c[2] for c in centro]
    pal = palette([:blue, :red, :orange, :yellow, :green], length(xs))
    plt = heatmap(x, color=:grays, ratio=:equal, yflip=true, leg=false,
                  framestyle=:none, padding=pdg, margin=mrg,
                  size=final_size)
    for i in eachindex(xs)
        scatter!(plt, [ys[i]], [xs[i]], padding=pdg,
                 margin=mrg, color=pal[i])
    end
    plt
end
