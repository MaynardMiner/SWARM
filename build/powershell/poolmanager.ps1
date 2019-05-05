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
function Remove-Pools {
    param (
        [Parameter(Mandatory = $true)]
        [String]$IPAddress,
        [Parameter(Mandatory = $true)]
        [Int]$PoolPort,
        [Parameter(Mandatory = $true)]
        [Int]$PoolTimeout
    )
    $getpool = "pools|0"
    $getpools = Get-TCP -Server $IPAddress -Port $Port -Message $getpool -Timeout 10
    if ($getpools) {
        $ClearPools = @()
        $getpools = $getpools -split "\|" | Select -skip 1 | Where {$_ -ne ""}
        $AllPools = [PSCustomObject]@{}
        $Getpools | foreach {$Single = $($_ -split "," | ConvertFrom-StringData); $AllPools | Add-Member "Pool$($Single.Pool)" $Single}
        $AllPools | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {if ($AllPools.$_.Priority -ne 0) {$Clear = $($_ -replace "Pool", ""); $ClearPools += "removepool|$Clear"}}
        if ($ClearPools) {$ClearPools | foreach {Get-TCP -Server $Master -Port $Port -Message "$($_)" -Timeout 10}; Start-Sleep -S .5}
    }
   
    $Found = "1"
    $Found
}