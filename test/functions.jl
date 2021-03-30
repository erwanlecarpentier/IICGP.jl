using IICGP
using Test
using OpenCV
using Combinatorics

function generate_white_img(sz::Tuple{Int64,Int64,Int64}=(3, 320, 210))
    convert(UInt8, 255) * ones(UInt8, sz)
end

function generate_black_img(sz::Tuple{Int64,Int64,Int64}=(3, 320, 210))
    zeros(UInt8, sz)
end

function generate_noisy_img(sz::Tuple{Int64,Int64,Int64}=(3, 320, 210))
    rand(collect(UInt8, 0:255), sz)
end

function test_inputs(f::Function, inps::AbstractArray)
    out = copy(f(inps...))
    @test size(out) == size(inps[1])
    @test size(out) == size(inps[2])
    @test typeof(out) == OpenCV.Mat{UInt8}
    @test all(out == f(inps...)) # functions are idempotent
    @test all(out .>= 0)
    @test all(out .<= 255)
end

function test_functions(functions::Array{Function}, img_pairs)
    for f in functions
        for pair in img_pairs
            test_inputs(f, pair)
        end
    end
end

@testset "OpenCV functions" begin
    # Load / generate images
    image_name = "centipede_frame_0"
    filename = string(@__DIR__, "/", image_name, ".png")
    atari_img = OpenCV.imread(filename)
    noisy_img = generate_noisy_img()
    white_img = generate_white_img()
    black_img = generate_black_img()

    img_set = [atari_img, noisy_img, white_img, black_img]
    img_pairs = Combinatorics.combinations(img_set, 2)

    """
    for i in [noisy_img, white_img, black_img]
        OpenCV.imshow("Image", i)
        OpenCV.waitKey(Int32(0))
        @test size(i) == (3, 320, 210)
    end
    """

    # Fetch functions
    functions = [
        IPCGPFunctions.f_add_img,
        IPCGPFunctions.f_subtract_img
    ]

    # Test functions
    test_functions(functions, img_pairs)
end





# Load / generate images
image_name = "centipede_frame_0"
filename = string(@__DIR__, "/", image_name, ".png")
atari_img = OpenCV.imread(filename)
grsca_img = OpenCV.cvtColor(atari_img, OpenCV.COLOR_BGR2GRAY)
noisy_img = generate_noisy_img()
white_img = generate_white_img()
black_img = generate_black_img()

OpenCV.imshow("Image", grsca_img)
OpenCV.waitKey(Int32(0))

img_set = [atari_img, noisy_img, white_img, black_img]
img_pairs = Combinatorics.combinations(img_set, 2)

for i in [noisy_img, white_img, black_img, atari_img]
    OpenCV.imshow("Image", i)
    OpenCV.waitKey(Int32(0))
    @test size(i) == (3, 320, 210)
end

test_img = Array{UInt8,2}[atari_img[1,:,:]]



out = Array{OpenCV.InputArray}[]
out = Array{OpenCV.Mat{UInt8}, 1}[]
out = Array{Array{UInt8,1}, 1}[]

out = OpenCV.InputArray[]
out = OpenCV.CxxMat[]
out = AbstractArray{UInt8,3}[]
out = OpenCV.Mat{UInt8}[]
out = Array{UInt8,1}[]

out = Array{Array{UInt8,1}}(undef, 3)
out = Array{OpenCV.InputArray}(undef, 3)
out = Array{OpenCV.Mat{UInt8}}(undef, 3)

out = Array{OpenCV.InputArray, 1}()
out = Array{OpenCV.Mat{UInt8}, 1}()

# split(m::InputArray, mv::Array{InputArray, 1})
OpenCV.split(noisy_img, out)
OpenCV.split(atari_img, out)


using OpenCV

noisy_img = rand(collect(UInt8, 0:255), (3, 320, 210))

out = OpenCV.CxxMat[]
out = AbstractArray{UInt8,3}[]
out = OpenCV.Mat{UInt8}[]
out = Array{UInt8}[]
out = Array{OpenCV.Mat{UInt8}, 1}()
out = OpenCV.InputArray[]
out = Array{OpenCV.InputArray, 1}()

OpenCV.split(noisy_img, out)

OpenCV.split(atari_img, out)  # Split RGB channels
OpenCV.split(atari_img)

# const dtypes = Union{UInt8, Int8, UInt16, Int16, Int32, Float32, Float64}
# const InputArray = Union{AbstractArray{T, 3} where {T <: dtypes}, CxxMat}



typeof(noisy_img) <: OpenCV.InputArray
typeof(out) <: Array{OpenCV.InputArray, 1}

clearconsole()
println(atari_img[1, 150, 140:150])
layer_i = reshape(atari_img[1,:,:], (1, 320, 210))
println(layer_i[:, 150, 140:150])


for i in 1:3
    layer_i = reshape(atari_img[i,:,:], (1, 320, 210))
    println(layer_i[1, 150, 140:150])
    OpenCV.imshow("Layer $i", layer)
    OpenCV.waitKey(Int32(0))
end
