pre = "[[https://github.com/erwanlecarpentier/ICGP-results/blob/main/graphs/2022-02-08_"
post = ".png]]"
b = "|"
rom_names = ["boxing", "gravitar", "freeway", "solaris", "space_invaders", "asteroids"]

println()
#println("||||")
#println("|---|---|---|")
for r in rom_names
    println(r)
    println("||||")
    println("|---|---|---|")
    println(string(
        b, pre, r, "/meanfit_vs_gen", post,
        b, pre, r, "/maxfit_vs_gen", post,
        b, pre, r, "/neval_vs_gen", post, b))
    println(string(
        b, pre, r, "/nevalperind_vs_gen", post,
        b, pre, r, "/log_nevalperind_vs_gen", post,
        b, pre, r, "/bound_scale_vs_gen", post, b))
end
