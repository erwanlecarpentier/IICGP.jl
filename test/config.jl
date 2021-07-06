using Statistics


@testset "Config parser" begin
    cfg_filename = string(@__DIR__, "/dualcgp_test.yaml")
    game_name = "enduro"
    seed=0
    game = Game(game_name, seed)
    n_in = 3  # RGB images
    n_out = length(getMinimalActionSet(game.ale))  # One output per legal action
    rgb = get_rgb(game)
    img_size = size(rgb[1])
    close!(game)

    encoder_cfg, controller_cfg, reducer = IICGP.dualcgp_config(
        cfg_filename, game_name, seed=seed
    )

    # I/O dimensionality
    @test encoder_cfg.n_in == n_in
    @test encoder_cfg.n_out == 2
    @test controller_cfg.n_in == 50
    @test controller_cfg.n_out == n_out

    @test encoder_cfg.img_size == img_size
    @test encoder_cfg.id == controller_cfg.id
    @test encoder_cfg.n_parameters == controller_cfg.n_parameters == 1

    @test reducer.parameters["pooling_function"] == Statistics.mean
    @test reducer.parameters["size"] == 5

    # Construction and processing test
    enco = IICGP.IPCGPInd(encoder_cfg)
    cont = CartesianGeneticProgramming.CGPInd(controller_cfg)
    features, out = IICGP.process_f(enco, reducer, cont, rgb)
    @test typeof(features) == Array{Array{Float64,2},1}
    @test length(features) == encoder_cfg.n_out
    @test typeof(out) == Array{Float64,1}
    @test length(out) == n_out
end
