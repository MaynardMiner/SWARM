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
function Global:Get-StatsXmrstak {
    if ( $global:MinerName -like "*xmrig*") { $message = "/1/summary" }
    else { $Message = "/api.json" }
    $Request = Global:Get-HTTP -Port $global:Port -Message $Message
    if ($Request) {
        try { $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop; }catch { Write-Host "Failed To gather summary" -ForegroundColor Red; break }
        $HashRate_Total = [Double]$Data.hashrate.total[0]
        if ($HashRate_Total -eq 0) { $HashRate_Total = [Double]$Data.hashrate.total[1] } #fix
        if ($HashRate_Total -eq 0) { $HashRate_Total = [Double]$Data.hashrate.total[2] } #fix
        if ($HashRate_Total -eq 0) {
            $HashRate_Total = 0
            $Data.hashrate.threads | % { $HashRate_Total += [double]$_[0] }
        }
        $global:RAW = $HashRate_Total
        $global:GPUKHS += [Double]$HashRate_Total / 1000
        Write-Host "Note: XMR-STAK/XMRig API is not great. You can't match threads to specific GPU." -ForegroundColor Yellow
        Global:Write-MinerData2
        $Hash = @()
        try { 
            for ($global:i = 0; $global:i -lt $Data.hashrate.threads.count; $global:i++) {
                $Hash += 
                ## If there is more than one count
                if ($Data.hashrate.threads[$global:i].count -gt 1) {
                    $Data.Hashrate.threads[$global:i] | Select-Object -First 1 
                }
                ## If not select that singular item.
                else { $Data.Hashrate.threads[$Global:i] }
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
    else { Global:Set-APIFailure }
}