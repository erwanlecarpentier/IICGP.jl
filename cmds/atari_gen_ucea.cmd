#!/bin/bash

# All games
# air_raid alien amidar assault asterix asteroids atlantis bank_heist battle_zone beam_rider berzerk bowling boxing breakout carnival centipede chopper_command crazy_climber defender demon_attack donkey_kong double_dunk elevator_action enduro fishing_derby freeway frogger frostbite galaxian gopher gravitar hero ice_hockey jamesbond journey_escape kaboom kangaroo keystone_kapers king_kong koolaid krull kung_fu_master laser_gates lost_luggage montezuma_revenge mr_do ms_pacman name_this_game pacman phoenix pitfall pong pooyan private_eye qbert riverraid robotank seaquest sir_lancelot skiing solaris space_invaders star_gunner surround tennis time_pilot trondead tutankham up_n_down venture video_pinball wizard_of_wor yars_revenge zaxxon

# Subset 9 representative games
# boxing centipede demon_attack enduro freeway kung_fu_master space_invaders riverraid pong

# Minatar benchmark
# seaquest breakout asterix freeway space_invaders

# 12 selected games (e.g. setting A)
# boxing assault
# freeway solaris
# defender gravitar
# space_invaders private_eye
# asteroids breakout
# frostbite riverraid

CMD_PREFIX="atari_"
CFGS=("cfg/eccgp_atari_ucea.yaml") # WARNING: sync with REDS
REDS=("ucea_") # WARNING: sync with CFGS
GAMES="solaris boxing space_invaders"
SCRIPT="scripts/atari_ucea.jl"
PROJECT="$PWD"
USERNAME=$(whoami)
OUTDIR="/tmpdir/$USERNAME/ICGP-results/results"
N_THREADS="5" # WARNING: sync with MEM
# MEM="192000" # WARNING: sync with N_THREADS
# echo "#SBATCH --mem=$MEM" >> $CM # add if MEM is set

for i in "${!CFGS[@]}"; do
	for GAME in $GAMES; do
		FNAME=$CMD_PREFIX${REDS[i]}$GAME
		CM=$FNAME.cmd
		OU=$FNAME.out
		LO=$FNAME.log
		echo "#!/bin/bash" > $CM
		echo "#SBATCH -J $FNAME" >> $CM
		echo "#SBATCH -N 1" >> $CM
		echo "#SBATCH -n $N_THREADS" >> $CM
		echo "#SBATCH --ntasks-per-node=$N_THREADS" >> $CM
		echo "#SBATCH --ntasks-per-core=1" >> $CM
		echo "#SBATCH -o /tmpdir/%u/logs/job%J_$FNAME.out" >> $CM
		echo "#SBATCH -e /tmpdir/%u/logs/job%J_$FNAME.log" >> $CM
		echo "#SBATCH --time=3-00:00:00" >> $CM
		echo "#SBATCH --mail-user=erwanlecarpentier@mailbox.org" >> $CM
		echo "#SBATCH --mail-type=END" >> $CM
		echo "" >> $CM
		echo "julia --threads $N_THREADS --project=$PROJECT $SCRIPT --cfg=${CFGS[i]} --game=$GAME --out=$OUTDIR" >> $CM

		RES=$(sbatch $CM) # --parsable
		JOBID=${RES##* }
		echo $RES
		mv $CM /tmpdir/$USERNAME/logs/job$(echo $JOBID)_$FNAME.cmd
		sleep 0.01
	done
done

wait
echo "All scripts launched"
