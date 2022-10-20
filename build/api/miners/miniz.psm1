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
function Global:Get-StatsMiniz {
    try { $Request = Invoke-WebRequest "http://$($global:Server):$global:Port" -UseBasicParsing -TimeoutSec 10 }catch { }
    if ($Request) {
        $Data = $Request.Content -split " "
        $Hash = $Data | Select-String "Sol/s" | Select-String "data-label" | ForEach-Object { $_ -split "</td>" | Select-Object -First 1 } | ForEach-Object { $_ -split ">" | Select-Object -Last 1 }
        $global:RAW = $Hash | Select-Object -Last 1
        Global:Write-MinerData2;
        $global:GPUKHS += [Double]$global:RAW / 1000
        $Shares = $Data | Select-String "Shares" | Select-Object -Last 1 | ForEach-Object { $_ -split "</td>" | Select-Object -First 1 } | ForEach-Object { $_ -split ">" | Select-Object -Last 1 }
        try { 
            for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) { 
                $global:GPUHashrates.$(Global:Get-GPUs) = (Global:Set-Array $Hash $global:i) 
            } 
        }
        catch { Write-Host "Failed To parse Threads" -ForegroundColor Red };
        $global:MinerACC += $Shares -split "/" | Select-Object -first 1
        $global:MinerREJ += $Shares -split "/" | Select-Object -Last 1
        $global:ALLACC += $global:MinerACC
        $global:ALLREJ += $global:MinerREJ
    }
    else { Global:Set-APIFailure; break }
}