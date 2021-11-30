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
using Random


out(plt) = println(IOContext(stdout, :color=>true), plt)

function print_usage()
	out = read(`top -bn1 -p $(getpid())`, String)
	res = split(split(out,  "\n")[end-1])
	println("RES: ", res[6], "   %MEM: ", res[10], "   %CPU: ", res[9])
	parse(Float64, replace(res[10], "," => "."))
end

function fakeplay(n_steps::Int64)
	for t in 1:n_steps
		s = [rand(UInt8, 80, 105)]
		output = IICGP.process(enco, redu, cont, ccfg, s)

		#CartesianGeneticProgramming.process(enco, s)
		#features_flatten = rand(35)
	    #push!(features_flatten, 0:1.0/(10-1):1.0...)
		#CartesianGeneticProgramming.process(cont, features_flatten)
	end
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

seed = 4
Random.seed!(seed)
n_iter = 25000
n_para = 4
n_steps = 10000
rom_name = "boxing"
#games = [Game(rom_name, 0) for _ in 1:n_para]
mem_usage = Vector{Float64}()
cfgpath = "/home/opaweynch/.julia/environments/v1.6/dev/IICGP/cfg/eccgp_atari_nsga2.yaml"
mcfg, ecfg, ccfg, redu, bootstrap = IICGP.dualcgp_config(cfgpath, rom_name)
enco = IPCGPInd(ecfg)
cont = CGPInd(ccfg)
grayscale, downscale = true, true
##

for e in 1:n_iter
	#=for i in 1:n_para
		fakeplay(n_steps)
	end=#
	@sync for i in 1:n_para
		Threads.@spawn begin
			fakeplay(n_steps)
			#play(games[i], n_steps, grayscale, downscale)
		end
	end
	mem = print_usage()
	push!(mem_usage, mem)
	out(lineplot(mem_usage, title = "%MEM"))
end

#=for game in games
	close!(game)
end=#
