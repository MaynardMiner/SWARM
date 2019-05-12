#!/usr/bin/env bash

cd `dirname $0`

. /hive/miners/custom/$CUSTOM_MINER/h-manifest.conf

	local mydir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
	local myminer=$(< $mydir"/build/txt/miner.txt")
	local mindex=$2 #empty or 2, 3, 4, ...
	khs=0
	stats=
	case $myminer in
		GPU)
			stats_raw=`echo "stats" | nc -w 2 localhost 6099`
			ac=$(jq '[.accepted]' <<< "$stats_raw")
			rj=$(jq '[.rejected]' <<< "$stats_raw")
			uptime=$(jq '.uptime' <<< "$stats_raw")
			gpus=$(jq -c '.gpus' <<< "$stats_raw")
			fans=$(jq -c '.fans' <<< "$stats_raw")
			temp=$(jq -c '.temps' <<< "$stats_raw")
			hsu=$(jq '.hsu' <<< "$stats_raw")
			algo=$(jq '.algo' <<< "$stats_raw")
			khs=$(jq '.gpu_total' <<< "$stats_raw")

		stats=$(jq -n \
					  --arg uptime "$uptime" \
					  --arg ac "$ac" \
					  --arg rj "$rj" \
					  --arg hs_units "$hsu" \
					  --arg algo "$algo" \
					  '{ hs: .gpus, temp: .temps, fan: .fans, $uptime, ar: [$ac, $rj], $hs_units}' <<< "$stats_raw")
			;;
		CPU)
				cpkhs=(`echo "$mystats" | grep 'CPUKHS=' | sed -e 's/.*=//' | tr -d '\r'`)
				algo=`echo "$mystats" | grep -m1 'HIVEALGO=' | sed -e 's/.*=//' | tr -d '\r'`
				local ac=`echo "$mystats" | grep -m1 'ACC=' | sed -e 's/.*=//' | tr -d '\r'`
				local rj=`echo "$mystats" | grep -m1 'REJ=' | sed -e 's/.*=//' | tr -d '\r'`
				uptime=`echo "$mystats" | grep -m1 'UPTIME=' | sed -e 's/.*=//' | tr -d '\r'`
				khs=`echo "$mystats" | grep -m1 'CPU_TOTAL_KHS=' | sed -e 's/.*=//' | tr -d '\r'`
				hs=`echo "$mystats" | grep -m1 'HSU=' | sed -e 's/.*=//' | tr -d '\r'`


			stats=$(jq -n \
				    --argjson hs "`echo "${cpkhs[@]}" | tr " " "\n" | jq -cs '.'`" \
					--arg hs_units "$hs" \
				     --arg uptime "$uptime", --arg algo "$algo" \
					--arg ac "$ac" --arg rj "$rj" \
					'{$hs, $hs_units, $temp, $fan, $uptime, ar: [$ac, $rj], $algo}')
			;;

esac
