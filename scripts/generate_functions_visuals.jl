using IICGP

function x_input(img1::Array{UInt8,2}, img2::Array{UInt8,2}, p::Array{Float64})::Array{UInt8,2}
    img1
end

function y_input(img1::Array{UInt8,2}, img2::Array{UInt8,2}, p::Array{Float64})::Array{UInt8,2}
    img2
end

function max_pool(img1::Array{UInt8,2}, img2::Array{UInt8,2}, p::Array{Float64})
    IICGP.ReducingFunctions.max_pool_reduction(img1)
end

function generate_img_pairs_dict(;rom_names=nothing)
    d = Dict{String,Array{Array{UInt8,2},1}}()
    if rom_names === nothing
        rom_names = setdiff(getROMList(), ["pacman", "surround"])
    end
    for rom in rom_names
        d[rom] = [
            IICGP.load_rgb(rom, 30)[1],
            IICGP.load_rgb(rom, 30)[2],
            IICGP.load_rgb(rom, 31)[1],
            IICGP.load_rgb(rom, 31)[2]
        ]
    end
    d
end

function generate_visual(f::Function, rom_name::String, inps::AbstractArray)
    p = [0.1]
    out = f(inps[1], inps[2], p)
    out = f(inps[3], inps[4], p)
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
    x_input,
    y_input,
    IICGP.CGPFunctions.f_dilate,
    IICGP.CGPFunctions.f_erode,
    IICGP.CGPFunctions.f_subtract,
    IICGP.CGPFunctions.f_remove_details,
    IICGP.CGPFunctions.f_make_boxes,
    IICGP.CGPFunctions.f_felzenszwalb_segmentation,
    IICGP.CGPFunctions.f_components_segmentation,
    IICGP.CGPFunctions.f_box_segmentation,
    IICGP.CGPFunctions.f_negative,
    IICGP.CGPFunctions.f_threshold,
    IICGP.CGPFunctions.f_binary,
    IICGP.CGPFunctions.f_motion_capture,
    IICGP.CGPFunctions.f_motion_distances,
    IICGP.CGPFunctions.f_corners,
    IICGP.CGPFunctions.f_gaussian,
    IICGP.CGPFunctions.f_laplacian,
    IICGP.CGPFunctions.f_sobel_x,
    IICGP.CGPFunctions.f_sobel_y,
    IICGP.CGPFunctions.f_canny,
    IICGP.CGPFunctions.f_edges,
    IICGP.CGPFunctions.f_opening,
    IICGP.CGPFunctions.f_closing,
    IICGP.CGPFunctions.f_tophat,
    IICGP.CGPFunctions.f_bothat,
    IICGP.CGPFunctions.f_morphogradient,
    IICGP.CGPFunctions.f_morpholaplace,
    IICGP.CGPFunctions.f_bitwise_not,
    IICGP.CGPFunctions.f_bitwise_and,
    IICGP.CGPFunctions.f_bitwise_or,
    IICGP.CGPFunctions.f_bitwise_xor,
    max_pool
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
