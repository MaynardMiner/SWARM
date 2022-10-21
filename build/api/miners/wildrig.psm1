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
function Global:Get-StatsWildrig {
    $Message = '/api.json'
    $Request = Global:Get-HTTP -Port $global:Port -Message $Message
    if ($Request) {
        try { $Data = $Null; $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop; }catch { Write-Host "Failed To parse API" -ForegroundColor Red; break }
        try { $global:RAW = $Data.hashrate.total[0]; $global:GPUKHS += [Double]$Data.hashrate.total[0] / 1000 }catch { }
        Global:Write-MinerData2;
        $Hash = $Data.hashrate.threads
        try {
            for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) {
                $global:GPUHashrates.$(Global:Get-GPUs) = (Global:Set-Array $Hash $global:i)
            } 
        }
        catch { Write-Host "Failed To parse GPU Array" -ForegroundColor Red }
        $global:MinerACC += $Data.results.shares_good
        $global:MinerREJ += [Double]$Data.results.shares_total - [Double]$Data.results.shares_good
        $global:ALLACC += $global:MinerACC
        $global:ALLREJ += $global:MinerREJ
    }
    else { Global:Set-APIFailure }
}