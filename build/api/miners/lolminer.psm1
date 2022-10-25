
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
function Global:Get-StatsLolminer {
    $Message = "/summary"
    $Request = Global:Get-HTTP -Server $global:Server -Port $global:Port -Message $Message
    if ($request) {
        try { $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop; }catch { Write-Host "Failed To parse API" -ForegroundColor Red; break }
        if($Data.Algorithms.Performance_Unit -eq "mh/s"){
            #Fix lolminer API reporting in mh/s for ETC & ETH
            $lolHashrate = [Double]$Data.Algorithms[0].Total_Performance * 1000000
            $lolmulti=1000000
        }else{
            $lolHashrate = [Double]$Data.Algorithms[0].Total_Performance
            $lolmulti=1
        }
        $global:RAW = $lolHashrate       
        $global:GPUKHS += $lolHashrate / 1000
        Global:Write-MinerData2;
        $Hash = $Data.Algorithms[0].Worker_Performance
        try { 
            for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) { 
                $global:GPUHashrates.$(Global:Get-GPUs) = ((Global:Set-Array $Hash $global:i) * $lolmulti) 
            } 
        }
        catch { Write-Host "Failed To parse GPU Array" -ForegroundColor Red };
        $global:MinerACC += [Double]$($Data.Algorithms[0].Worker_Accepted | Measure-Object -Sum).Sum
        $global:MinerREJ += [Double]$($Data.Algorithms[0].Worker_Rejected | Measure-Object -Sum).Sum
        $global:ALLACC += $global:MinerACC
        $global:ALLREJ += $global:MinerREJ
    }
    elseif (Test-Path ".\logs\$($global:Name).log") {
        Write-Host "Miner API failed- Attempting to get hashrate through logs." -ForegroundColor Yellow
        Write-Host "Will only pull total hashrate in this manner." -ForegroundColor Yellow
        $MinerLog = Get-Content ".\logs\$($global:Name).log" | Select-String "Average Speed " | Select-Object -Last 1
        $Speed = $MinerLog -split "Total: " | Select-Object -Last 1
        $Speed = $Speed -split "sol/s" | Select-Object -First 1
        if ($Speed) {
            $global:RAW += [Double]$Speed 
            $global:GPUKHS += [Double]$Speed / 1000
            Global:Write-MinerData2;
        }
    }
    else { Global:Set-APIFailure }
}
