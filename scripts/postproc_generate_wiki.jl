pre = "[[https://github.com/erwanlecarpentier/ICGP-results/blob/main/graphs/2022-01-27_"
post = ".png]]"
b = "|"
rom_names = ["boxing", "gravitar", "freeway", "solaris", "space_invaders", "asteroids"]

println()
println("|Game||||")
println("|---|---|---|---|")
for r in rom_names
    println(string(b, r,
        b, pre, r, "/meanfit_vs_gen", post,
        b, pre, r, "/maxfit_vs_gen", post,
        b, pre, r, "/total_n_eval", post, b))
    println(string(b,
        b, pre, r, "/neval_vs_gen", post,
        b, pre, r, "/log_neval_vs_gen", post,
        b, pre, r, "/bound_scale_vs_gen", post, b))
end
