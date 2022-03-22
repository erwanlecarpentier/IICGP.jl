#!/bin/bash
#SBATCH -J doubleenco
#SBATCH -N 1
#SBATCH -n 1
# SBATCH -o /tmpdir/%u/logs/job.%j.atarilucie.out
# SBATCH -e /tmpdir/%u/logs/job.%j.atarilucie.log
#SBATCH --time=1-00:00:00
# SBATCH --mail-user=erwanlecarpentier@mailbox.org

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

source pyvenv/bin/activate

python pytexgraph.py /home/wahara/Documents/git/ICGP-results/results/2022-02-23T18:11:39.288_1_bowling
