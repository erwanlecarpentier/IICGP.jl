export imshow, display_buffer

using CartesianGeneticProgramming

"""
    imshow(m::T) where {T <: OpenCV.InputArray}

Show input image using functions `imshow` and `waitKey` from OpenCV Julia
binding.
"""
function imshow(m::T) where {T <: OpenCV.InputArray}
    OpenCV.imshow("Image", m)
    OpenCV.waitKey(Int32(0))
end

"""
    imshow(m::T; enlargement::Int64) where {T <: OpenCV.InputArray}

Show enlarged input image using functions `imshow` and `waitKey` from OpenCV
Julia binding.
The enlargement factor is given by the `enlargement` input parameter.

Examples:

    IICGP.imshow(m)
    IICGP.imshow(m, 2)
    IICGP.imshow(m, 0.5)
"""
function imshow(m::T, enlargement::E) where {T <: OpenCV.InputArray, E <: Union{Int64, Float64}}
    n_cols = convert(Int32, size(m)[2] * enlargement)
    n_rows = convert(Int32, size(m)[3] * enlargement)
    new_size = OpenCV.Size(n_cols, n_rows)
    enlarged = OpenCV.resize(m, new_size, m, 1.0, 1.0, OpenCV.INTER_NEAREST)
    imshow(enlarged)
end


"""
    function my_imshow(img::AbstractArray; kwargs...)

Show input image using heatmap.
Magnitude parameter may be precised using the `clim` keyword. The default value
is set to `clim=(0,255)`. Using `clim="auto"` amounts to take the maximum of
the input image as maximum magnitude.

Examples:

    my_imshow(m)
    my_imshow(m, clim="auto")
    my_imshow(m, clim=(1, 10))
"""
function my_imshow(img::AbstractArray; kwargs...)
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
    heatmap(
        transpose(img),
        yflip=true,
        color=:grays,
        clim=clim
    )
end

"""
    function display_buffer(ind::CGPInd, enlargement::E=1, indexes::Array{Int64}) where {E <: Union{Int64, Float64}}

Display the images contained in each node in the input IPCGP individual.

Examples:

    IICGP.display_buffer(ind)
    IICGP.display_buffer(ind, 2)
    IICGP.display_buffer(ind, indexes=1:3)
    IICGP.display_buffer(ind, 2, indexes=1:3)
"""
function display_buffer(ind::CGPInd, enlargement::E=1; indexes=eachindex(ind.buffer)) where {E <: Union{Int64, Float64}}
    for i in indexes
        imshow(ind.buffer[i], enlargement)
    end
end
