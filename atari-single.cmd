#!/bin/bash
#SBATCH -J atari
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --ntasks-per-node=1
#SBATCH --ntasks-per-core=1
#SBATCH -o atari.out
#SBATCH -e atari.log
#SBATCH --time=96:00:00
#SBATCH --mail-user=erwanlecarpentier@mailbox.org
#SBATCH --mail-type=END

echo julia --project=/users/p21001/lecarpen/IICGP.jl scripts/atari.jl --game=$1
