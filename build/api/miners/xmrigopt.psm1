
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
function Global:Get-Statsxmrigopt {
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
        $global:CPUKHS = $HashRate_Total / 1000
        Global:Write-MinerData2
        Write-Host "Note: XMR-STAK/XMRig API is not great. You can't match threads to specific CPU." -ForegroundColor Yellow
        $Hash = @()
        catch { Write-Host "Failed To parse threads" -ForegroundColor Red };
        $global:MinerACC += $Data.results.shares_good
        $global:MinerREJ += [Double]$Data.results.shares_total - [Double]$Data.results.shares_good
        $global:ALLACC += $global:MinerACC
        $global:ALLREJ += $global:MinerREJ
    }
    else { Write-Host "$MinerAPI API Failed- Could Not Get Stats" -Foreground Red; $global:BCPURAW = 0; }
}