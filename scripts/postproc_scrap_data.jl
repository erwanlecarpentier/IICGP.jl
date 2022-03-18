#run(`cd /tmpdir/p21049le/ICGP-results/results`)
#run(`ls /tmpdir/p21049le/ICGP-results/results`)

resdirs = readdir("/tmpdir/p21049le/ICGP-results/results")
prefix = "2022-02-08T15:19:07.129_1_box"

for resdir in resdirs
	if startswith(resdir, prefix)
		println("mkdir ./results/", resdir)
		println("mkdir ./results/", resdir, "/gens/")
		println("shpass -f \"./pswd\" scp -r -P 11300 \$USERNAME@127.0.0.1:/tmpdir/\$USERNAME/ICGP-results/results/", resdir, "/logs ./results/", resdir)
		genfiles = readdir(string("/tmpdir/p21049le/ICGP-results/results/", resdir, "/gens/"))
		enco_genfile = genfiles[end]
		cont_genfile = genfiles[convert(Int64,ceil(length(genfiles)/2))]
		println("shpass -f \"./pswd\" scp -r -P 11300 \$USERNAME@127.0.0.1:/tmpdir/\$USERNAME/ICGP-results/results/", resdir, "/gens/", enco_genfile, " ./results/", resdir, "/gens/")
		println("shpass -f \"./pswd\" scp -r -P 11300 \$USERNAME@127.0.0.1:/tmpdir/\$USERNAME/ICGP-results/results/", resdir, "/gens/", cont_genfile, " ./results/", resdir, "/gens/")
	end
end
