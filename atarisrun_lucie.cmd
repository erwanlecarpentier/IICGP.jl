#!/bin/bash
#SBATCH -J lucie
#SBATCH -N 1
#SBATCH -n 36
#SBATCH --ntasks-per-node=36
#SBATCH --ntasks-per-core=1
#SBATCH --threads-per-core=1
#SBATCH -o /tmpdir/%u/logs/job%J_atari_lucie.out
#SBATCH -e /tmpdir/%u/logs/job%J_atari_lucie.log
#SBATCH --mem=192000
#SBATCH --time=00:00:10
#SBATCH --mail-user=erwanlecarpentier@mailbox.org

cd ~/IICGP.jl/

USERNAME=$(whoami)
OUTDIR="/tmpdir/$USERNAME/ICGP-results/results"
CFG="cfg/eccgp_atari_lucie.yaml"
GAMES="solaris boxing space_invaders"
SCRIPT="scripts/atari_lucie.jl"
PROJECT="$PWD"


for GAME in $GAMES; do
	echo srun -N 1 -n 2 julia --threads 2 --project=$PROJECT $SCRIPT --cfg=$CFG --game=$GAME --out=$OUTDIR
	sleep 0.1
done
wait