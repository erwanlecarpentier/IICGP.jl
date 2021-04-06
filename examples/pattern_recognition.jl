using OpenCV
using IICGP

"""
   pattern_recognition(m::T; ksize::Int64=100, pos::Tuple{Int64,Int64}=(1, 1)) where {T <: OpenCV.InputArray}

Pattern recognition method.
Method:
- TM_CCOEFF
- TM_CCOEFF_NORMED
- TM_CCORR
- TM_CCORR_NORMED
- TM_SQDIFF
- TM_SQDIFF_NORMED
"""
function pattern_recognition(m::T; ksize::Int64=100, pos::Tuple{Int64,Int64}=(1, 1)) where {T <: OpenCV.InputArray}
   x = min(pos[1], size(img)[2] - ksize + 1)
   y = min(pos[2], size(img)[3] - ksize + 1)
   template = m[:, x:x+ksize-1, y:y+ksize-1]


   IICGP.imshow(template)


   println()
   # println(x:x+ksize-1, " ", y:y+ksize-1)

   match = OpenCV.matchTemplate(m, template, OpenCV.TM_CCOEFF_NORMED)

   # println(size(match))
   IICGP.imshow(match)

   return match
end

function load_img(rom_name::String, frame_number::Int64)
   filename = string(@__DIR__, "/images/", rom_name, "_frame_$frame_number.png")
   return OpenCV.imread(filename)
end

rom_name = "freeway"

# First input
img = load_img(rom_name, 30)
img = IICGP.split_rgb(img)[1]
IICGP.imshow(img)

out = pattern_recognition(img)
out = pattern_recognition(img, ksize=100, pos=(100, 50))

IICGP.imshow(out)
