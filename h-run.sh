#!/usr/bin/env bash

cd `dirname $0`

if [ -f /usr/lib/x86_64-linux-gnu/libcurl-compat.so.3.0.0 ]; then
    echo "Exporting Libcurl"
    export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu
fi

[ -t 1 ] && . colors

. /hive-config/wallet.conf

. h-manifest.conf

SWARMDIR=${PWD##*/}
SWARMCONF="$PWD/$SWARMDIR.conf"

if [ ! -f $SWARMCONF ]
then
    touch $SWARMCONF
fi

#echo $CUSTOM_MINER
#echo $CUSTOM_LOG_BASENAME
#echo $CUSTOM_CONFIG_FILENAME

[[ -z $CUSTOM_CONFIG_FILENAME ]] && echo -e "${RED}No CUSTOM_CONFIG_FILENAME is set${NOCOLOR}" && exit 1
[[ ! -f $CUSTOM_CONFIG_FILENAME ]] && echo -e "${RED}Custom config ${YELLOW}$CUSTOM_CONFIG_FILENAME${RED} is not found${NOCOLOR}" && exit 1

logs-off

if ! [ -x "$(command -v pwsh)" ]; then
disk-expand
wget https://github.com/PowerShell/PowerShell/releases/download/v6.1.0/powershell-6.1.0-linux-x64.tar.gz -O /tmp/powershell.tar.gz --no-check-certificate
sudo mkdir -p /opt/microsoft/powershell/6.1.0
sudo tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/6.1.0
sudo chmod +x /opt/microsoft/powershell/6.1.0/pwsh
sudo ln -s /opt/microsoft/powershell/6.1.0/pwsh /usr/bin/pwsh
sudo rm -rf /tmp/powershell.tar.gz
fi

pwsh -command "&.\startup.ps1 $(< /hive/miners/custom/$CUSTOM_NAME/$CUSTOM_NAME.conf)" $@
