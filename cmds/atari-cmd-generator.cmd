#!/bin/bash

# All games
# air_raid alien amidar assault asterix asteroids atlantis bank_heist battle_zone beam_rider berzerk bowling boxing breakout carnival centipede chopper_command crazy_climber defender demon_attack donkey_kong double_dunk elevator_action enduro fishing_derby freeway frogger frostbite galaxian gopher gravitar hero ice_hockey jamesbond journey_escape kaboom kangaroo keystone_kapers king_kong koolaid krull kung_fu_master laser_gates lost_luggage montezuma_revenge mr_do ms_pacman name_this_game pacman phoenix pitfall pong pooyan private_eye qbert riverraid robotank seaquest sir_lancelot skiing solaris space_invaders star_gunner surround tennis time_pilot trondead tutankham up_n_down venture video_pinball wizard_of_wor yars_revenge zaxxon

# Subset 9 representative games
# boxing centipede demon_attack enduro freeway kung_fu_master space_invaders riverraid pong

for GAME in boxing centipede demon_attack enduro freeway kung_fu_master space_invaders riverraid pong
do
	# sbatch atari-single.cmd $GAME
	echo "#!/bin/bash" > atari_$GAME.cmd
	echo "#SBATCH -J atari-$GAME" >> atari_$GAME.cmd
	echo "#SBATCH -N 1" >> atari_$GAME.cmd
	echo "#SBATCH -n 1" >> atari_$GAME.cmd
	echo "#SBATCH --ntasks-per-node=1" >> atari_$GAME.cmd
	echo "#SBATCH --ntasks-per-core=1" >> atari_$GAME.cmd
	echo "#SBATCH -o atari-$GAME.out" >> atari_$GAME.cmd
	echo "#SBATCH -e atari-$GAME.log" >> atari_$GAME.cmd
	echo "#SBATCH --time=96:00:00" >> atari_$GAME.cmd
	echo "#SBATCH --mail-user=erwanlecarpentier@mailbox.org" >> atari_$GAME.cmd
	echo "#SBATCH --mail-type=END" >> atari_$GAME.cmd
	echo "" >> atari_$GAME.cmd
	echo "julia --project=/users/p21001/lecarpen/IICGP.jl scripts/atari.jl --game=$GAME" >> atari_$GAME.cmd

	sbatch atari_$GAME.cmd

	rm atari_$GAME.cmd
done

wait
echo "All scripts launched"
