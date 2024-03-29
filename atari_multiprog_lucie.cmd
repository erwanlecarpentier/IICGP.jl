#!/bin/bash
#SBATCH -J doubleenco
#SBATCH -N 1
#SBATCH -n 18
#SBATCH --cpus-per-task=2
# SBATCH -o /tmpdir/%u/logs/job.%j.atarilucie.out
# SBATCH -e /tmpdir/%u/logs/job.%j.atarilucie.log
#SBATCH --time=9-00:00:00
# SBATCH --mail-user=erwanlecarpentier@mailbox.org

# SBATCH --ntasks-per-node=36
# SBATCH --ntasks-per-core=1
# SBATCH --threads-per-core=1

echo start
export OMP_NUM_THREADS=2

# USERNAME=$(whoami)
# OUTDIR="/tmpdir/$USERNAME/ICGP-results/results"
# CFG="cfg/eccgp_atari_lucie.yaml"
# GAMES="solaris boxing space_invaders gravitar freeway asteroids"
SCRIPT="$(pwd)/scripts/atari_lucie.jl"
# PROJECT="$PWD"
# NINSTANCES=3

cd ~/IICGP.jl/

echo running programs
echo $SCRIPT

srun --multi-prog atari_multiprog_lucie_romset_2.config
