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

function Global:Start-HiveTune {
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [PSCustomObject]$Miners,
        ## Potential Future Implementation
        [Parameter(Position = 1, Mandatory = $false)]
        [string]$Miner_Name,
        ## Potential Future Implementation
        [Parameter(Position = 2, Mandatory = $false)]
        [string]$Miner_Pool,
        ## Potential Future Implementation
        [Parameter(Position = 3, Mandatory = $false)]
        [string]$Profit_Day
    )


    log "Checking Hive OC Tuning" -ForegroundColor Cyan
    $OCSheet = @()
    $Algo = $Algo -replace "`_", " "
    $Algo = $Algo -replace "veil", "x16rt"
    $Url = "https://api2.hiveos.farm/api/v2/farms/$($Global:Config.hive_params.FarmID)/workers/$($Global:Config.hive_params.Id)"
    $CheckOC = $false
    $CheckDate = Get-Date
    $Success = $false

    $T = @{Authorization = "Bearer $($(arg).API_Key)" }
    $Splat = @{ Method = "GET"; Uri = $Url + "?token=$($(arg).API_Key)"; Headers = $T; ContentType = 'application/json'; }
    try { $Worker = Invoke-RestMethod @Splat -TimeoutSec 10 -ErrorAction Stop } catch { log "WARNING: Failed to Contact HiveOS for OC" -ForegroundColor Yellow; return }

}