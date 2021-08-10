#!/bin/bash
#SBATCH -J ataritest
#SBATCH -N 1
#SBATCH -n 3
#SBATCH --ntasks-per-node=3
#SBATCH --ntasks-per-core=1
#SBATCH -o ataritest.out
#SBATCH -e ataritest.log
#SBATCH --time=00:30:00
#SBATCH --mail-user=erwanlecarpentier@mailbox.org
#SBATCH --mail-type=END

julia --threads 3 --project=/users/p21001/lecarpen/IICGP.jl scripts/atari_monocgp.jl --game=assault
