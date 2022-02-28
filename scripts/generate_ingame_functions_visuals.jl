using ArcadeLearningEnvironment
using IICGP
using Statistics
using TiledIteration

function x_input(img1::Matrix{UInt8}, img2::Matrix{UInt8}, p::Array{Float64})
    img1
end

function y_input(img1::Matrix{UInt8}, img2::Matrix{UInt8}, p::Array{Float64})
    img2
end

function mean_pool(x::Matrix{UInt8}, img2::Matrix{UInt8}, p::Array{Float64})
    outsz = (5, 5)
    tilesz = ceil.(Int, size(x)./outsz)
    R = TileIterator(axes(x), tilesz)
    [Statistics.mean(view(x, tileaxs...)) for tileaxs in R] ./ 255.0
end

transpose_save(x::Matrix, p::String) = save_img(convert(Matrix,transpose(x)), p)

function get_path(
	rootdir::String,
	rom_name::String,
	seed::Int64,
	frame::Int64,
	name::String
)
	fname = string(rom_name, "_s", seed, "_f", frame, "_", name, ".png")
	joinpath(rootdir, fname)
end

function generate_ingame_visuals(
    fprocess::Function,
    rom_name::String,
    seed::Int64,
	max_frames::Int64,
	grayscale::Bool,
	downscale::Bool;
    verbose::Bool=true
)
    game = Game(rom_name, seed)
    s = get_state_buffer(game, grayscale)
	o = get_observation_buffer(game, grayscale, downscale)
    reward = 0.0
    frame = 0
    while ~game_over(game.ale)
		get_state!(s, game, grayscale)
		get_observation!(o, s, game, grayscale, downscale)
		action = game.actions[rand(1:length(game.actions))]
        reward += act(game.ale, action)
        frame += 1
		fprocess(rom_name, o, frame, seed)
        if frame >= max_frames
            break
        end
    end
    close!(game)
    if verbose
		println("Generated visuals:")
        println("Game          : ", rom_name)
        println("Seed          : ", seed)
        println("Total return  : ", reward)
        println("Reached frame : ", frame)
    end
end

function generate_visual(
    fprocess::Function,
    rom_names::Vector{String},
    seeds::Vector{Int64},
	max_frames::Int64,
	grayscale::Bool,
	downscale::Bool
)
    for rom_name in rom_names
        for seed in seeds
            generate_ingame_visuals(fprocess, rom_name, seed, max_frames,
				grayscale, downscale)
        end
    end
end

function sequential_fprocess(
	rom_name::String,
	o::Vector{Matrix{UInt8}},
	frame::Int64,
	seed::Int64
)
	functions = [
		x_input,
		y_input,
		IICGP.CGPFunctions.f_dilate,
		IICGP.CGPFunctions.f_erode,
		IICGP.CGPFunctions.f_subtract,
		IICGP.CGPFunctions.f_binary,
		IICGP.CGPFunctions.f_threshold,
		IICGP.CGPFunctions.f_bitwise_not,
		IICGP.CGPFunctions.f_bitwise_and,
		IICGP.CGPFunctions.f_bitwise_or,
		IICGP.CGPFunctions.f_bitwise_xor,
		IICGP.CGPFunctions.f_motion_capture,
		mean_pool
	]
	p = [0.5]
	for f in functions
		for i in eachindex(o)
			out = f(o[i], o[i], p)
			fname = string(
				rom_name,
				"seed", seed,
				"_frame", frame,
				"_in", i,
				"_", f, ".png")
			fpath = joinpath(rootdir, fname)
			transpose_save(out, fpath)
		end
	end
end

function custom_fprocess(
	rom_name::String,
	o::Vector{Matrix{UInt8}},
	frame::Int64,
	seed::Int64
)
	path(name::String) = get_path(rootdir, rom_name, seed, frame, name)
	p = [0.5]
	inp = o[1]
	mot = IICGP.CGPFunctions.f_motion_capture(inp, inp, pmot)
	dil = IICGP.CGPFunctions.f_dilate(mot, mot, p)
	dil = IICGP.CGPFunctions.f_dilate(dil, dil, p)
	dil = IICGP.CGPFunctions.f_dilate(dil, dil, p)
	out = mean_pool(dil, dil, p)
	transpose_save(inp, path("input"))
	transpose_save(mot, path("motion"))
	transpose_save(dil, path("dilate"))
	transpose_save(out, path("output"))
end

pmot = [0.5]

rootdir = joinpath(homedir(), "Documents/git/ICGP-paper/img/atari/")
rom_names = ["boxing"]#, "pong"]
seeds = [0]
max_frames = 3
grayscale, downscale = true, false
fprocess = custom_fprocess

generate_visual(fprocess, rom_names, seeds, max_frames, grayscale, downscale)
