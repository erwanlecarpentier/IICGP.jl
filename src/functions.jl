export CGPFunctions, ImgType

module CGPFunctions

using ImageMorphology

global arity = Dict()

SorX = Union{Symbol, Expr}
ImgType = Array{UInt8,2}

function scaled(x::Float64)
    if isnan(x)
        return 0.0
    end
    min(max(x, -1.0), 1.0)
end

function fgen(name::Symbol, ar::Int, s1::SorX, iotype::U; safe::Bool=false) where {U <: Union{DataType, Union}}
    if safe
        @eval function $name(x::T, y::T)::T where {T <: $(iotype)}
            try
                return $s1
            catch
                return x
            end
        end
    else
        @eval function $name(x::T, y::T)::T where {T <: $(iotype)}
            $s1
        end
    end
    arity[String(name)] = ar
end

#=
# OpenCV image processing functions
fgen(:f_absdiff_img, 2, :(OpenCV.absdiff(x, y)), OpenCV.InputArray)
fgen(:f_add_img, 2, :(OpenCV.add(x, y)), OpenCV.InputArray)
fgen(:f_subtract_img, 2, :(OpenCV.subtract(x, y)), OpenCV.InputArray)
fgen(:f_addweighted_img, 2, :(OpenCV.addWeighted(x, 0.5, y, 0.5, 0.0)), OpenCV.InputArray)

# OpenCV Bitwise operations
fgen(:f_bitwise_and_img, 2, :(OpenCV.bitwise_and(x, y)), OpenCV.InputArray)
fgen(:f_bitwise_not_img, 1, :(OpenCV.bitwise_not(x)), OpenCV.InputArray)
fgen(:f_bitwise_or_img, 2, :(OpenCV.bitwise_or(x, y)), OpenCV.InputArray)
fgen(:f_bitwise_xor_img, 2, :(OpenCV.bitwise_xor(x, y)), OpenCV.InputArray)

# OpenCV Images comparison
fgen(:f_compare_eq_img, 2, :(OpenCV.compare(x, y, OpenCV.CMP_EQ)), OpenCV.InputArray)
fgen(:f_compare_ge_img, 2, :(OpenCV.compare(x, y, OpenCV.CMP_GE)), OpenCV.InputArray)
fgen(:f_compare_le_img, 2, :(OpenCV.compare(x, y, OpenCV.CMP_LE)), OpenCV.InputArray)

# OpenCV Change pixels magnitude
fgen(:f_max_img, 2, :(OpenCV.max(x, y)), OpenCV.InputArray)
fgen(:f_min_img, 2, :(OpenCV.min(x, y)), OpenCV.InputArray)
# fgen(:f_normalize_img, 1, :(OpenCV.normalize(x, x, 1.0, 0.0, OpenCV.NORM_L2)))

# OpenCV Filters
fgen(:f_dilate_img, 1, :(OpenCV.dilate(x, OpenCV.getStructuringElement(OpenCV.MORPH_ELLIPSE, OpenCV.Size{Int32}(8, 8)))), OpenCV.InputArray)
fgen(:f_erode_img, 1, :(OpenCV.erode(x, OpenCV.getStructuringElement(OpenCV.MORPH_ELLIPSE, OpenCV.Size{Int32}(4, 4)))), OpenCV.InputArray)
=#

# Julia image processing functions

#=
fgen(:f_corners, 1, :(x),
     :(Float64.(Images.fastcorners(x))); safe=true)
fgen(:f_filter, 2, :(x), :(x),
     :(ndims(y) == 2 ?
       scaled(ImageFiltering.imfilter(x, Images.centered(y))) : x);
     safe=true)
fgen(:f_gaussian, 1, :(x),
     :(scaled(ImageFiltering.imfilter(x, Images.Kernel.gaussian(0.1))));
     safe=true)
fgen(:f_laplacian, 1, :(x),
     :(scaled(ImageFiltering.imfilter(x, Images.Kernel.Laplacian())));
     safe=true)
fgen(:f_sobelx, 1, :(x),
     :(scaled(ImageFiltering.imfilter(x, Images.Kernel.sobel()[2])));
     safe=true)
fgen(:f_sobely, 1, :(x),
     :(scaled(ImageFiltering.imfilter(x, Images.Kernel.sobel()[1])));
     safe=true)
fgen(:f_canny, 1, :(x),
     :(Float64.(Images.canny(x, (Images.Percentile(80),
                                 Images.Percentile(20)))));
     safe=true)
