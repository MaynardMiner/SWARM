#!/bin/bash
if ! [ -x "$(command -v pwsh)" ]; then
sudo apt-get install p7zip-full
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
sudo curl -o /etc/apt/sources.list.d/microsoft.list https://packages.microsoft.com/config/ubuntu/16.04/prod.list
sudo apt-get update
sudo apt-get install -y powershell
fi
sudo pwsh -command "./Install.ps1"
