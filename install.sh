#!/bin/bash
if ! [ -x "$(command -v pwsh)" ]; then
wget https://github.com/PowerShell/PowerShell/releases/download/v6.2.3/powershell-6.2.3-linux-x64.tar.gz -O /tmp/powershell.tar.gz --no-check-certificate
mkdir -p /opt/microsoft/powershell/6.2.3
tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/6.2.3
chmod +x /opt/microsoft/powershell/6.2.3/pwsh
ln -s /opt/microsoft/powershell/6.2.3/pwsh /usr/bin/pwsh
rm -rf /tmp/powershell.tar.gz
fi
chmod 777 -R $HOME/.local/share/powershell
pwsh -command "./install.ps1"
