#!/usr/bin/env bash

cd `dirname $0`

. /hive/miners/custom/$CUSTOM_MINER/h-manifest.conf

	mindex=$2 #empty or 2, 3, 4, ...
	khs=0
		  port=`cat /hive/miners/custom/$CUSTOM_MINER/debug/port.txt`
		  stats_raw=`echo "stats" | nc -w 2 localhost $port`
		  if [[ $? -ne 0  || -z $stats_raw ]]; then
		  	echo -e "${YELLOW}Failed to read SWARM stats from localhost:$port${NOCOLOR}"
		  else
		  	ac=$(jq -c -r '.accepted' <<< "$stats_raw" | tr -d '"')
			rj=$(jq -c -r '.rejected' <<< "$stats_raw" | tr -d '"')
			uptime=$(jq -r '.uptime' <<< "$stats_raw" | tr -d '"')
			gpus=$(jq -r '.gpus' <<< "$stats_raw" | tr -d '"')
			fans=$(jq -r '.fans' <<< "$stats_raw" | tr -d '"')
			temps=$(jq -r '.temps' <<< "$stats_raw" | tr -d '"')
			hsu=$(jq -r '.hsu' <<< "$stats_raw")
			algo=$(jq -r '.algo' <<< "$stats_raw")
			khs=$(jq -r '.gpu_total_khs' <<< "$stats_raw")
			bus_numbers=$(jq -r '.bus_numbers' <<< "$stats_raw" | tr -d '"')

			stats=$(jq -n \
					  --argjson hs "`echo "${gpus[@]}" | jq -c .`" \
					  --argjson fan "`echo "${fans[@]}" | jq -c .`" \
					  --argjson temp "`echo "${temps[@]}" | jq -c .`" \
					  --arg uptime "$uptime" \
					  --arg ac "$ac" \
					  --arg rj "$rj" \
					  --arg hs_units "$hsu" \
					  --arg algo "$algo" \
					  --argjson bus_numbers "`echo "${bus_numbers[@]}" | jq -c .`" \
					  '{$hs, $hs_units, $temp, $fan, $uptime, ar: [$ac, $rj], $bus_numbers, $algo}')
		  fi