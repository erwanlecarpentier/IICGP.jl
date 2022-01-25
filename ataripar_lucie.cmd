#!/bin/bash
#SBATCH -J lucie
#SBATCH -N 1
#SBATCH -n 36
#SBATCH --ntasks-per-node=36
#SBATCH --ntasks-per-core=1
#SBATCH --threads-per-core=1
#SBATCH -o /tmpdir/%u/logs/slurm.%N.%j.out # STDOUT
#SBATCH -e /tmpdir/%u/logs/slurm.%N.%j.err # STDERR
#SBATCH --mem=192000
#SBATCH --time=00:00:10
#SBATCH --mail-user=erwanlecarpentier@mailbox.org

cd ~/IICGP.jl/

USERNAME=$(whoami)
OUTDIR="/tmpdir/$USERNAME/ICGP-results/results"
CFG="cfg/eccgp_atari_lucie.yaml"
GAMES="solaris boxing space_invaders gravitar freeway asteroids"
SCRIPT="scripts/atari_lucie.jl"
PROJECT="$PWD"
NINSTANCES=3

srun -N 1 -n 2 julia --threads 2 --project=$PROJECT $SCRIPT --cfg=$CFG --game=boxing --out=$OUTDIR &
sleep 0.1
srun -N 1 -n 2 julia --threads 2 --project=$PROJECT $SCRIPT --cfg=$CFG --game=boxing --out=$OUTDIR &
sleep 0.1
srun -N 1 -n 2 julia --threads 2 --project=$PROJECT $SCRIPT --cfg=$CFG --game=boxing --out=$OUTDIR &
sleep 0.1

wait
