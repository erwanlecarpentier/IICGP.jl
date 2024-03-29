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

cd ~/IICGP.jl/

USERNAME=$(whoami)
OUTDIR="/tmpdir/$USERNAME/ICGP-results/results"
CFG="cfg/eccgp_atari_lucie.yaml"
GAMES="solaris boxing space_invaders gravitar freeway asteroids"
SCRIPT="scripts/atari_lucie.jl"
PROJECT="$PWD"
NINSTANCES=3

for GAME in $GAMES; do
	for i in $(seq 1 $NINSTANCES); do
		echo running game $GAME instance $i
		srun -N 1 -n 2 julia --threads 2 --project=$PROJECT $SCRIPT --cfg=$CFG --game=$GAME --out=$OUTDIR &
		sleep 0.1
	done
done
wait
