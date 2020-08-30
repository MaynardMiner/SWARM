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
function Global:Get-StatsCgminer {
    $Hash_Table = @{HS = 1; KHS = 1000; MHS = 1000000; GHS = 1000000000; THS = 1000000000000; PHS = 1000000000000000 }
    $Command = "summary|0"
    $Request = Global:Get-TCP -Server $global:Server -Port $global:Port -Message $Command
    if ($Request) {
        $response = $Request -split "SUMMARY," | Select-Object -Last 1
        $response = $Request -split "," | ConvertFrom-StringData
        if ($response."HS 5s") { $global:RAW = [Double]$response."HS 5s" * $Hash_Table.HS }
        if ($response."KHS 5s") { $global:RAW = [Double]$response."KHS 5s" * $Hash_Table.KHS }
        if ($response."MHS 5s") { $global:RAW = [Double]$response."MHS 5s" * $Hash_Table.MHS }
        if ($response."GHS 5s") { $global:RAW = [Double]$response."GHS 5s" * $Hash_Table.GHS }
        if ($response."THS 5s") { $global:RAW = [Double]$response."THS 5s" * $Hash_Table.THS }
        if ($response."PHS 5s") { $global:RAW = [Double]$response."PHS 5s" * $Hash_Table.PHS }
        if ($response."HS_5s") { $global:RAW = [Double]$response."HS_5s" * $Hash_Table.HS }
        if ($response."KHS_5s") { $global:RAW = [Double]$response."KHS_5s" * $Hash_Table.KHS }
        if ($response."MHS_5s") { $global:RAW = [Double]$response."MHS_5s" * $Hash_Table.MHS }
        if ($response."GHS_5s") { $global:RAW = [Double]$response."GHS_5s" * $Hash_Table.GHS }
        if ($response."THS_5s") { $global:RAW = [Double]$response."THS_5s" * $Hash_Table.THS }
        if ($response."PHS_5s") { $global:RAW = [Double]$response."PHS_5s" * $Hash_Table.PHS }
        Global:Write-MinerData2;
        $global:ASICKHS += if ($global:RAW -ne 0) { [Double]$global:RAW / 1000 }
        $global:ASICHashRates.$($global:Anumber) = if ($global:RAW -ne 0) { [Double]$global:RAW / 1000 }
        $global:MinerREJ += $response.Rejected
        $global:MinerACC += $response.Accepted
        $global:ALLACC += $global:MinerACC
        $global:ALLREJ += $global:MinerREJ
    } 
    else { Global:Set-APIFailure }
}