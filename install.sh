#!/bin/bash
if ! [ -x "$(command -v pwsh)" ]; then
wget https://github.com/PowerShell/PowerShell/releases/download/v6.1.0/powershell-6.1.0-linux-x64.tar.gz -O /tmp/powershell.tar.gz
sudo mkdir -p /opt/microsoft/powershell/6.1.0
sudo tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/6.1.0
sudo chmod +x /opt/microsoft/powershell/6.1.0/pwsh
sudo ln -s /opt/microsoft/powershell/6.1.0/pwsh /usr/bin/pwsh
sudo rm -rf /tmp/powershell.tar.gz
fi
sudo pwsh -command "./install.ps1"
sudo chmod 777 -R $HOME/.local/share/powershell
