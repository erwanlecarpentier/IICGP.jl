using ArcadeLearningEnvironment
using IICGP
using Random

function play_atari(
    game::String,
    seed::Int64,
    max_frames::Int64,
    stickiness::Float64
)
    Random.seed!(seed)
    game = Game(game, seed)
    ArcadeLearningEnvironment.restoreSystemState(game.ale, state_ref)
    s_traj = Array{Array{Array{UInt8,2},1},1}()
    a_traj = Array{Int64,1}()
    r_traj = Array{Float64,1}()
    e_traj = Array{Float64,1}()
    frames = 0
    prev_action = 0
    while ~game_over(game.ale)
        e = rand()
        if e > stickiness || frames == 0
            action = game.actions[rand(1:length(game.actions))]
        else
            action = prev_action
        end
        r = act(game.ale, action)
        s = get_rgb(game)
        push!(s_traj, s)
        push!(a_traj, action)
        push!(r_traj, r)
        push!(e_traj, e)
        frames += 1
        if frames > max_frames
            break
        end
    end
    close!(game)
    s_traj, a_traj, r_traj, e_traj
end

const game = "assault"
const seed = 0
Random.seed!(seed)
max_frames = 100
stickiness = 0.25
nthreads = Threads.nthreads()
inline_test = true
n_inline_rep = 10

# Reference
s1, a1, r1, e1 = play_atari(game, seed, max_frames, stickiness)


# State reference
g = Game(game, seed)
const state_ref = ArcadeLearningEnvironment.cloneSystemState(g.ale)
close!(g)


if inline_test
    for i in 1:n_inline_rep
        s2, a2, r2, e2 = play_atari(game, seed, max_frames, stickiness)
        println()
        println("same states  : ", s1 == s2)
        println("same actions : ", a1 == a2)
        println("same rewards : ", r1 == r2)
        println("same e       : ", e1 == e2)
    end
else
    @sync for i in 1:nthreads
        Threads.@spawn begin
            s2, a2, r2 = play_atari(game, seed, max_frames, stickiness)
            println()
            println("threadid     : ", Threads.threadid())
            println("same states  : ", s1 == s2)
            println("same actions : ", a1 == a2)
            println("same rewards : ", r1 == r2)
        end
    end
end



##
using BenchmarkTools
using Images
using ArcadeLearningEnvironment
using IICGP

const p = 0.5

function rescale_uint_img(x::AbstractArray)::Array{UInt8}
    mini, maxi = minimum(x), maximum(x)
    if mini == maxi
        return floor.(UInt8, mod.(x, 255))
    end
    m = (convert(Array{Float64}, x) .- mini) .* (255 / (maxi - mini))
    floor.(UInt8, m)
end

function f1(x::Array{UInt8,2})::Array{UInt8,2}
    k = Images.Kernel.gaussian(ceil(Int64, 5 * p))
    out = ImageFiltering.imfilter(x, k)
    return rescale_uint_img(out)
end

function f2(x::Array{UInt8,2})# ::Array{UInt8,2}
    k = Images.Kernel.gaussian(ceil(Int64, 5 * p))
    return ImageFiltering.imfilter(x, k)
end

ImType = Base.ReinterpretArray{Normed{UInt8,8},2,UInt8,Array{UInt8,2}}

f3(x) = ImageFiltering.imfilter(x, Images.Kernel.gaussian(ceil(Int64, 5 * p)))
f4(x) = ImageFiltering.imfilter(x, [-1 1 -1; -1 0 -1; -1 1 -1])
f5(x) = ImageFiltering.imfilter(x, Images.Kernel.Laplacian())
f6(x) = Images.canny(x, (Images.Percentile(80), Images.Percentile(20)))
f7(x) = Images.imedge(x)[3]
f8(x) = ImageMorphology.dilate(x)
f9(x) = ImageMorphology.erode(x)


game = Game("assault", 0)
r, g, b = get_rgb(game)
close!(game)

xr = reinterpret(N0f8, r)
xg = reinterpret(N0f8, g)
x = xr
y3 = f3(x)
y4 = f4(x)
y5 = f5(x)
y6 = f6(x)
y7 = f7(x)
y8 = f8(x)
y9 = f9(x)

functions = [f3, f4, f5, f6, f7, f8, f9]
for f in functions
    y = f(x)
    iplot(y)
    for g in functions
        g(y)
    end
end

y34 = f4(y3)
y43 = f3(y4)


if false
    @btime f1(r)
    @btime f2(r)
    @btime f3(x)
    @btime o4 = f4(x)
    # display(implot(o1))
    # display(implot(o2))
end

nplot(x) = display(implot(rawview(x)))
iplot(x) = display(implot(x, clim="auto"))

iplot(r)

##

using TiledIteration
using IICGP
using Images
using BenchmarkTools
using Interpolations

iplot(x) = display(implot(x, clim="auto"))

game = Game("assault", 0)
r, g, b = get_rgb(game)
rgb = get_rgb(game)
gs = get_grayscale(game)


function downscale(x::Array{UInt8,2}; factor::Int64=2)
    outsz = ceil.(Int, size(x)./factor)
    tilesz = (factor,factor)
    out = Array{UInt8,2}(undef, outsz)
    R = TileIterator(axes(x), tilesz)
    i = 1
    for tileaxs in R
       out[i] = maximum(view(x, tileaxs...))
       i += 1
    end
    out
end

function prints(s::AbstractArray)
    for si in s
        iplot(si)
    end
end

r_down = downscale(r)

iplot(r)
iplot(imresize(r, ratio=0.5, method=BSpline(Constant())))
iplot(imresize(r, ratio=0.5, method=Linear()))
iplot(imresize(r, ratio=0.5, method=BSpline(Linear())))

if false
    @btime s = get_state(game, false, false)
    @btime s = get_state(game, true, false)
    @btime s = get_state(game, false, true)
    @btime s = get_state(game, true, true)
end

# prints(s)

s = get_state(game, true, true)

functions = [
    IICGP.CGPFunctions.f_threshold,
    IICGP.CGPFunctions.f_subtract,
    IICGP.CGPFunctions.f_binary,
    IICGP.CGPFunctions.f_erode,
    IICGP.CGPFunctions.f_dilate,
    IICGP.CGPFunctions.f_bitwise_not,
    IICGP.CGPFunctions.f_bitwise_and,
    IICGP.CGPFunctions.f_bitwise_or,
    IICGP.CGPFunctions.f_bitwise_xor,
    IICGP.CGPFunctions.f_motion_capture
]

gs = s[1]
println()
for f in functions
    f_name = string(f)
    print("| ", f_name, " | ")
    p = [0.33]
    f(gs, gs, p)
    @btime $f($gs, $gs, $p)
end

close!(game)
