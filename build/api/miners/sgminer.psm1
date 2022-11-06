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
function Global:Get-StatsSgminer {
    $Message = @{command = "summary+devs"; parameter = "" } | ConvertTo-Json -Compress
    $Request = Global:Get-TCP -Server $global:Server -Port $global:Port -Message $Message
    if ($Request) {
        $Tryother = $false
        try { $Data = $Null; $Data = $Request | ConvertFrom-Json -ErrorAction Stop }catch { $Tryother = $true }
        if ($Tryother -eq $true) {
            try {
                $Request = $Request.Substring($Request.IndexOf("{"), $Request.LastIndexOf("}") - $Request.IndexOf("{") + 1) -replace " ", "_"
                $Data = $Request | ConvertFrom-Json -ErrorAction Stop
            }
            catch { Write-Host "Failed To parse GPU Array" -ForegroundColor Red; break }
        }
        $summary = $Data.summary.summary
        $threads = $Data.devs.devs
        $Sum = $Null;
        if ($summary.'KHS_5s' -gt 0) { $Sum = $summary.'KHS_5s'; $sgkey = 'KHS_5s' }
        elseif ($summary.'KHS 5s' -gt 0) { $Sum = $summary.'KHS 5s'; $sgkey = 'KHS 5s' }
        elseif ($summary.'KHS_30s' -gt 0) { $Sum = $Summary.'KHS_30s'; $sgkey = 'KHS_30s' }
        elseif ($summary.'KHS 30s' -gt 0) { $sum = $summary.'KHS 30s'; $sgkey = 'KHS 30s' }
        $DataHash = $threads.$sgkey
        $Hash = @()
        $DataHash | Foreach-Object { 
            $HashValue = [Double]$_
            $NewValue = $HashValue * 1000
            $Hash += $NewValue
        }
        $global:RAW += [Double]$Sum * 1000
        Global:Write-MinerData2;
        $global:GPUKHS += $Sum
        try { 
            for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) { 
                $global:GPUHashrates.$(Global:Get-GPUs) = Global:Set-Array $Hash $global:i 
            } 
        }
        catch { Write-Host "Failed To parse GPU Array" -ForegroundColor Red };
        $summary.Rejected | ForEach-Object { $global:MinerREJ += $_ }
        $summary.Accepted | ForEach-Object { $global:MinerACC += $_ }    
        $global:ALLACC += $global:MinerACC
        $global:ALLREJ += $global:MinerREJ
    }
    else { Global:Set-APIFailure; break }
}