fgen(:f_edge, 1, :(x), :(ndims(x) > 1 ? scaled(Images.imedge(x)[3]) : x))
fgen(:f_histogram, 1, :(x), :(normalized(Float64.(Images.imhist(x, 10)[2])));
     safe=true)
fgen(:f_dilate, 1, :(x), :(ImageMorphology.dilate(x)))
fgen(:f_erode, 1, :(x), :(scaled(ImageMorphology.erode(x))))
fgen(:f_opening, 1, :(x), :(scaled(ImageMorphology.opening(x))))
fgen(:f_closing, 1, :(x), :(scaled(ImageMorphology.closing(x))))
fgen(:f_tophat, 1, :(x), :(scaled(ImageMorphology.tophat(x))))
fgen(:f_bothat, 1, :(x), :(scaled(ImageMorphology.bothat(x))))
fgen(:f_morphogradient, 1, :(x), :(scaled(ImageMorphology.morphogradient(x))))
fgen(:f_morpholaplace, 1, :(x), :(scaled(ImageMorphology.morpholaplace(x))))
fgen(:f_rotate_right, 1, :(x), :(rotr90(x)); safe=true)
fgen(:f_rotate_left, 1, :(x), :(rotl90(x)); safe=true)
fgen(:f_shift_up, 1, :(x), :(circshift(x, (-1, zeros(ndims(x)-1)...))))
fgen(:f_shift_down, 1, :(x), :(circshift(x, (1, zeros(ndims(x)-1)...))))
fgen(:f_shift_left, 1, :(x),
     :(circshift(x, (0, -1, zeros(ndims(x)-2)...))), safe=true)
fgen(:f_shift_right, 1, :(x),
     :(circshift(x, (0, 1, zeros(ndims(x)-2)...))), safe=true)
fgen(:f_min_window, 1, :(x), :(ImageFiltering.MapWindow.mapwindow(
    minimum, x, 3*ones(Int, ndims(x)))); safe=true)
fgen(:f_max_window, 1, :(x), :(ImageFiltering.MapWindow.mapwindow(
    maximum, x, 3*ones(Int, ndims(x)))); safe=true)
fgen(:f_mean_window, 1, :(x), :(ImageFiltering.MapWindow.mapwindow(
    Statistics.mean, x, 3*ones(Int, ndims(x)))); safe=true)
fgen(:f_restrict, 1, :(x),
     :(scaled(ImageTransformations.restrict(x))); safe=true)
=#

# Image processing
fgen(:f_dilate, 1, :(ImageMorphology.dilate(x)), ImgType)
fgen(:f_erode, 1, :(ImageMorphology.erode(x)), ImgType)
fgen(:f_remove_details, 1,
     :(ImageMorphology.dilate(ImageMorphology.erode(x))), ImgType)

# Mathematical
fgen(:f_add, 2, :((x + y) / 2.0), Float64)
fgen(:f_subtract, 2, :(abs(x - y) / 2.0), Float64)
fgen(:f_mult, 2, :(x * y), Float64)
fgen(:f_div, 2, :(scaled(x / y)), Float64)
fgen(:f_abs, 1, :(abs(x)), Float64)
fgen(:f_sqrt, 1, :(sqrt(abs(x))), Float64)
fgen(:f_pow, 2, :(abs(x) ^ abs(y)), Float64)
fgen(:f_exp, 1, :((2 * (exp(x+1)-1.0))/(exp(2.0)-1.0) -1), Float64)
fgen(:f_sin, 1, :(sin(x)), Float64)
fgen(:f_cos, 1, :(cos(x)), Float64)
fgen(:f_tanh, 1, :(tanh(x)), Float64)
fgen(:f_sqrt_xy, 2, :(sqrt(x^2 + y^2) / sqrt(2.0)), Float64)
fgen(:f_lt, 2, :(Float64(x < y)), Float64)
fgen(:f_gt, 2, :(Float64(x > y)), Float64)

# Logical
fgen(:f_and, 2, :(Float64((&)(Int(round(x)), Int(round(y))))), Float64)
fgen(:f_or, 2, :(Float64((|)(Int(round(x)), Int(round(y))))), Float64)
fgen(:f_xor, 2, :(Float64(xor(Int(abs(round(x))), Int(abs(round(y)))))), Float64)
fgen(:f_not, 1, :(1 - abs(round(x))), Float64)

end
