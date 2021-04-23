using IICGP
using TiledIteration

function max_pool(img::Array{UInt8}; s::Int64=5)
    n_cols = s
    n_rows = s
    tile_width = convert(Int64, ceil(size(img)[2] / n_cols))
    tile_heigt = convert(Int64, ceil(size(img)[3] / n_rows))
    out = map(TileIterator(axes(img[1, :, :]), (tile_width, tile_heigt))) do tileaxs maximum(img[1, tileaxs...]) end
    reshape(out, 1, n_cols, n_rows)
end
inp = rand(collect(UInt8, 0:255), (1, 100, 100))
out = max_pool(inp)


IICGP.imshow(inp, 10.0)
IICGP.imshow(out, 100.0)


#=
using PkgTemplates

t = Template(;
    user="erwanlecarpentier",
    authors="Erwan Lecarpentier",
    julia=v"1.5.4",
    plugins=[
        Codecov(),
        Coveralls(),
        License(; name="MIT"),
        Git(; manifest=true, ssh=false),
    ],
)

# https://www.youtube.com/watch?v=QVmU29rCjaA&t=1356s
# 7:18

generate("JuliaSandbox", t)
=#
