using ArcadeLearningEnvironment
using IICGP
using Test

ROM_NAMES = ["boxing", "assault", "freeway"]

@testset "Reset ALE" begin
    for rom_name in ROM_NAMES
        for _ in 1:10
            seed = 0
            game = Game(rom_name, seed)
            s0 = get_state(game, true, false)
            for t in 1:100
                action = 0
                act(game.ale, action)
            end
            reset!(game)
            s1 = get_state(game, true, false)
            @test s0 == s1
            #display(IICGP.implot(s0[1]))
            #display(IICGP.implot(s1[1]))
            close!(game)
        end
    end
end
