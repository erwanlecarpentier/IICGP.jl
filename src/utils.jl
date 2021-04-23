export split_rgb, imshow, load_img

using OpenCV

"""
    split_rgb(m::T) where {T <: OpenCV.InputArray}

Split input array in three channels.
"""
function split_rgb(m::T) where {T <: OpenCV.InputArray}
    @assert size(m)[1] == 3
    [reshape(m[i, :, :], (1, size(m)[2], size(m)[3])) for i in 1:3]
end

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
"""
function imshow(m::T, enlargement::E) where {T <: OpenCV.InputArray, E <: Union{Int64, Float64}}
    n_cols = convert(Int32, size(m)[2] * enlargement)
    n_rows = convert(Int32, size(m)[3] * enlargement)
    new_size = OpenCV.Size(n_cols, n_rows)
    enlarged = OpenCV.resize(m, new_size, m, 1.0, 1.0, OpenCV.INTER_NEAREST)
    imshow(enlarged)
end
