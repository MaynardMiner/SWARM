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
function Global:Get-StatsEthminer {

    if ($global:MinerName -eq "PhoenixMiner" -or $global:MinerName -eq "Phoenixminer.exe") { 
        $Message = @{id = 1; jsonrpc = "2.0"; method = "miner_getstat2" } | ConvertTo-Json -Compress
    }
    else {
        $Message = @{id = 1; jsonrpc = "2.0"; method = "miner_getstat1" } | ConvertTo-Json -Compress
    }

    switch ($global:MinerName) {
        "TT-Miner" { $Multiplier = 1 }
        "TT-Miner.exe" { $Multiplier = 1 }
        default { $Multiplier = 1000 }
    }
    switch ($global:MinerName) {
        "TT-Miner" { $Divsor = 1000 }
        "TT-Miner.exe" { $Divsor = 1000 }
        default { $Divsor = 1 }
    }

    $Request = Global:Get-TCP -Server $global:Server -Port $global:Port -Message $Message
    if ($Request) {
        try { $Data = $Request | ConvertFrom-Json -ErrorAction Stop; }
        catch { Write-Host "Failed To parse API" -ForegroundColor Red; Break }
        if ($Data) { $Summary = $Data.result[2]; $Threads = $Data.result[3]; }
        $global:RAW += $Summary -split ";" | Select-Object -First 1 | ForEach-Object { [Convert]::ToDouble($_) * $Multiplier } 
        Global:Write-MinerData2;
        $global:GPUKHS += $Summary -split ";" | Select-Object -First 1 | ForEach-Object { [Convert]::ToDouble($_) / $Divsor } 
        $Hash = $Threads -split ";" | ForEach-Object { [Convert]::ToDouble($_) }
        
        try { 
            for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) { 
                $global:GPUHashrates.$(Global:Get-GPUs) = (Global:Set-Array $Hash $global:i) 
            } 
        }
        catch { Write-Host "Failed To parse GPU Threads" -ForegroundColor Red };

        $global:MinerACC = $Summary -split ";" | Select-Object -skip 1 -first 1
        $global:MinerREJ = $Summary -split ";" | Select-Object -skip 2 -first 1
        $global:ALLACC += $global:MinerACC
        $global:ALLREJ += $global:MinerREJ

    }
    else { Global:Set-APIFailure }
}