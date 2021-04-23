using IICGP
using OpenCV
using Test
using TiledIteration  # TODO remove

function test_inputs(f::Function, img::AbstractArray)
    img_reduced = f(img)
    @test size(img_reduced) <= size(img)
end

function test_functions(functions::Array{Function}, images)
    for f in functions
        for img in images
            test_inputs(f, img)
        end
    end
end

@testset "Reducing functions" begin
        # Load / generate images
        image_name = "centipede_frame_0"
        filename = string(@__DIR__, "/", image_name, ".png")
        m = OpenCV.imread(filename)
        r, g, b = IICGP.split_rgb(m)
        images = [r, g, b]

        functions = [
                IICGP.ReducingFunctions.nearest_reduction,
                IICGP.ReducingFunctions.linear_reduction,
                IICGP.ReducingFunctions.area_reduction,
                IICGP.ReducingFunctions.cubic_reduction,
                IICGP.ReducingFunctions.lanczos_reduction
        ]

        # Test each function
        test_functions(functions, images)
end

# Load image and split
image_name = "centipede_frame_0"
filename = string(@__DIR__, "/", image_name, ".png")
m = OpenCV.imread(filename)
r, g, b = IICGP.split_rgb(m)
images = [r, g, b]

m_reduced = IICGP.ReducingFunctions.nearest_reduction(m)
m_reduced = IICGP.ReducingFunctions.linear_reduction(m)
m_reduced = IICGP.ReducingFunctions.area_reduction(m)
m_reduced = IICGP.ReducingFunctions.cubic_reduction(m)
m_reduced = IICGP.ReducingFunctions.lanczos_reduction(m)
m_reduced = IICGP.ReducingFunctions.max_pool_reduction(g)

imshow(m_reduced, 100)

A = rand(100, 100)
img = r[1, :, :]

# Input
m = r
n_cols = 5
n_rows = 5

# Process
out = zeros(1, n_cols, n_rows)
tile_width = convert(Int64, ceil(size(m)[2] / n_cols))
tile_heigt = convert(Int64, ceil(size(m)[3] / n_rows))
for tileaxs in TileIterator(axes(m[1, :, :]), (tile_width, tile_heigt))
        println()
        @show tileaxs
        println(maximum(m[1, tileaxs...]))
end

out = map(TileIterator(axes(m[1, :, :]), (tile_width, tile_heigt))) do tileaxs maximum(m[1, tileaxs...]) end
out = reshape(out, 1, n_cols, n_rows)

# Post-tests
IICGP.imshow(r)
IICGP.imshow(out, 100)
