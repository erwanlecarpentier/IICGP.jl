pre = "[[https://github.com/erwanlecarpentier/ICGP-results/blob/main/graphs/2022-02-21_"
post = ".png]]"
suffix = ""
b = "|"
rom_names = ["boxing", "gravitar", "freeway", "solaris", "space_invaders", "asteroids"]
#rom_names = ["boxing"]

println()
#println("||||")
#println("|---|---|---|")
for r in rom_names
    println(r)
    println("||||")
    println("|---|---|---|")
    println(string(
        b, pre, r, suffix, "/meanfit_vs_gen", post,
        b, pre, r, suffix, "/maxfit_vs_gen", post,
        b, pre, r, suffix, "/validation_vs_gen", post, b))
    println(string(
        b, pre, r, suffix, "/neval_vs_gen", post,
        b, pre, r, suffix, "/total_n_eval", post,
        b, pre, r, suffix, "/nevalperind_vs_gen", post, b))
    println(string(
        b, pre, r, suffix, "/bound_scale_vs_gen", post,
        b, pre, r, suffix, "/epsilon_vs_gen", post,
        b, pre, r, suffix, "/log_nevalperind_vs_gen", post, b))
    println()
end
