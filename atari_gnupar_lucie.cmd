#!/bin/sh
#SBATCH -J lucie-atari
#SBATCH -N 1
#SBATCH --ntasks=36
#SBATCH --time=00:10:00
#SBATCH -o /tmpdir/%u/logs/job%J_atari_lucie.out
#SBATCH -e /tmpdir/%u/logs/job%J_atari_lucie.log
#SBATCH --mail-user=erwanlecarpentier@mailbox.org
# SBATCH --mem-per-cpu=2G  # NOTE DO NOT USE THE --mem= OPTION 
# SBATCH --partition=broadwl

cd ~/IICGP.jl/

USERNAME=$(whoami)
OUTDIR="/tmpdir/$USERNAME/ICGP-results/results"
CFG="cfg/eccgp_atari_lucie.yaml"
GAMES="solaris boxing space_invaders gravitar freeway asteroids"
SCRIPT="scripts/atari_lucie.jl"
PROJECT="$PWD"
NINSTANCES=3

# Load the default version of GNU parallel.
module load parallel

# When running a large number of tasks simultaneously, it may be
# necessary to increase the user process limit.
# ulimit -u 10000

# This specifies the options used to run srun. The "-N1 -n1" options are
# used to allocates a single core to each task.
mysrun="srun --exclusive -N1 -n2"

# This specifies the options used to run GNU parallel:
#
#   --delay of 0.2 prevents overloading the controlling node.
#
#   -j is the number of tasks run simultaneously.
#
#   The combination of --joblog and --resume create a task log that
#   can be used to monitor progress.
#
myparallel="parallel --delay 0.1 -j $SLURM_NTASKS --joblog runtask.log --resume"

# Run a script, runtask.sh, using GNU parallel and srun. Parallel
# will run the runtask script for the numbers 1 through 128. To
# illustrate, the first job will run like this:
#
#   srun --exclusive -N1 -n1 ./runtask.sh arg1:1 > runtask.1
#
echo launching scripts
for GAME in $GAMES; do
	echo $GAME
	$myparallel "$mysrun julia --threads 2 --project=$PROJECT $SCRIPT --cfg=$CFG --game=$GAME --out=$OUTDIR &" ::: {1..$NINSTANCES}
done
