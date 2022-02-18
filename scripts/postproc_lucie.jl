using IICGP
using Dates
using Plots

#=
1. Specify where results are saved
Should be the same as `output directory`, specified in atari_lucie.jl arguments.
=#
rootdir = joinpath(homedir(), "Documents/git/ICGP-results/")
#rootdir = dirname(@__DIR__)
resdir = joinpath(rootdir, "results/")

#=
2. Filter parameters
Postproc will only consider experiments with the following criteria:
- Exp date should be between `min_date` and `max_date`
- Only roms in `rom_names` will be considered
- Only experiments using the reducer in `reducers` will be considered
=#
min_date = DateTime(2022, 02, 08, 14, 40)
max_date = DateTime(2022, 02, 08, 17, 00)
rom_names = ["boxing", "gravitar", "freeway", "solaris", "space_invaders", "asteroids"]
rom_names = ["asteroids"]
reducers = ["pooling"]
suffix="epsilon2"

#=
3. Some styling
=#
theme(:ggplot2) # :default
labels = Vector{String}()
colors = Vector{Symbol}()
#colors = [:skyblue3]
#labels = ["LUCIE"]
#savedir_index = 1

#=
4. Run postproc for all selected exp_dir
=#
for rom_name in rom_names
    exp_dirs, ids, games = get_exp_dir(resdir, min_date=min_date, max_date=max_date,
        games=[rom_name], reducers=reducers)
    process_lucie_results(exp_dirs, games, colors, labels, do_display=true,
        do_save=true, omit_last_gen=false, suffix=suffix)
end
