#!/bin/bash
#SBATCH -J test-multithread
#SBATCH -N 1
#SBATCH -n 4
#SBATCH --ntasks-per-node=4
#SBATCH --ntasks-per-core=1
#SBATCH -o test.out
#SBATCH -e test.log
#SBATCH --time=00:05:00
#SBATCH --mail-user=erwanlecarpentier@mailbox.org
#SBATCH --mail-type=END

julia --threads 4 --project=/users/p21001/lecarpen/IICGP.jl test-multithread.jl

