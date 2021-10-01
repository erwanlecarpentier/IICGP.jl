#!/bin/bash
#SBATCH -J atari_test_frostbite
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --ntasks-per-node=1
#SBATCH --ntasks-per-core=1
#SBATCH -o /tmpdir/%u/logs/job%J_atari_test_frostbite.out
#SBATCH -e /tmpdir/%u/logs/job%J_atari_test_frostbite.log
#SBATCH --time=00:03:00
#SBATCH --mail-user=erwanlecarpentier@mailbox.org
#SBATCH --mail-type=END

OUTDIR="/tmpdir/%u/ICGP-results"

julia --threads 1 --project=/home/opaweynch/.julia/environments/v1.6/dev/IICGP scripts/atari_dualcgp.jl --cfg=cfg/test_dual.yaml --game=frostbite --out=$OUTDIR
