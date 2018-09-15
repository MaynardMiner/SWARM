#!/usr/bin/env bash

cd `dirname $0`

[ -t 1 ] && . colors

. /hive-config/wallet.conf

#[[ -z $CUSTOM_MINER ]] && echo -e "${RED}No CUSTOM_MINER is set${NOCOLOR}" && exit 1
#. /hive/custom/$CUSTOM_MINER/h-manifest.conf

. h-manifest.conf

#echo $CUSTOM_MINER
#echo $CUSTOM_LOG_BASENAME
#echo $CUSTOM_CONFIG_FILENAME

[[ -z $CUSTOM_CONFIG_FILENAME ]] && echo -e "${RED}No CUSTOM_CONFIG_FILENAME is set${NOCOLOR}" && exit 1
[[ ! -f $CUSTOM_CONFIG_FILENAME ]] && echo -e "${RED}Custom config ${YELLOW}$CUSTOM_CONFIG_FILENAME${RED} is not found${NOCOLOR}" && exit 1


if ! [ -x "$(command -v pwsh)" ]; then
sudo apt-get install p7zip-full
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
sudo curl -o /etc/apt/sources.list.d/microsoft.list https://packages.microsoft.com/config/ubuntu/16.04/prod.list
sudo apt-get update
sudo apt-get install -y powershell
apt-get -f install
fi

pwsh -command "&.\SWARM.ps1 $(< /hive/custom/$CUSTOM_NAME/$CUSTOM_NAME.conf)" $@ && . colors
