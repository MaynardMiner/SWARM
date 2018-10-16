#!/usr/bin/env bash
                                

get_nvidia_cards_temp(){
	echo $(jq -c "[.temp$nvidia_indexes_array]" <<< $gpu_stats)
}

get_nvidia_cards_fan(){
	echo $(jq -c "[.fan$nvidia_indexes_array]" <<< $gpu_stats)
}

get_amd_cards_temp(){
	echo $(jq -c "[.temp$amd_indexes_array]" <<< $gpu_stats)
}

get_amd_cards_fan(){
	echo $(jq -c "[.fan$amd_indexes_array]" <<< $gpu_stats)
}

function miner_stats {
	local mydir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
	local mystats=$(< $mydir/build/bash/hivestats.sh)
	local miner=$(< $mydir"/build/txt/miner.txt")
	local mindex=$2 #empty or 2, 3, 4, ...
	local Ntemp=$(get_nvidia_cards_temp)	# cards temp
	local Nfan=$(get_nvidia_cards_fan)	# cards fan
	local Atemp=$(get_amd_cards_temp)	# cards temp
	local Afan=$(get_amd_cards_fan)	# cards fan
	khs=0
	stats=
	case $miner in

		GPU)
				cpkhs=(`echo "$mystats" | grep 'GPU=' | sed -e 's/.*=//'`)
				cpfan=(`echo "$mystats" | grep 'FAN=' | sed -e 's/.*=//'`)
				cptemp=(`echo "$mystats" | grep 'TEMP=' | sed -e 's/.*=//'`)
				algo=`echo "$mystats" | grep -m1 'ALGO=' | sed -e 's/.*=//'`
				local ac=`echo "$mystats" | grep -m1 'ACC=' | sed -e 's/.*=//'`
				local rj=`echo "$mystats" | grep -m1 'REJ=' | sed -e 's/.*=//'`
				uptime=`echo "$mystats" | grep -m1 'UPTIME=' | sed -e 's/.*=//'`
				khs=`echo "$mystats" | grep -m1 'KHS=' | sed -e 's/.*=//'`
				hs=`echo "$mystats" | grep -m1 'HS=' | sed -e 's/.*=//'`


			stats=$(jq -n \
				    --argjson hs "`echo ${cpkhs[@]} | tr " " "\n" | jq -cs '.'`" \
					--arg hs_units $hs \
				    --argjson temp "`echo ${cptemp[@]} | tr " " "\n" | jq -cs '.'`" \
				    --argjson fan "`echo ${cpfan[@]} | tr " " "\n" | jq -cs '.'`"\
				     --arg uptime "$uptime", --arg algo "$algo" \
					--arg ac "$ac" --arg rj "$rj" \
					'{$hs, $hs_units, $temp, $fan, $uptime, ar: [$ac, $rj], $algo}')
			;;
		*)
			miner="unknown"
			#MINER=miner
			eval "MINER${mindex}=unknown"
		;;
	esac


	[[ -z $khs ]] && khs=0
	[[ -z $stats ]] && stats="null"


#	[[ ! -z $mindex ]] &&
#		eval "khs${mindex}"
}
