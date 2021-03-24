
SorX = Union{Symbol, Expr}

function fgen(name::Symbol, s1::SorX)
    @eval function $name(x::Int64, y::Int64)::Int64
        $s1
    end
end

fgen(:f_add_int, :(x + y))


# fgen(:f_dilate, 1, :(x), :(ImageMorphology.dilate(x)))

function custom_fgen(name::Symbol, iotype::Type, s1::SorX)
    @eval function $name(x::iotype, y::iotype)::iotype
        $s1
    end
end

custom_fgen(:f_add_float, Float64, :(x + y))
