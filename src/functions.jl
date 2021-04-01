export IPCGPFunctions

module IPCGPFunctions

using OpenCV

global arity = Dict()

SorX = Union{Symbol, Expr}

function scaled(x::Float64)
    if isnan(x)
        return 0.0
    end
    min(max(x, -1.0), 1.0)
end

function fgen(name::Symbol, ar::Int, s1::SorX; safe::Bool=false)
    if safe
        if ar == 1
            @eval function $name(x::OpenCV.InputArray)::OpenCV.InputArray
                try
                    return $s1
                catch
                    return x
                end
            end
        elseif ar == 2
            @eval function $name(x::OpenCV.InputArray, y::OpenCV.InputArray)::OpenCV.InputArray
                try
                    return $s1
                catch
                    return x
                end
            end
        else
            throw(DomainError("ar=$ar, arity different from 1 or 2 not implemented"))
        end
    else
        if ar == 1
            @eval function $name(x::OpenCV.InputArray)::OpenCV.InputArray
                $s1
            end
        elseif ar == 2
            @eval function $name(x::OpenCV.InputArray, y::OpenCV.InputArray)::OpenCV.InputArray
                $s1
            end
        else
            throw(DomainError("ar=$ar, arity different from 1 or 2 not implemented"))
        end
    end
    arity[String(name)] = ar
end

# OpenCV functions
fgen(:f_add_img, 2, :(OpenCV.add(x, y)))
fgen(:f_subtract_img, 2, :(OpenCV.subtract(x, y)))
fgen(:f_absdiff_img, 2, :(OpenCV.absdiff(x, y)))
fgen(:f_addweighted_img, 2, :(OpenCV.addWeighted(x, 0.5, y, 0.5, 0.0)))
fgen(:f_bitwise_and_img, 2, :(OpenCV.bitwise_and(x, y)))
fgen(:f_bitwise_not_img, 1, :(OpenCV.bitwise_not(x)))
fgen(:f_bitwise_or_img, 2, :(OpenCV.bitwise_or(x, y)))
fgen(:f_bitwise_xor_img, 2, :(OpenCV.bitwise_xor(x, y)))

"""
# Mathematical
fgen(:f_add, 2, Int64, :((x + y) / 2.0))
fgen(:f_subtract, 2, :(abs(x - y) / 2.0))
fgen(:f_mult, 2, :(x * y))
fgen(:f_div, 2, :(scaled(x / y)))
fgen(:f_abs, 1, :(abs(x)))
fgen(:f_sqrt, 1, :(sqrt(abs(x))))
fgen(:f_pow, 2, :(abs(x) ^ abs(y)))
fgen(:f_exp, 1, :((2 * (exp(x+1)-1.0))/(exp(2.0)-1.0) -1))
fgen(:f_sin, 1, :(sin(x)))
fgen(:f_cos, 1, :(cos(x)))
fgen(:f_tanh, 1, :(tanh(x)))
fgen(:f_sqrt_xy, 2, :(sqrt(x^2 + y^2) / sqrt(2.0)))
fgen(:f_lt, 2, :(Float64(x < y)))
fgen(:f_gt, 2, :(Float64(x > y)))

# Logical
fgen(:f_and, 2, :(Float64((&)(Int(round(x)), Int(round(y))))))
fgen(:f_or, 2, :(Float64((|)(Int(round(x)), Int(round(y))))))
fgen(:f_xor, 2, :(Float64(xor(Int(abs(round(x))), Int(abs(round(y)))))))
fgen(:f_not, 1, :(1 - abs(round(x))))
"""

end
