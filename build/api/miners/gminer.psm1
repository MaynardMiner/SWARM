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
function Global:Get-StatsGminer {
    $Request = Global:Get-HTTP -Server $global:Server -Port $global:Port -Message "/stat" -Timeout 5
    if ($Request) {
        try { $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop }
        Catch { Write-Host "Failed To parse API" -ForegroundColor Red; Break }
        if ($Data) {
            $Data.devices.speed | ForEach-Object { $global:RAW += [Double]$_; }
            $Hash = $Data.devices.speed
            Global:Write-MinerData2;
            try { 
                for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) { 
                    $global:GPUHashrates.$(Global:Get-GPUs) = (Global:Set-Array $Hash $global:i) 
                }
            }
            catch { Write-Host "Failed To parse Threads" -ForegroundColor Red };
            #$Data.devices.accepted_shares | Select-Object -First 1 | ForEach-Object { $global:MinerACC = $_; $global:ALLACC += $_ }
            #$Data.devices.rejected_shares | Select-Object -First 1 | ForEach-Object { $global:MinerREJ = $_; $global:ALLREJ += $_ }
            $global:MinerACC = [int]$Data.total_accepted_shares
            $global:ALLACC += [int]$Data.total_accepted_shares
            $global:MinerREJ = [int]$Data.total_rejected_shares
            $global:ALLREJ += [int]$Data.total_rejected_shares

            $Data.devices.speed | ForEach-Object { $global:GPUKHS += [Double]$_ / 1000 }
        }
    }
    else { Global:Set-APIFailure }
}