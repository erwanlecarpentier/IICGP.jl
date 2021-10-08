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
CFGS=("cfg/dualcgpga_atari_pooling.yaml") # WARNING: sync with REDS
REDS=("ga_pool_") # WARNING: sync with CFGS
GAMES="gravitar boxing"
SCRIPT="scripts/atari_dualcgp_ga.jl"
PROJECT="$PWD"
USERNAME=$(whoami)
OUTDIR="/tmpdir/$USERNAME/ICGP-results"
N_THREADS="36"

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
		echo "#SBATCH --time=7-00:00:00" >> $CM
		echo "#SBATCH --mail-user=erwanlecarpentier@mailbox.org" >> $CM
		echo "#SBATCH --mail-type=END" >> $CM
		echo "" >> $CM
		echo "julia --threads $N_THREADS --project=$PROJECT $SCRIPT --cfg=${CFGS[i]} --game=$GAME --out=$OUTDIR" >> $CM

		sbatch $CM
		rm $CM
	done
done

wait
echo "All scripts launched"
