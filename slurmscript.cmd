#!/bin/bash
#SBATCH -J main-exp
#SBATCH -N 1
#SBATCH -n 36
#SBATCH --ntasks-per-node=36
#SBATCH --ntasks-per-core=1
#SBATCH -o main.out
#SBATCH -e main.log
#SBATCH --time=24:00:00
#SBATCH --mail-user=erwanlecarpentier@mailbox.org
#SBATCH --mail-type=END

source venv/bin/activate
python main.py
deactivate

