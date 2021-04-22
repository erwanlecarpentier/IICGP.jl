using IICGP
using OpenCV
using Test

@testset "Reducer" begin
        # Load / generate images
        image_name = "centipede_frame_0"
        filename = string(@__DIR__, "/", image_name, ".png")
        m = OpenCV.imread(filename)

        m_p = IICGP.max_pool_reduction(m)

        @test size(m) > size(m_new)
end


image_name = "centipede_frame_0"
filename = string(@__DIR__, "/", image_name, ".png")
m = OpenCV.imread(filename)
IICGP.imshow(m)

m_new = IICGP.max_pool_reduction(m)
IICGP.imshow(m_new)
