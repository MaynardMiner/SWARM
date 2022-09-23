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
function Global:Get-Statsxmrig {
    $Message = "/1/summary"
    $Request = Global:Get-HTTP -Port $global:Port -Message $Message
    if ($Request) {
        try { $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop; }catch { Write-Host "Failed To gather summary" -ForegroundColor Red; break }
        ##Grab the first one that has a value
        foreach($hash in $Data.hashrate.total) {
            $GetHash = 0;
            $IsInt = [Double]::TryParse($hash,$GetHash);
            if($IsInt) {
                break;
            }
        }
        $HashRate_Total = $GetHash;
        $global:RAW = $HashRate_Total
        $global:GPUKHS += $HashRate_Total / 1000
        Global:Write-MinerData2
        $Hash = @()
        try { 
            for ($global:i = 0; $global:i -lt $Data.hashrate.threads.count; $global:i++) {
                $GetThread = $Data.hashrate.threads[$i]
                foreach($hash in $GetThread) {
                    $GetHash = 0;
                    $IsInt = [Double]::TryParse($hash,$GetHash);
                    if($IsInt) {
                        break;
                    }
                }       
                $Hash += $GetHash;
            }
        }
        catch { }
        try { 
            if($global:TypeS -eq "CPU") {
                $global:CPUKHS += $($Hash | Measure-Object -Sum).Sum
            }
            for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) { 
                $global:GPUHashrates.$(Global:Get-GPUs) = ($Hash[$global:i]) / 1000 
            } 
        }
        catch { Write-Host "Failed To parse threads" -ForegroundColor Red };
        $global:MinerACC += $Data.results.shares_good
        $global:MinerREJ += [Double]$Data.results.shares_total - [Double]$Data.results.shares_good
        $global:ALLACC += $global:MinerACC
        $global:ALLREJ += $global:MinerREJ
    }
    else { Write-Host "$MinerAPI API Failed- Could Not Get Stats" -Foreground Red; $global:BCPURAW = 0; }
}