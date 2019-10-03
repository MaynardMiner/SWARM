<#
SWARM is open-source software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
SWARM is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>

[cultureinfo]::CurrentCulture = 'en-US'
$AllProtocols = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12' 
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
$dir = (Split-Path (Split-Path (Split-Path (Split-Path $script:MyInvocation.MyCommand.Path))))
$dir = $dir -replace "/var/tmp", "/root"
Set-Location $dir

$Keys = Get-Content ".\config\parameters\Hive_params_keys.json" | ConvertFrom-Json
$API = $(Get-Content ".\config\parameters\newarguments.json" | ConvertFrom-Json).API_Key
$Url = "https://api2.hiveos.farm/api/v2/farms/$($Keys.FarmID)/workers"

if("-windows" -in $args){$Windows = $True}
if("-linux" -in $args){$Linux = $True}

$args = $args | Where {$_ -ne "-windows"}
$args = $args | Where {$_ -ne "-linux"}
Write-Host "Command is $([string]$args)"

Write-Host "Getting Workers Running SWARM"
$T = @{Authorization = "Bearer $API" }
$Splat = @{ Method = "GET"; Uri = $Url; Headers = $T; ContentType = 'application/json'; }
try { $A = Invoke-RestMethod @Splat -TimeoutSec 10 -ErrorAction Stop } catch { Write-Host "WARNING: Failed to Contact HiveOS for Worker List" -ForegroundColor Yellow; return }

$Workers = $A.data
$SWARM_Workers = $Workers | Where {$_.flight_sheet.items.miner_alt -like "*SWARM*"}

if($Windows){$SWARM_Workers = $SWARM_Workers | Where {$_.flight_sheet.items.miner_alt -like "*windows*"}}
if($Linux){$SWARM_Workers = $SWARM_Workers | Where {$_.flight_sheet.items.miner_alt -like "*linux*"}}

$SWARM_Workers = $SWARM_Workers.id

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