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
function Global:Get-StatsMultiminer {
    $GetSummary = Global:Get-TCP -Server $global:Server -Port $global:Port -Message "summary"
    if ($GetSummary) {
        $SUM = $GetSummary -split ";" | Select-String "KHS=" | ForEach-Object { $_ -replace ("KHS=", "") }
        $global:RAW = [double]$SUM * 1000
        Global:Write-MinerData2
    }
    else { Write-Host "API Summary Failed- Could Not Total Hashrate" -Foreground Red; break }
    $GetThreads = Global:Get-TCP -Server $global:Server -Port $global:Port -Message "threads"
    if ($GetThreads) {
        $Data = $GetThreads -split "\|"
        $kilo = $false
        $KHash = $Data | Select-String "kH/s"
        if ($KHash) { $Hash = $Data -split ";" | Select-String "kH/s"; $kilo = $true }
        else { $Hash = $Data -split ";" | Select-String "H/s"; $kilo = $false }
        $Hash = $Hash | ForEach-Object { $_ -split "=" | Select-Object -Last 1 }
        $J = $Hash | ForEach-Object { Invoke-Expression [Double]$_ }
        if ($kilo -eq $true) {
            if ($Hash) { 
                for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) { $global:GPUHashrates.$(Global:Get-GPUs) = (Global:Set-Array $Hash $global:i) }
            }
            $J | ForEach-Object { $global:CPUKHS += $_ }
        }
        else {
            if ($Hash) { 
                for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) { $global:GPUHashrates.$(Global:Get-GPUs) = (Global:Set-Array $Hash $global:i) } 
            }
            $J | ForEach-Object { $global:GPUKHS += $_ }
        }
        $global:MinerACC = $GetSummary -split ";" | Select-String "ACC=" | ForEach-Object { $_ -replace ("ACC=", "") }
        $global:MinerREJ = $GetSummary -split ";" | Select-String "REJ=" | ForEach-Object { $_ -replace ("REJ=", "") }
        $global:ALLACC += $global:MinerACC
        $global:ALLREJ += $global:MinerREJ
    }
    else { Write-Host "API Threads Failed- Could Not Get Individual GPU Information" -Foreground Red }
}