#!/bin/bash
#SBATCH -J atari-$1
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --ntasks-per-node=1
#SBATCH --ntasks-per-core=1
#SBATCH -o atari-$1.out
#SBATCH -e atari-$1.log
#SBATCH --time=96:00:00
#SBATCH --mail-user=erwanlecarpentier@mailbox.org
#SBATCH --mail-type=END

julia --project=/users/p21001/lecarpen/IICGP.jl scripts/atari.jl --game=$1 &
