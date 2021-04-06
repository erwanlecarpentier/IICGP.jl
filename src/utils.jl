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

Show input image using functions `imshow` and `waitKey` from OpenCV Julia binding.
"""
function imshow(m::T) where {T <: OpenCV.InputArray}
    OpenCV.imshow("Image", m)
    OpenCV.waitKey(Int32(0))
end
