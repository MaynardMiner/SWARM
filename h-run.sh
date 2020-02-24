#!/usr/bin/env bash

cd `dirname $0`

[ -t 1 ] && . colors

. /hive-config/wallet.conf

. h-manifest.conf

SWARMDIR=${PWD##*/}
SWARMCONF="$PWD/$SWARMDIR.conf"

## Make a config dir to the lastest version.
if [ ! -f $SWARMCONF ]
then
    touch $SWARMCONF
fi

#echo $CUSTOM_MINER
#echo $CUSTOM_LOG_BASENAME
#echo $CUSTOM_CONFIG_FILENAME

[[ -z $CUSTOM_CONFIG_FILENAME ]] && echo -e "${RED}No CUSTOM_CONFIG_FILENAME is set${NOCOLOR}" && exit 1
[[ ! -f $CUSTOM_CONFIG_FILENAME ]] && echo -e "${RED}Custom config ${YELLOW}$CUSTOM_CONFIG_FILENAME${RED} is not found${NOCOLOR}" && exit 1

## SWARM does its own logging
logs-off

## If pwsh-preview is not installed.
if ! [ -x "$(command -v pwsh-preview)" ]; then
disk-expand
wget https://github.com/PowerShell/PowerShell/releases/download/v7.0.0-rc.3/powershell-7.0.0-rc.3-linux-x64.tar.gz -O /tmp/powershell.tar.gz --no-check-certificate
mkdir -p /opt/microsoft/powershell/7.0.0-rc.3
tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7.0.0-rc.3
chmod +x /opt/microsoft/powershell/7.0.0-rc.3/pwsh-preview
ln -s /opt/microsoft/powershell/7.0.0-rc.3/pwsh-preview /usr/bin/pwsh-preview
rm -rf /tmp/powershell.tar.gz
fi

PVERSION=`pwsh-preview -version`

## If pwsh-preview is wrong version, install it again.
if [ "$PVERSION" != "PowerShell 7.0.0-rc.3" ]; then
echo "updating powershell to latest version"
rm -rf /opt/microsoft/powershell/
rm -rf /usr/bin/pwsh
wget https://github.com/PowerShell/PowerShell/releases/download/v7.0.0-rc.3/powershell-7.0.0-rc.3-linux-x64.tar.gz -O /tmp/powershell.tar.gz --no-check-certificate
mkdir -p /opt/microsoft/powershell/7.0.0-rc.3
tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7.0.0-rc.3
chmod +x /opt/microsoft/powershell/7.0.0-rc.3/pwsh-preview
ln -s /opt/microsoft/powershell/7.0.0-rc.3/pwsh-preview /usr/bin/pwsh-preview
rm -rf /tmp/powershell.tar.gz
fi

## remove old config.json
SWARM_CONFIG_FILE=config.json
if [ -f "$SWARM_CONFIG_FILE" ]; then
    rm -f $SWARM_CONFIG_FILE
fi

## Check to see if user sent a config as a json format rather than arguments
json=`echo cat $SWARMCONF`
$json | jq -e . >/dev/null 2>&1
get=$?

if [ "$get" -eq 0 ]; then
  ## Set json to config.json
  $json > $PWD/config.json;
  ## Start SWARM with no arguments
  pwsh-preview -command "& .\startup.ps1";
  else
  ## Feed arguments to SWARM
  pwsh-preview -command "&.\startup.ps1 $(< /hive/miners/custom/$CUSTOM_NAME/$CUSTOM_NAME.conf)" $@;
fi
