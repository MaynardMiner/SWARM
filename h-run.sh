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
wget https://github.com/PowerShell/PowerShell/releases/download/v6.2.3/powershell-6.2.3-linux-x64.tar.gz -O /tmp/powershell.tar.gz --no-check-certificate
mkdir -p /opt/microsoft/powershell/6.2.3
tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/6.2.3
chmod +x /opt/microsoft/powershell/6.2.3/pwsh
ln -s /opt/microsoft/powershell/6.2.3/pwsh /usr/bin/pwsh
rm -rf /tmp/powershell.tar.gz
fi

PVERSION=`pwsh -version`

if [ "$PVERSION" != "PowerShell 6.2.3" ]; then
echo "updating powershell to latest version"
rm -rf /opt/microsoft/powershell/6.2.1
rm -rf /usr/bin/pwsh
wget https://github.com/PowerShell/PowerShell/releases/download/v6.2.3/powershell-6.2.3-linux-x64.tar.gz -O /tmp/powershell.tar.gz --no-check-certificate
mkdir -p /opt/microsoft/powershell/6.2.3
tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/6.2.3
chmod +x /opt/microsoft/powershell/6.2.3/pwsh
ln -s /opt/microsoft/powershell/6.2.3/pwsh /usr/bin/pwsh
rm -rf /tmp/powershell.tar.gz
fi

json=`echo cat $SWARMCONF`
$json | jq -e . >/dev/null 2>&1
get=$?

if [ "$get" -eq 0 ]; then
  $json > $PWD/config.json;
  pwsh -command "& .\startup.ps1";
  else
  pwsh -command "&.\startup.ps1 $(< /hive/miners/custom/$CUSTOM_NAME/$CUSTOM_NAME.conf)" $@;
fi
