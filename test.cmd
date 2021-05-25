#!/bin/bash
#SBATCH -J main-exp
#SBATCH -N 1
#SBATCH -n 2
#SBATCH --ntasks-per-node=2
#SBATCH --ntasks-per-core=1
#SBATCH -o test.out
#SBATCH -e test.log
#SBATCH --time=00:01:00
#SBATCH --mail-user=erwanlecarpentier@mailbox.org
#SBATCH --mail-type=END

julia
cd("/users/p21001/lecarpen/IICGP.jl")
import Pkg
Pkg.activate(".")
include("scripts/dualcgp.jl")
exit()
