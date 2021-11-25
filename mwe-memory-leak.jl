using UnicodePlots

out(plt) = println(IOContext(stdout, :color=>true), plt)

function print_mem_usage()
	out = read(`top -bn1 -p $(getpid())`, String)
	res = split(split(out,  "\n")[end-1])
	println("RES: ", res[6], "   %MEM: ", res[10], "   %CPU: ", res[9])
	parse(Float64, replace(res[10], "," => "."))
end

mutable struct Foo
	f::Function
end

function f1(x::Matrix{Float64})
    out = copy(x)
    out[x .< 0.5] .= 0.0
    out[x .>= 0.5] .= 1.0
    out
end

function f2(x::Matrix{Float64})
	reshape([x[i] < 0.5 ? 0.0 : 1.0 for i in eachindex(x)], size(x))
end

function test(foo::Foo)
	mem_usage = Vector{Float64}()
	for i in 1:1000
		x = rand(1000, 1000)
		foo.f(x)
		mem = print_mem_usage()
		push!(mem_usage, mem)
		out(lineplot(mem_usage, title = "%MEM"))
	end
end

foo = Foo(f1)
test(foo)
