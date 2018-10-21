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
function Get-Miners {
    param (
        [Parameter(Mandatory=$false)]
        [string]$Platforms,        
        [Parameter(Mandatory=$false)]
        [string]$MinerType,
        [Parameter(Mandatory=$false)]
        [Array]$Stats,
        [Parameter(Mandatory=$false)]
        [Array]$Pools
    )


if(Test-Path ".\timeout\pool_block.txt"){$GetPoolBlock = Get-Content ".\timeout\pool_block.txt" | ConvertFrom-Json}
if(Test-Path ".\timeout\algo_block.txt"){$GetAlgoBlock = Get-Content ".\timeout\algo_block.txt" | ConvertFrom-Json}

if($Platforms -eq "linux")
{
   $GetMiners = if(Test-Path "miners\linux"){Get-ChildItemContent "miners\linux" | ForEach {$_.Content | Add-Member @{Name = $_.Name} -PassThru} |
   Where {$Type.Count -eq 0 -or (Compare-Object $Type $_.Type -IncludeEqual -ExcludeDifferent | Measure).Count -gt 0}}
}

if($Platforms -eq "windows")
{
$GetMiners = if(Test-Path "miners\windows"){Get-ChildItemContent "miners\windows" | ForEach {$_.Content | Add-Member @{Name = $_.Name} -PassThru} | 
Where {$Type.Count -eq 0 -or (Compare-Object $Type $_.Type -IncludeEqual -ExcludeDifferent | Measure).Count -gt 0}}
}

$GetMiners | foreach {
$miner = $_
   
$GetPoolBlock | foreach {
if($_.Algo -eq $miner.Algo -and $_.Name -eq $miner.Name -and $_.Type -eq $miner.Type -and $_.MinerPool -eq $miner.MinerPool){ $miner | Add-Member "PoolBlock" "Yes"}
}
   
$GetAlgoBlock | foreach {
if($_.Algo -eq $miner.Algo -and $_.Name -eq $miner.Name -and $_.Type -eq $miner.Type){ $miner | Add-Member "AlgoBlock" "Yes"}
 }
}
   
$GetMiners = $GetMiners | Where PoolBlock -ne "Yes" | Where AlgoBlock -ne "Yes"

$GetMiners

}