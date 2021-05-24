#!/bin/bash
#SBATCH -J main-exp
#SBATCH -N 1
#SBATCH -n 36
#SBATCH --ntasks-per-node=36
#SBATCH --ntasks-per-core=1
#SBATCH -o main.out
#SBATCH -e main.log
#SBATCH --time=01:00:00
#SBATCH --mail-user=erwanlecarpentier@mailbox.org
#SBATCH --mail-type=END

julia scripts/dualcgp.jl
