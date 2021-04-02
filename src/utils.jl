export split_rgb, imshow

using OpenCV

"""
    split_rgb(m::T)::Array{T, 1} where {T <: OpenCV.InputArray}

Split input array in three channels.
"""
function split_rgb(m::T) where {T <: OpenCV.InputArray}
    @assert size(m)[1] == 3
    [reshape(m[i, :, :], (1, size(m)[2], size(m)[3])) for i in 1:3]
end

function imshow(m::T) where {T <: OpenCV.InputArray}
    OpenCV.imshow("Image", m)
    OpenCV.waitKey(Int32(0))
end
