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

function play(game::Game, n_steps::Int64, grayscale::Bool, downscale::Bool)
	IICGP.reset!(game)
	s = get_state_buffer(game, grayscale)
	o = get_observation_buffer(game, grayscale, downscale)
	for t in 1:n_steps
		get_state!(s, game, grayscale)
		get_observation!(o, s, game, grayscale, downscale)
		#s = getScreenRGB(game.ale)
		output = IICGP.process(enco, redu, cont, ccfg, o)
		act(game.ale, game.actions[rand(1:length(game.actions))])
		if game_over(game.ale)
			break
		end
	end
end

n_iter = 500
n_para = 4
n_steps = 10000
rom_name = "boxing"
games = [Game(rom_name, 0) for _ in 1:n_para]
mem_usage = Vector{Float64}()
cfgpath = "/home/opaweynch/.julia/environments/v1.6/dev/IICGP/cfg/eccgp_atari.yaml"
mcfg, ecfg, ccfg, redu, bootstrap = IICGP.dualcgp_config(cfgpath, rom_name)
enco = IPCGPInd(ecfg)
cont = CGPInd(ccfg)
grayscale, downscale = true, true

for e in 1:n_iter
	@sync for i in 1:n_para
		Threads.@spawn begin
			play(games[i], n_steps, grayscale, downscale)
		end
	end
	#play(games[1], n_steps, grayscale, downscale)
	mem = print_usage()
	push!(mem_usage, mem)
	out(lineplot(mem_usage, title = "%MEM"))
end

for game in games
	close!(game)
end

##

mutable struct Foo
	v::Int64
	b::Bool
end

pop = [Foo(i, false) for i in 1:10]
for i in [1, 3, 5, 6, 7]
	pop[i].b = true
end

filter!(ind -> ind.b, pop)

function get_count(pop::Vector{Foo})
	sum([ind.b for ind in pop])
end

function get_count2(pop::Vector{Foo})
	count(i->i.b, pop)
end

@btime get_count($pop)
@btime get_count2($pop)

##

game = Game("boxing", 0)
grayscale = true
downscale = true

s = get_state_buffer(game, grayscale)
o = get_observation_buffer(game, grayscale, downscale)
# 81 x 106

get_state!(s, game, grayscale)
get_observation!(o, s, game, grayscale, downscale)


##

IICGP.implot(o[1])

for t in 1:600
	act(game.ale, game.actions[rand(1:length(game.actions))])
end


##

IICGP.implot(ds1(x))
IICGP.implot(ds3(x))

function ds1(x::Matrix{UInt8})
	convert(
		Matrix{UInt8},
		floor.(
			imresize(x, ratio=0.5, method=BSpline(Linear()))
		)
	)
end

function ds3(x::Matrix{UInt8})
	convert(
		Matrix{UInt8},
		floor.(
			imresize(x, ratio=0.5, method=BSpline(Constant()))
		)
	)
end

function ds2(x::Matrix{UInt8})
	convert(
		Matrix{UInt8},
		floor.([mean(UInt8, view(x, tile...)) for tile in TileIterator(axes(x), (2, 2))])
	)
end

@btime ds1($x)
@btime ds3($x)
