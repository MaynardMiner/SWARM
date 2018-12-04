#!/usr/bin/env bash

cd `dirname $0`

. /hive/miners/custom/$CUSTOM_MINER/h-manifest.conf

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


	local mydir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
	local mystats=$(< $mydir/build/bash/hivestats.sh)
	local myminer=$(< $mydir"/build/txt/miner.txt")
	local mindex=$2 #empty or 2, 3, 4, ...
	local Ntemp=$(get_nvidia_cards_temp)	# cards temp
	local Nfan=$(get_nvidia_cards_fan)	# cards fan
	local Atemp=$(get_amd_cards_temp)	# cards temp
	local Afan=$(get_amd_cards_fan)	# cards fan
	khs=0
	stats=
	case $myminer in

		GPU)
				cpkhs=(`echo "$mystats" | grep 'GPU=' | sed -e 's/.*=//' | tr -d '\r'`)
				cpfan=(`echo "$mystats" | grep 'FAN=' | sed -e 's/.*=//' | tr -d '\r'`)
				cptemp=(`echo "$mystats" | grep 'TEMP=' | sed -e 's/.*=//' | tr -d '\r'`)
				algo=`echo "$mystats" | grep -m1 'ALGO=' | sed -e 's/.*=//' | tr -d '\r'`
				local ac=`echo "$mystats" | grep -m1 'ACC=' | sed -e 's/.*=//' | tr -d '\r'`
				local rj=`echo "$mystats" | grep -m1 'REJ=' | sed -e 's/.*=//' | tr -d '\r'`
				uptime=`echo "$mystats" | grep -m1 'UPTIME=' | sed -e 's/.*=//' | tr -d '\r'`
				khs=`echo "$mystats" | grep -m1 'KHS=' | sed -e 's/.*=//' | tr -d '\r'`
				hs=`echo "$mystats" | grep -m1 'HSU=' | sed -e 's/.*=//' | tr -d '\r'`


			stats=$(jq -n \
				    --argjson hs "`echo "${cpkhs[@]}" | tr " " "\n" | jq -cs '.'`" \
					--arg hs_units "$hs" \
				    --argjson temp "`echo "${cptemp[@]}" | tr " " "\n" | jq -cs '.'`" \
				    --argjson fan "`echo "${cpfan[@]}" | tr " " "\n" | jq -cs '.'`"\
				     --arg uptime "$uptime", --arg algo "$algo" \
					--arg ac "$ac" --arg rj "$rj" \
					'{$hs, $hs_units, $temp, $fan, $uptime, ar: [$ac, $rj], $algo}')
			;;

esac
