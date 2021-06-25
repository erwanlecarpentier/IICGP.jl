export implot, display_buffer, plot_encoding, plot_centroids

using Plots

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
    heatmap(img, yflip=true, color=:grays, clim=clim, ratio=:equal)
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
function display_buffer(
        ind::CGPInd,
        enlargement::E=1;
        indexes=eachindex(ind.buffer)
    ) where {E <: Union{Int64, Float64}}
    for i in indexes
        imshow(ind.buffer[i], enlargement)
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
    p = plot(layout=grid(3, n_cols), leg=false, framestyle=:none) #axis=nothing)
    for i in 1:n_in
        plot!(p[i], buffer[i], seriestype=:heatmap, flip=true, ratio=:equal, color=:grays) #, color=:inferno)
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
        x::Array{UInt8, 2},
        centroids::Array{Tuple{Float64,Float64},1}
    )

Given an image and a set of centroids, plot the image as a heatmap along with
the centroids.
"""
function plot_centroids(
        x::Array{UInt8, 2},
        centroids::Array{Tuple{Float64,Float64},1}
    )
    xs = [c[1] for c in centroids]
    ys = [c[2] for c in centroids]
    pal = palette([:blue, :red, :orange, :yellow, :green], length(xs))
    plt = heatmap(x, color=:grays, ratio=:equal, yflip=true, leg=false,
                  framestyle=:none)
    for i in eachindex(xs)
        scatter!(plt, [ys[i]], [xs[i]], legend=:none, color=pal[i])#, color=:thermal)
    end
    plt
end
