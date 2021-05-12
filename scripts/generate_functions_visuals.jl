using IICGP

function generate_visual(f::Function, rom_name::String, inps::AbstractArray)
    out = f(inps...)
    function_name = :($f)
    filename = string(@__DIR__, "/../images/", rom_name, "_", function_name)
    IICGP.save_img(out, filename)
end

function generate_img_pairs_dict()
    d = Dict()
    rom_list = setdiff(getROMList(), ["pacman", "surround"])
    rom_list = ["alien"]  # TODO remove
    for rom in rom_list
        d[rom] = [IICGP.load_rgb(rom, 30)[1], IICGP.load_rgb(rom, 31)[1]]
    end
    d
end






functions = [
    IICGP.CGPFunctions.f_dilate,
    IICGP.CGPFunctions.f_erode,
    IICGP.CGPFunctions.f_remove_details
]
pairs_dict = generate_img_pairs_dict()
for f in functions
    for (key, value) in pairs_dict
        generate_visual(f, key, value)
    end
end
