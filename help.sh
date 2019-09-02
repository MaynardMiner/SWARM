#!/bin/bash
if ! [ -x "$(command -v pwsh)" ]; then
wget https://github.com/PowerShell/PowerShell/releases/download/v6.1.0/powershell-6.1.0-linux-x64.tar.gz -O /tmp/powershell.tar.gz
mkdir -p /opt/microsoft/powershell/6.1.0
tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/6.1.0
chmod +x /opt/microsoft/powershell/6.1.0/pwsh
ln -s /opt/microsoft/powershell/6.1.0/pwsh /usr/bin/pwsh
rm -rf /tmp/powershell.tar.gz
fi
pwsh -command "./install.ps1"
chmod 777 -R $HOME/.local/share/powershell
pwsh -command "./build/powershell/scripts/help.ps1"