using IICGP
using Test

function test_functions(functions::Array{Function})
    for f in functions
        println(f)
    end
end

@testset "OpenCV functions" begin
    functions = [
        IPCGPFunctions.f_add_img
    ]
    test_functions(functions)
end


# Load image
image_name = "centipede_frame_0"
filename = string(@__DIR__, "/", image_name, ".png")
img = OpenCV.imread(filename)
@test size(img) == (3, 320, 210)

# Show image
OpenCV.imshow(image_name, img)
OpenCV.waitKey(Int32(0))


rand_img = rand(1:256, (3, 320, 210), d=Int32)
test_img = AbstractArray{UInt8, 3}

OpenCV.imshow("rand", rand_img)
OpenCV.waitKey(Int32(0))



const dtypes = Union{UInt8, Int8, UInt16, Int16, Int32, Float32, Float64}
function testprint(m::AbstractArray{T, 3} where {T <: dtypes})
    println(m[1][1])
end

println(rand_img[1][1])
testprint(rand_img)
