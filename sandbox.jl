using OpenCV

global arity = Dict()

SorX = Union{Symbol, Expr}

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

function function_generator(name::Symbol, e::Expr, iotype::U) where {U <: Union{DataType, Union}}
    @eval function $name(x::T, y::T)::T where {T <: $(iotype)}
        return $e
    end
end

# Functions generation

function_generator(:incr, :(x + 1), Float64)
function_generator(:incr, :(x + 1), Int64)
function_generator(:incr, :(x + 1), UType)

fgen(:f_add, 2, :(x + y), Float64)
fgen(:f_add, 2, :(x + y), Int64)
fgen(:f_add, 2, :(x + y), UType)

fgen(:f_add, 2, :(OpenCV.add(x, y)), OpenCV.InputArray)
