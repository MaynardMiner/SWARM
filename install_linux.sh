#!/bin/bash

# ************installer for linux**************************************************
#
#
# This will attempt to install libs for certain miners that may be required.
# This will also install the commands swarm uses to /usr/bin, so they can be
# called upon at any time from any terminal.
#
# HiveOS does this automatically. If this fails to install commands -
# They are very simple actions that can be done manually by reviewing
# install.ps1. 
# I tried to keep linux expressions in ./build/powershell/scripts/install.ps1 
# in case they need to be done manually rather than using powershell code.

if ! [ -x "$(command -v pwsh)" ]; then
echo 'pwsh not found- installing 6.2.3'
wget https://github.com/PowerShell/PowerShell/releases/download/v6.2.3/powershell-6.2.3-linux-x64.tar.gz -O /tmp/powershell.tar.gz --no-check-certificate
mkdir -p /opt/microsoft/powershell/6.2.3
tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/6.2.3
chmod +x /opt/microsoft/powershell/6.2.3/pwsh
ln -s /opt/microsoft/powershell/6.2.3/pwsh /usr/bin/pwsh
rm -rf /tmp/powershell.tar.gz
fi
chmod 777 -R $HOME/.local/share/powershell
echo 'starting install script'
pwsh -command "./build/powershell/scripts/install.ps1"
