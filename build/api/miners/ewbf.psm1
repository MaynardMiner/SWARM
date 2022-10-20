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
function Global:Get-StatsEWBF {
    $Message = @{id = 1; method = "getstat" } | ConvertTo-Json -Compress
    $Request = Global:Get-TCP -Server $global:Server -Port $global:Port -Message $Message
    if ($Request) { 
        try { $Data = $Null; $Data = $Request | ConvertFrom-Json -ErrorAction Stop; }
        catch { Write-Host "Failed To parse API" -ForegroundColor Red; break }
        $Data = $Data.result
        $Data.speed_sps | ForEach-Object { $global:RAW += [Double]$_; $global:GPUKHS += [Double]$_ / 1000 }
        $Hash = $Data.speed_sps
        Global:Write-MinerData2;
        try {
            for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) { 
                $global:GPUHashrates.$(Global:Get-GPUs) = (Global:Set-Array $Hash $global:i) 
            }
        }
        catch { Write-Host "Failed To parse Threads" -ForegroundColor Red };
        $Data.accepted_shares | ForEach-Object { $global:MinerACC += $_ }
        $Data.rejected_shares | ForEach-Object { $global:MinerREJ += $_ }
        $global:ALLACC += $global:MinerACC
        $global:ALLREJ += $global:MinerREJ
    }
    else { Global:Set-APIFailure }
}