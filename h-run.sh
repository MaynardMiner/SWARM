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
disk-expand
wget https://github.com/PowerShell/PowerShell/releases/download/v6.1.0/powershell-6.1.0-linux-x64.tar.gz -O /tmp/powershell.tar.gz
sudo mkdir -p /opt/microsoft/powershell/6.1.0
sudo tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/6.1.0
sudo chmod +x /opt/microsoft/powershell/6.1.0/pwsh
sudo ln -s /opt/microsoft/powershell/6.1.0/pwsh /usr/bin/pwsh
sudo rm -rf /tmp/powershell.tar.gz
fi

pwsh -command "&.\SWARM.ps1 $(< /hive/custom/$CUSTOM_NAME/$CUSTOM_NAME.conf)" $@ && . color
