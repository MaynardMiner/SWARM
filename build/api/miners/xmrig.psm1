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
        $HashRate_Total = 0;
        foreach($threads in $Data.hashrate.threads) {
                $GetHash = 0;
                $ToString = [string]$threads[0];
                $IsInt = [Double]::TryParse($ToString, [ref]$GetHash);
                $HashRate_Total += $Gethash;   
        }
        $global:RAW = $HashRate_Total
        $global:GPUKHS += $HashRate_Total / 1000
        Global:Write-MinerData2
        $Hash = @()
        try {
            ## Assume we have same amount of threads per device..All we can do.
            $Totalthreads = $Data.hashrate.threads.count / ($Data.hashrate.threads.count / $Devices.Count);
            for ($global:i = 0; $global:i -lt $Totalthreads; $global:i++) {
                [Double]$Gethash = 0;
                $Value = [String]$Data.hashrate.threads[$global:i][0]
                $Gethash = [Double]$Value
                if ($Totalthreads -gt $Devices.Count) {
                    ## Prevent out of bounds if doing multiple threads
                    if (($global:1 + 1) -le $Data.hashrate.threads.count) {
                        $Value = [String]$Data.hashrate.threads[$global:i + 1][0]
                        $Gethash += [Double]$Value
                    }
                }
                $Hash += $GetHash;
            }
        }
        catch { }
        try { 
            for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) { 
                $global:GPUHashrates.$(Global:Get-GPUs) = ($Hash[$global:i])
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