
$File = "/home/miner/config.json"
$json = Get-Content $File | ConvertFrom-Json
$json.minerPath = "/root/miner/SWARM/startup.ps1"

$Json | ConvertTo-Json -Compress | Set-Content test.txt
