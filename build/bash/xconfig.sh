#!/bin/bash

[[ `id -u` -eq 0 ]] && echo "Please run NOT as root" && exit

CONFIG_FILE="/root/config.txt"
source $CONFIG_FILE
#JSON=`cat /home/miner/config.json`

export DISPLAY=:0
export GPU_MAX_ALLOC_PERCENT=100
export GPU_USE_SYNC_OBJECTS=1
export GPU_SINGLE_ALLOC_PERCENT=100
export GPU_MAX_HEAP_SIZE=100
export GPU_FORCE_64BIT_PTR=1

# Logging
sudo chown miner:miner /var/tmp/screen.miner.* 1>/dev/null 2>/dev/null
sudo chmod 777         /var/tmp/screen.miner.* 1>/dev/null 2>/dev/null
screen -S miner -X logfile /var/tmp/screen.miner.log 1>/dev/null 2>/dev/null
screen -S miner -X logfile flush 1 1>/dev/null 2>/dev/null
screen -S miner -X log on 1>/dev/null 2>/dev/null

touch /var/tmp/update_status_fast
/root/utils/stats_periodic.sh &

# ocAdvTool
/root/utils/oc_advtools.sh

#OhGood
LABSOhGodAnETHlargementPill=`echo "$JSON" | jq -r .LABSOhGodAnETHlargementPill`
if [ "$LABSOhGodAnETHlargementPill" == "on" ]; then
  CZY=`ps ax | grep OhGodAnETHlargementPill | grep -v grep | wc -l`
  if [ "$CZY" == "0" ]; then
    gpu_count=`nvidia-smi -L | grep -i "1080\|titan" | wc -l`
    if [[ "$gpu_count" -ge 1 ]]; then
      echo -e $xNO$xGREEN"Running OhGodETHlagementPill..."$xNO
      screen -dm -S ohgod bash -c "sudo /root/utils/OhGodAnETHlargementPill" &
    fi
  fi
fi

# Overclocking
if [ $osSeries == "R" ]; then
  echo -e $xNO$xGREEN$xBOLD"Overclocking..."$xNO
  amdconfig --od-enable --adapter=all
  amdconfig --od-setclocks=$MINER_CORE,$MINER_MEMORY --adapter=all &
  /root/utils/atitweak/atitweak -p $MINER_POWERLIMIT --adapter=all &
fi
if [ $osSeries == "RX" ]; then
  echo -e $xNO$xGREEN$xBOLD"Overclocking..."$xNO
  sudo /root/utils/oc_dpm.sh "$MINER_CORE" "$MINER_MEMORY" "$MINER_OCVDDC"
fi
if [ $osSeries == "NV" ]; then
  export DISPLAY=:0
  echo -ne $xNO$xGREEN"Waiting for X server..."$xNO
  for i in `seq 1 12`; do
    ERR=`sudo nvidia-settings -L 2>&1 | grep "ERROR" | wc -l`
    [ "$ERR" == "0" ] && break
    echo -ne $xNO$xRED"Fail. Retrying..."$xNO
    sleep 10
  done
  echo
  sudo cp /.Xauthority /home/miner
  sudo chvt 1 &
  echo -e $xNO$xGREEN$xBOLD"Overclocking..."$xNO
  sudo /root/utils/oc_nv.sh $MINER_CORE $MINER_MEMORY $MINER_POWERLIMIT
fi

if [ $osSeries == "none" ]; then
  echo -e $xNO$xRED$xBOLD"ERROR: System doesnt see ANY GPUs in system."$xNO
  echo -e $xNO$xRED$xBOLD"Please check if you connected gpus, risers, power to risers."$xNO
  echo -e $xNO$xRED$xBOLD"Please also note that you cant mix AMD and NVIDIA in one rig - that will cause failure"$xNO
  echo -e $xNO$xRED$xBOLD"Here is what system see as GPUs list:"$xNO
  lspci | grep -i "VGA\|3D Contr"
fi

i=0
while true; do
  echo -e $xNO$xGREEN"Preparing miner workspace..."$xNO
  # save original variable in case of custom miner using
  MINER_OPTIONS_GO="$MINER_OPTIONS"
  # extract some variables
  MINER_DIR=`dirname $MINER_PATH`
  MINER_FILE=`basename $MINER_PATH`
  MINER_PKG_NAME=`basename $MINER_DIR`
  # a little bit different if custom miner
  echo -e $xNO$xGREEN$xBOLD"Starting Miner Program..."$xNO
  cd $MINER_DIR

  if [ $USER_EMAIL == "admin@simplemining.net" ]; then
    echo -e $xNO$xRED$xBOLD"Please set Your email address in config file and reboot rig to start mining."$xNO
    read
  elif [ $MINER_PATH != "null" ]; then
    sudo pwsh-preview -command "$MINER_PATH $MINER_OPTIONS_GO"
    sleep=$((10+i))
    [ $sleep -gt 60 ] && sleep=60
    echo -e $xNO$xRED$xBOLD"Miner ended or crashed. Restarting miner in $sleep seconds..."$xNO
    sleep $sleep
  else
    echo -e $xNO$xRED$xBOLD"Go to your Dasboard at simplemining.net and configure your Group Config."
    sleep 10
  fi
done
