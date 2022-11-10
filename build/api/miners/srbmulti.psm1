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
function Global:Get-StatsSrbmulti {
    $Request = Global:Get-HTTP -Server $global:Server -Port $global:Port
    if ($Request) {
        try { $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop }
        Catch { Write-Host "Failed To parse API" -ForegroundColor Red; Break }
        if ($Data) {
            $global:RAW += $Data.algorithms.hashrate.'1min';
            $Hash = @()
            Global:Write-MinerData2;
            $Data.algorithms.hashrate.gpu | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                    $Hash += $Data.algorithms.hashrate.gpu.$_
            }
            try {
                for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) { 
                    $global:GPUHashrates.$(Global:Get-GPUs) = (Global:Set-Array $Hash $global:i)
                }
            }
            catch { Write-Host "Failed To parse Threads" -ForegroundColor Red };
            $global:MinerACC = $Data.algorithms.shares.accepted; $global:ALLACC += $Data.algorithms.shares.accepted 
            $global:MinerREJ = $Data.algorithms.shares.rejected; $global:ALLREJ += $Data.algorithms.shares.rejected
            $Hash | ForEach-Object { $global:GPUKHS += [Double]$_ / 1000 }
        }
    }
    else { Global:Set-APIFailure }
}
