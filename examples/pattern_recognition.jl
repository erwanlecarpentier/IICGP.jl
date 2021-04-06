using OpenCV
using IICGP
using BenchmarkTools

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
function pattern_recognition(m::T; ksize::Int64=100, pos::Tuple{Int64,Int64}=(1, 1), threshold::Float64=0.9) where {T <: OpenCV.InputArray}
   _, x_max, y_max = size(m)
   x = min(pos[1], x_max - ksize + 1)
   y = min(pos[2], y_max - ksize + 1)

   # Extract template
   template = m[:, x:x+ksize-1, y:y+ksize-1]
   IICGP.imshow(template)

   # Compute matching map
   match = OpenCV.matchTemplate(m, template, OpenCV.TM_CCOEFF_NORMED)
   _, i_max, j_max = size(match)
   IICGP.imshow(match)

   # Create and fill matching image
   out = zeros(UInt8, size(m))
   for i in 1:i_max
      for j in 1:j_max
         if match[1, i, j] > threshold
            out[1, i:i+ksize-1, j:j+ksize-1] .= 255
         end
      end
   end
   IICGP.imshow(out)

   return out
end

# Load image
rom_name = "freeway"
img = OpenCV.imread(string(@__DIR__, "/images/", rom_name, "_frame_30.png"))
img = IICGP.split_rgb(img)[1]
IICGP.imshow(img)

# Compute pattern recognition
out = pattern_recognition(img)
out = pattern_recognition(img, ksize=50, pos=(100, 50), threshold=0.9)
