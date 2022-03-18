#run(`cd /tmpdir/p21049le/ICGP-results/results`)
#run(`ls /tmpdir/p21049le/ICGP-results/results`)

resdirs = readdir("/tmpdir/p21049le/ICGP-results/results")
prefix = "2022-02-08T15"

for resdir in resdirs
	if startswith(resdir, prefix)
		println()
		println("echo ", resdir)
		println("mkdir -p ./results/", resdir)
		println("mkdir -p ./results/", resdir, "/gens/")
		println("sshpass -f \"./pswd\" scp -r -P 11300 \$USERNAME@127.0.0.1:/tmpdir/\$USERNAME/ICGP-results/results/", resdir, "/logs ./results/", resdir)
		genfiles = readdir(string("/tmpdir/p21049le/ICGP-results/results/", resdir, "/gens/"))
		gen_numbers = [parse(Int64, split(f, "_")[2]) for f in genfiles]
		sort!(gen_numbers)
		last_gen = maximum(gen_numbers)
		pre_last_gen = gen_numbers[end-2]
		for g in [last_gen, pre_last_gen]
			println("sshpass -f \"./pswd\" scp -r -P 11300 \$USERNAME@127.0.0.1:/tmpdir/\$USERNAME/ICGP-results/results/", resdir, "/gens/encoder_", g, " ./results/", resdir, "/gens/")
			println("sshpass -f \"./pswd\" scp -r -P 11300 \$USERNAME@127.0.0.1:/tmpdir/\$USERNAME/ICGP-results/results/", resdir, "/gens/controller_", g, " ./results/", resdir, "/gens/")
		end
	end
end
