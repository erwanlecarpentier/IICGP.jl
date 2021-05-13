using IICGP

function original(img1::Array{UInt8,2}, img2::Array{UInt8,2})::Array{UInt8,2}
    img1
end

function generate_img_pairs_dict(;rom_names=nothing)
    d = Dict{String,Array{Array{UInt8,2},1}}()
    if rom_names === nothing
        rom_names = setdiff(getROMList(), ["pacman", "surround"])
    end
    for rom in rom_names
        d[rom] = [IICGP.load_rgb(rom, 30)[1], IICGP.load_rgb(rom, 31)[1]]
    end
    d
end

function generate_visual(f::Function, rom_name::String, inps::AbstractArray)
    out = f(inps...)
    function_name = :($f)
    filename = string(@__DIR__, "/../images/filtered/", rom_name, "_function_",
                      function_name, ".png")
    IICGP.save_img(out, filename)
end

function generate_visual(functions::Array{Function};
                         rom_names=nothing)
    pairs_dict = generate_img_pairs_dict(rom_names=rom_names)
    for f in functions
        for (key, value) in pairs_dict
            generate_visual(f, key, value)
        end
    end
end

functions = [
    original,
    IICGP.CGPFunctions.f_dilate,
    IICGP.CGPFunctions.f_erode,
    IICGP.CGPFunctions.f_remove_details
]
rom_names = [
    "boxing",
    "centipede",
    "demon_attack",
    "enduro",
    "freeway",
    "kung_fu_master",
    "space_invaders",
    "riverraid",
    "pong"
]
generate_visual(functions, rom_names=rom_names)
