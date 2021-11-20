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

n_episodes = 500
n_steps = 10000
rom_name = "boxing"
game = Game(rom_name, 0)
actions = game.actions
mem_usage = Vector{Float64}()
cfgpath = "/home/opaweynch/.julia/environments/v1.6/dev/IICGP/cfg/eccgp_atari.yaml"
mcfg, ecfg, ccfg, redu, bootstrap = IICGP.dualcgp_config(cfgpath, rom_name)
enco = IPCGPInd(ecfg)
cont = CGPInd(ccfg)

for e in 1:n_episodes
	IICGP.reset!(game)
	for t in 1:n_steps
		s = get_state(game, true, true) # gain 2%
		output = IICGP.process(enco, redu, cont, ccfg, s)
		act(game.ale, actions[rand(1:length(actions))])
		if game_over(game.ale)
			break
		end
	end
	# Display memory
	mem = print_usage()
	push!(mem_usage, mem)
	out(lineplot(mem_usage, title = "%MEM"))
end
close!(game)



##

game = Game("boxing", 0)
gs = get_grayscale(game)
rgb = get_rgb(game)
x = gs[1]
features = redu.reduct(gs, redu.parameters)

IICGP.implot(rgb[1])
IICGP.implot(x)
IICGP.implot(pr2(x, redu.parameters), clim="auto")
IICGP.implot(pr1(x, redu.parameters), clim="auto")
IICGP.implot(features[1], clim="auto")



@btime pr1($x, $redu.parameters)
@btime pr2($x, $redu.parameters)

function pr1(x::Array{UInt8,2}, parameters::Dict)
    outsz = (parameters["size"], parameters["size"])
    tilesz = ceil.(Int, size(x)./outsz)
	out = Array{Float64, ndims(x)}(undef, outsz)
    R = TileIterator(axes(x), tilesz)
    i = 1
    for tileaxs in R
       out[i] = parameters["pooling_function"](view(x, tileaxs...))
       i += 1
    end
    return out ./ 255.0
end

function pr2(x::Array{UInt8,2}, parameters::Dict)
    outsz = (parameters["size"], parameters["size"])
    tilesz = ceil.(Int, size(x)./outsz)
    R = TileIterator(axes(x), tilesz)
    [parameters["pooling_function"](view(x, tileaxs...)) for tileaxs in R] ./ 255.0
end
