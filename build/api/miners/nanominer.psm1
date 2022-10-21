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
function Global:Get-StatsNanominer {
    $Request = Global:Get-HTTP -Server $global:Server -Port $global:Port -Message "/stats" -Timeout 5
    if ($Request) {
        try { $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop } 
        Catch { Write-Host "Failed To parse API" -ForegroundColor Red; Break }
        if ($Data) {
            $Data = $Data.Algorithms.$($global:MinerAlgo.replace("autolykos2","autolykos"))
            $global:RAW += [decimal]$Data.Total.Hashrate
            Global:Write-MinerData2;
            try { 
                for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) {
                    $Hash = $($Data."GPU $($global:Devices[$global:i])".Hashrate)
                    $global:GPUHashrates.$($global:Devices[$global:i]) = [decimal]$Hash
                    $global:GPUKHS += [decimal]($Hash / 1000)
                }
            }
            catch { Write-Host "Failed To parse Threads" -ForegroundColor Red };
            for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) {
                $global:MinerACC += $($Data."GPU $($global:Devices[$global:i])".Accepted)
                $global:MinerREJ += $($Data."GPU $($global:Devices[$global:i])".Denied)
                $global:ALLACC += $($Data."GPU $($global:Devices[$global:i])".Accepted)
                $global:ALLREJ += $($Data."GPU $($global:Devices[$global:i])".Denied)
            }
        }
    }
    else { Global:Set-APIFailure }
}