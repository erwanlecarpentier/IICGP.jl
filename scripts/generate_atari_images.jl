using ArcadeLearningEnvironment
import Random

rom_list = getROMList()
buggy = ["pacman", "surround"]
noop = 0
saved_frames = [0, 1, 2, 30, 31]
last_frame = max(saved_frames...)

for rom_name in rom_list
    if rom_name ∉ buggy
        ale = ALE_new()
        loadROM(ale, rom_name)
        # actions = getMinimalActionSet(ale)

        frame_number = 0
        while ~game_over(ale)
            act(ale, noop)
            if frame_number ∈ saved_frames
                filename = string(@__DIR__, "../images/", rom_name, "_frame_$frame_number.png")
                saveScreenPNG(ale, filename)
            end
            if frame_number > last_frame
                break
            end
            frame_number += 1
        end

        ALE_del(ale)
    end
end
