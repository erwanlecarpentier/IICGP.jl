#!/bin/bash
#SBATCH -J atari_centroid_solaris
#SBATCH -N 1
#SBATCH -n 25
#SBATCH --ntasks-per-node=25
#SBATCH --ntasks-per-core=1
#SBATCH -o atari_centroid_solaris.out
#SBATCH -e atari_centroid_solaris.log
#SBATCH --time=5-00:00:00
#SBATCH --mail-user=erwanlecarpentier@mailbox.org
#SBATCH --mail-type=END

julia --threads 25 --project=/users/p21049/p21049le/IICGP.jl scripts/atari_dualcgp.jl --cfg=cfg/dualcgp_atari_centroid.yaml --game=solaris
