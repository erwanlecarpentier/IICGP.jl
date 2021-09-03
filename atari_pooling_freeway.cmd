#!/bin/bash
#SBATCH -J atari_pooling_freeway
#SBATCH -N 1
#SBATCH -n 25
#SBATCH --ntasks-per-node=25
#SBATCH --ntasks-per-core=1
#SBATCH -o atari_pooling_freeway.out
#SBATCH -e atari_pooling_freeway.log
#SBATCH --time=5-00:00:00
#SBATCH --mail-user=erwanlecarpentier@mailbox.org
#SBATCH --mail-type=END

julia --threads 25 --project=/users/p21049/p21049le/IICGP.jl scripts/atari_dualcgp.jl --cfg=cfg/dualcgp_atari_pooling.yaml --game=freeway
