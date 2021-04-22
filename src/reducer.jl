export max_pool_reduction

using OpenCV

function max_pool_reduction(m::T) where {T <: OpenCV.InputArray}
    # function resize(src::InputArray, dsize::Size{Int32}, dst::InputArray, fx::Float64, fy::Float64, interpolation::Int32)
    dsize = OpenCV.Size(convert(Int32, 30), convert(Int32, 30))
    return OpenCV.resize(m, dsize, m, 1.0, 1.0, OpenCV.INTER_MAX)
end
