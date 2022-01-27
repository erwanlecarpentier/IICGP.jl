#!/bin/bash
#SBATCH -J lucie-atari
#SBATCH -N 1
#SBATCH -n 36
#SBATCH --ntasks-per-node=36
#SBATCH --ntasks-per-core=1
#SBATCH --threads-per-core=1
#SBATCH -o /tmpdir/%u/logs/job%J_atari_lucie.out
#SBATCH -e /tmpdir/%u/logs/job%J_atari_lucie.log
#SBATCH --time=01:00:00
#SBATCH --mail-user=erwanlecarpentier@mailbox.org

USERNAME=$(whoami)
OUTDIR="/tmpdir/$USERNAME/ICGP-results/results"
CFG="cfg/eccgp_atari_lucie.yaml"
GAMES="solaris boxing space_invaders gravitar freeway asteroids"
SCRIPT="scripts/atari_lucie.jl"
PROJECT="$PWD"
NINSTANCES=3

cd ~/IICGP.jl/

srun --multi-prog test.config
