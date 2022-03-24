#!/bin/bash
#SBATCH -J doubleenco
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --time=00:10:00
# SBATCH -o /tmpdir/%u/logs/job.%j.atarilucie.out
# SBATCH -e /tmpdir/%u/logs/job.%j.atarilucie.log
# SBATCH --mail-user=erwanlecarpentier@mailbox.org

# export OMP_NUM_THREADS=2

# USERNAME=$(whoami)
# OUTDIR="/tmpdir/$USERNAME/ICGP-results/results"
# CFG="cfg/eccgp_atari_lucie.yaml"
# GAMES="solaris boxing space_invaders gravitar freeway asteroids"
SCRIPT="$(pwd)/scripts/atari_lucie.jl"
# PROJECT="$PWD"
# NINSTANCES=3

cd ~/IICGP.jl/

# module add $HOME/IICGP.jl/pyvenv/bin/python3.8
# module add Python/3.8.5
# source $HOME/IICGP.jl/pyvenv/bin/activate
source $HOME/venvs/py3.6/bin/activate

python --version

which python

#python pytexgraph.py /tmpdir/p21049le/ICGP-results/results/2022-02-23T18:11:39.288_1_bowling

#deactivate
