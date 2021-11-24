using ArcadeLearningEnvironment
using CartesianGeneticProgramming
using IICGP
using UnicodePlots
using ImageCore
using ImageTransformations
using Interpolations
using BenchmarkTools
using TiledIteration
using Images
using ImageMorphology
using LinearAlgebra

out(plt) = println(IOContext(stdout, :color=>true), plt)

function print_usage()
	out = read(`top -bn1 -p $(getpid())`, String)
	res = split(split(out,  "\n")[end-1])
	println("RES: ", res[6], "   %MEM: ", res[10], "   %CPU: ", res[9])
	parse(Float64, replace(res[10], "," => "."))
end

mutable struct Foo
	f::Function
	p::Vector{Float64}
end

function test_function(foo::Foo, n::Int64)
	mem_usage = Vector{Float64}()
	for i in 1:n
		x = rand(UInt8, 1000, 1000)
		y = rand(UInt8, 1000, 1000)
		foo.f(x, y, foo.p)
		mem = print_usage()
		push!(mem_usage, mem)
		out(lineplot(mem_usage, title = "%MEM"))
	end
end

functions = [
    IICGP.CGPFunctions.f_dilate,
    IICGP.CGPFunctions.f_erode,
    IICGP.CGPFunctions.f_subtract,
    IICGP.CGPFunctions.f_threshold,
    IICGP.CGPFunctions.f_binary,
    IICGP.CGPFunctions.f_bitwise_not,
    IICGP.CGPFunctions.f_bitwise_and,
    IICGP.CGPFunctions.f_bitwise_or,
    IICGP.CGPFunctions.f_bitwise_xor,
	IICGP.CGPFunctions.f_motion_capture
]

functions = [IICGP.CGPFunctions.f_motion_capture]

for i in eachindex(functions)
	foo = Foo(functions[i], [0.5])
	test_function(foo, 300)
end
