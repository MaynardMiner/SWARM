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
function Global:Get-StatsNebutech {
    $Request = Invoke-RestMethod "http://$($global:Server):$($global:Port)/api/v1/status" -UseBasicParsing -Method Get -TimeoutSec 5
    if ($Request) {
        $Data = $Request
        $global:RAW += [Double]$Data.miner.total_hashrate_raw
        $global:GPUKHS += [Double]$Data.miner.total_hashrate_raw / 1000
        Global:Write-MinerData2;
        $Hash = $Data.Miner.devices.hashrate_raw | ForEach-Object{[Double]$_}
        try {
            for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) {
                $global:GPUHashrates.$(Global:Get-GPUs) = Global:Set-Array $Hash $global:i
            } 
        }
        catch { Write-Host "Failed To parse Threads" -ForegroundColor Red };
        $Data.stratum.accepted_shares | ForEach-Object { $global:MinerACC += $_ }
        $Data.stratum.rejected_shares | ForEach-Object { $global:MinerREJ += $_ }
        $global:ALLACC += $global:MinerACC
        $global:ALLREJ += $global:MinerREJ
    }
    else { Global:Set-APIFailure }
}