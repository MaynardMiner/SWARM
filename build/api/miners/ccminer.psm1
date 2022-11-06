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
function Global:Get-StatsCcminer {
    switch ($global:MinerName) {
        "zjazz_cuda.exe" { if ($Global:MinerAlgo -eq "cuckoo_cycle") { $Multiplier = 2000000 }else { $Multiplier = 1000 } }
        "zjazz_cuda" { if ($Global:MinerAlgo -eq "cuckoo_cycle") { $Multiplier = 2000000 }else { $Multiplier = 1000 } }
        "zjazz_amd.exe" { if ($Global:MinerAlgo -eq "cuckoo_cycle") { $Multiplier = 2000000 }else { $Multiplier = 1000 } }
        "zjazz_amd" { if ($Global:MinerAlgo -eq "cuckoo_cycle") { $Multiplier = 2000000 }else { $Multiplier = 1000 } }
        default { $Multiplier = 1000 }
    }

    $Request = $Null; $Request = Global:Get-TCP -Server $global:Server -Port $global:Port -Message "summary"
    if ($Request) {
        try { $GetKHS = $Request -split ";" | ConvertFrom-StringData -ErrorAction Stop }catch { Write-Warning "Failed To Get Summary"; break }
        $global:RAW = if ([Double]$GetKHS.KHS -ne 0 -or [Double]$GetKHS.ACC -ne 0) { [Double]$GetKHS.KHS * $Multiplier }
        Global:Write-MinerData2;
        $global:GPUKHS += if ([Double]$GetKHS.KHS -ne 0 -or [Double]$GetKHS.ACC -ne 0) { [Double]$GetKHS.KHS }
    }
    else { Global:Set-APIFailure }
    $GetThreads = $Null; $GetThreads = Global:Get-TCP -Server $global:Server -Port $global:Port -Message "threads"
    if ($GetThreads) {
        $Data = $GetThreads -split "\|"
        $DataHash = $Data -split ";" | Select-String "KHS" | ForEach-Object { $_ -replace ("KHS=", "") }
        $Hash = @()
        $DataHash | Foreach-Object { 
            $HashValue = [Double]$_
            $NewValue = $HashValue * 1000
            $Hash += $NewValue
        }
        try { 
            for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) { 
                $global:GPUHashrates.$(Global:Get-GPUs) = Global:Set-Array $Hash $global:i 
            } 
        }
        catch { Write-Host "Failed To parse Threads" -ForegroundColor Red };
        try { $global:MinerACC += $Request -split ";" | Select-String "ACC=" | ForEach-Object { $_ -replace ("ACC=", "") } }catch { }
        try { $global:MinerREJ += $Request -split ";" | Select-String "REJ=" | ForEach-Object { $_ -replace ("REJ=", "") } }catch { }
        $global:ALLACC += $global:MinerACC
        $global:ALLREJ += $global:MinerREJ
    }
    else { Write-Host "API Threads Failed" }
}