using OpenCV

global arity = Dict()

SorX = Union{Symbol, Expr}

function img_fgen(name::Symbol, ar::Int, s1::SorX; safe::Bool=false)
    if safe
        @eval function $name(x::OpenCV.InputArray, y::OpenCV.InputArray)::OpenCV.InputArray
            try
                return $s1
            catch
                return x
            end
        end
    else
        @eval function $name(x::OpenCV.InputArray, y::OpenCV.InputArray)::OpenCV.InputArray
            $s1
        end
    end
    arity[String(name)] = ar
end

function fgen(name::Symbol, ar::Int, s1::SorX, iotype::DataType; safe::Bool=false)
    if safe
        @eval function $name(x::T, y::T)::T where {T <: $(Symbol(iotype))}
            try
                return $s1
            catch
                return x
            end
        end
    else
        @eval function $name(x::T, y::T)::T where {T <: $(Symbol(iotype))}
            $s1
        end
    end
    arity[String(name)] = ar
end

function function_generator(name::Symbol, e::Expr, iotype::DataType)
    @eval function $name(x::T, y::T)::T where {T <: $(Symbol(iotype))}
        return $e
    end
end

function_generator(:incr, :(x + 1), Float64)

# OpenCV operations
img_fgen(:f_add_img_spec, 2, :(OpenCV.add(x, y)))

fgen(:f_add, 2, :(OpenCV.add(x, y)), OpenCV.InputArray)
fgen(:f_add, 2, :(x + y), Float64)
