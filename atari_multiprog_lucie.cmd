#!/bin/bash
#SBATCH -J lucie-atari
#SBATCH -N 1
#SBATCH -n 18
#SBATCH --cpus-per-task=2
#SBATCH -o /tmpdir/%u/logs/job%J_atari_lucie.out
#SBATCH -e /tmpdir/%u/logs/job%J_atari_lucie.log
#SBATCH --time=00:10:00
#SBATCH --mail-user=erwanlecarpentier@mailbox.org

# SBATCH --ntasks-per-node=36
# SBATCH --ntasks-per-core=1
# SBATCH --threads-per-core=1

# export OMP_NUM_THREADS=2

USERNAME=$(whoami)
OUTDIR="/tmpdir/$USERNAME/ICGP-results/results"
CFG="cfg/eccgp_atari_lucie.yaml"
GAMES="solaris boxing space_invaders gravitar freeway asteroids"
SCRIPT="$(pwd)/scripts/atari_lucie.jl"
PROJECT="$PWD"
NINSTANCES=3

cd ~/IICGP.jl/

echo running programs
echo $SCRIPT

srun --multi-prog atari_multiprog_lucie.config
