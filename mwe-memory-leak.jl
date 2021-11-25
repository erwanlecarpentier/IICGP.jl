using UnicodePlots

out(plt) = println(IOContext(stdout, :color=>true), plt)

function print_mem_usage()
	out = read(`top -bn1 -p $(getpid())`, String)
	res = split(split(out,  "\n")[end-1])
	println("RES: ", res[6], "   %MEM: ", res[10], "   %CPU: ", res[9])
	parse(Float64, replace(res[10], "," => "."))
end

module MyFunctions
function f1(x::Matrix{Float64})
    out = copy(x)
    out[x .< 0.5] .= 0.0
    out[x .>= 0.5] .= 1.0
    out
end
function f2(x::Matrix{Float64})
	reshape([x[i] < 0.5 ? 0.0 : 1.0 for i in eachindex(x)], size(x))
end
end

struct Foo
	functions::Vector{Function}
end

function Foo(function_module::Module, fname::String)
	functions = Array{Function}(undef, 1)
	functions[1] = getfield(function_module, Symbol(fname))
	Foo(functions)
end

mutable struct Bar
	f::Function
end

function Bar(foo::Foo)
	f = foo.functions[1]
	Bar(f)
end

function test(bar::Bar)
	mem_usage = Vector{Float64}()
	for i in 1:100
		x = rand(1000, 1000)
		bar.f(x)
		mem = print_mem_usage()
		push!(mem_usage, mem)
		out(lineplot(mem_usage, title = "%MEM"))
	end
end

function_module = MyFunctions
fname = "f1"
foo = Foo(function_module, fname)
bar = Bar(foo)

test(bar)
