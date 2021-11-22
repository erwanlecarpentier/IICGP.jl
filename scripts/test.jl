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
		# output = IICGP.process(enco, redu, cont, ccfg, s)
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
grayscale = true
downscale = true

for e in 1:n_iter
	@sync for i in 1:n_para
		Threads.@spawn begin
			play(games[i], n_steps, grayscale, downscale)
		end
	end
	mem = print_usage()
	push!(mem_usage, mem)
	out(lineplot(mem_usage, title = "%MEM"))
end

for game in games
	close!(game)
end



##

#game = Game("boxing", 0)
grayscale = false
downscale = true

s = get_state_buffer(game, grayscale)
o = get_observation_buffer(game, grayscale, downscale)
# 81 x 106

get_state!(s, game, grayscale)
get_observation!(o, s, game, grayscale, downscale)
@btime get_observation!($o, $s, $game, $grayscale, $downscale)

# 1 1 - 41.143 μs (16 allocations: 276.27 KiB)
# 1 0 - 77.752 ns (3 allocations: 192 bytes)
# 0 0 - 54.647 μs (7 allocations: 98.97 KiB)
# 0 1 - 158.778 μs (43 allocations: 828.58 KiB)
##

IICGP.implot(o[3])

for t in 1:600
	act(game.ale, game.actions[rand(1:length(game.actions))])
end
