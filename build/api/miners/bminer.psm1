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
function Global:Get-StatsBminer {
    $Request = Global:Get-HTTP -Port $global:Port -Message "/api/status"
    if ($Request) {
        try { $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop; }
        catch { Write-Host "Failed To parse API" -ForegroundColor Red }
        for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) { 
            $GPU = $Devices[$global:i]; $global:RAW += [Double]$Data.Miners.$GPU.solver.solution_rate / 1
            $global:GPUKHS += [Double]$Data.Miners.$GPU.solver.solution_rate / 1000
        }
        Global:Write-MinerData2;
        $Hash = $Data.Miners
        try {
            for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) { 
                $GPU = $Devices[$global:i]; $global:GPUHashrates.$(Global:Get-GPUs) = [Double]$Hash.$GPU.solver.solution_rate
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