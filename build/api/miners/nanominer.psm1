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
    $Request = Global:Get-HTTP -Server $global:Server -Port $global:Port -Message "/stat" -Timeout 5
    if ($Request) {
        try { $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop } 
        Catch { Write-Host "Failed To parse API" -ForegroundColor Red; Break }
        if ($Data) {
            $Data = $Data.Statistics
            switch ($global:MinerAlgo) {
                "ethash" { $Data.Devices | ForEach-Object { $global:RAW += [Double]$_.hashrates.hashrate * 1000000 } }
                "etchash" { $Data.Devices | ForEach-Object { $global:RAW += [Double]$_.hashrates.hashrate * 1000000 } }
                default { $Data.Devices | ForEach-Object { $global:RAW += [Double]$_.hashrates.hashrate } }
            }
            Global:Write-MinerData2;
            try { 
                for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) {
                    $Hash = $($Data.Devices[$global:i]).hashrates.hashrate
                    switch ($global:MinerAlgo) {
                        "ethash" { $global:GPUHashrates.$(Global:Get-GPUs) = $Hash * 1000 }
                        "etchash" { $global:GPUHashrates.$(Global:Get-GPUs) = $Hash * 1000 }
                        default { $global:GPUHashrates.$(Global:Get-GPUs) = $Hash / 1000 }
                    }
                }
            }
            catch { Write-Host "Failed To parse Threads" -ForegroundColor Red };
            $Data.Devices | ForEach-Object { $global:MinerACC += [Double]$_.hashrates.gpuAccepted; $global:ALLACC += [Double]$_.hashrates.gpuAccepted }
            $Data.Devices | ForEach-Object { $global:MinerREJ += [Double]$_.hashrates.gpuDenied; $global:ALLREJ += [Double]$_.hashrates.gpuDenied }
            $Data.devices.speed | ForEach-Object { $global:GPUKHS += [Double]$_.hashrates.hashrate / 1000 }
        }
    }
    else { Global:Set-APIFailure }
}