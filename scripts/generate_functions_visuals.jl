using IICGP

function generate_visual(f::Function, inps::AbstractArray)
    out = f(inps...)
    println(typeof(out))
end

function generate_img_pairs()
    pairs = Array{Array{Array{UInt8,2},1},1}()
    rom_list = setdiff(getROMList(), ["pacman", "surround"])
    for rom in rom_list
        append!(pairs, [[IICGP.load_rgb(rom, 30)[1], IICGP.load_rgb(rom, 31)[1]]])
    end
    pairs
end







functions = [
    IICGP.CGPFunctions.f_dilate,
    IICGP.CGPFunctions.f_erode,
    IICGP.CGPFunctions.f_remove_details
]

pairs = generate_img_pairs()

for f in functions
    for p in pairs
        generate_visual(f, p)
    end
end
