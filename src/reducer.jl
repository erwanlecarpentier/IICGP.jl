export ReducingFunctions

module ReducingFunctions

using OpenCV
using TiledIteration

function nearest_reduction(m::T; s::Int64=5) where {T <: OpenCV.InputArray}
    # dsize = OpenCV.Size(convert(Int32, s), convert(Int32, s))
    return OpenCV.resize(m, OpenCV.Size(convert(Int32, s), convert(Int32, s)),
                         m, 1.0, 1.0, OpenCV.INTER_NEAREST)
end

function linear_reduction(m::T; s::Int64=5) where {T <: OpenCV.InputArray}
    # dsize = OpenCV.Size(convert(Int32, s), convert(Int32, s))
    return OpenCV.resize(m, OpenCV.Size(convert(Int32, s), convert(Int32, s)),
                         m, 1.0, 1.0, OpenCV.INTER_LINEAR)
end

function area_reduction(m::T; s::Int64=5) where {T <: OpenCV.InputArray}
    # dsize = OpenCV.Size(convert(Int32, s), convert(Int32, s))
    return OpenCV.resize(m, OpenCV.Size(convert(Int32, s), convert(Int32, s)),
                         m, 1.0, 1.0, OpenCV.INTER_AREA)
end

function cubic_reduction(m::T; s::Int64=5) where {T <: OpenCV.InputArray}
    # dsize = OpenCV.Size(convert(Int32, s), convert(Int32, s))
    return OpenCV.resize(m, OpenCV.Size(convert(Int32, s), convert(Int32, s)),
                         m, 1.0, 1.0, OpenCV.INTER_CUBIC)
end

function lanczos_reduction(m::T; s::Int64=5) where {T <: OpenCV.InputArray}
    # dsize = OpenCV.Size(convert(Int32, s), convert(Int32, s))
    return OpenCV.resize(m, OpenCV.Size(convert(Int32, s), convert(Int32, s)),
                         m, 1.0, 1.0, OpenCV.INTER_LANCZOS4)
end

function max_pool_reduction(m::T; s::Int64=5) where {T <: OpenCV.InputArray}
    n_cols = s
    n_rows = s

    # Process
    # out = zeros(1, n_cols, n_rows)
    tile_width = convert(Int64, ceil(size(m)[2] / n_cols))
    tile_heigt = convert(Int64, ceil(size(m)[3] / n_rows))
    #=
    for tileaxs in TileIterator(axes(m[1, :, :]), (tile_width, tile_heigt))
            println()
            @show tileaxs
            println(maximum(m[1, tileaxs...]))
    end
    =#

    out = map(TileIterator(axes(m[1, :, :]), (tile_width, tile_heigt))) do tileaxs maximum(m[1, tileaxs...]) end
    reshape(out, 1, n_cols, n_rows)
end

end
