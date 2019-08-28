[cultureinfo]::CurrentCulture = 'en-US'
$AllProtocols = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12' 
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
$dir = (Split-Path (Split-Path (Split-Path (Split-Path $script:MyInvocation.MyCommand.Path))))
$dir = $dir -replace "/var/tmp", "/root"
Set-Location $dir

$Keys = Get-Content ".\build\txt\hive_params_keys.txt" | ConvertFrom-Json
$API = $(Get-Content ".\config\parameters\newarguments.json" | ConvertFrom-Json).API_Key
$Url = "https://api2.hiveos.farm/api/v2/farms/$($Keys.FarmID)/workers"

Write-Host "Command is $([string]$args)"

Write-Host "Getting Workers Running SWARM"
$T = @{Authorization = "Bearer $API" }
$Splat = @{ Method = "GET"; Uri = $Url; Headers = $T; ContentType = 'application/json'; }
try { $A = Invoke-RestMethod @Splat -TimeoutSec 10 -ErrorAction Stop } catch { Write-Host "WARNING: Failed to Contact HiveOS for Worker List" -ForegroundColor Yellow; return }

$Workers = $A.data
$SWARM_Workers = $($Workers | Where {$_.flight_sheet.items.miner_alt -like "*SWARM*"}).id

$command = @{ 
    worker_ids = @($SWARM_Workers); 
    data = @{ 
        command = "exec";
        data = @{"cmd" = [string]$args;}
    };
}

$command = $command | ConvertTo-Json -Depth 10 -Compress
$command
$T = @{Authorization = "Bearer $API" }
$Url = "https://api2.hiveos.farm/api/v2/farms/$($Keys.FarmID)/workers/command"
$Splat = @{ Method = "Post"; Uri = $Url; Headers = $T; ContentType = 'application/json'; }
try { $B = Invoke-RestMethod @Splat -Body $Command -TimeoutSec 10 -ErrorAction Stop }
catch [Exception]
{
    Write-Host "Exception: "$_.Exception.Message -ForegroundColor Red;
}


if($B) { Write-Host "Sent all commands to workers running SWARM" }