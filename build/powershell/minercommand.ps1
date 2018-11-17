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

$GetPoolBlocks = $null
$GetAlgoBlocks = $null
if(Test-Path ".\timeout\pool_block\pool_block.txt"){$GetPoolBlocks = Get-Content ".\timeout\pool_block\pool_block.txt" | ConvertFrom-Json}
if(Test-Path ".\timeout\algo_block\algo_block.txt"){$GetAlgoBlocks = Get-Content ".\timeout\algo_block\algo_block.txt" | ConvertFrom-Json}
if(Test-Path ".\timeout\miner_block\miner_block.txt"){$GetMinerBlocks = Get-Content ".\timeout\miner_block\miner_block.txt" | ConvertFrom-Json}

$GetMiners = if(Test-Path "miners\gpu"){Get-ChildItemContent "miners\gpu" | ForEach {$_.Content | Add-Member @{Name = $_.Name} -PassThru} |
 Where {$Type.Count -eq 0 -or (Compare-Object $Type $_.Type -IncludeEqual -ExcludeDifferent | Measure).Count -gt 0} |
 Where {$_.Path -ne "None"} |
 Where {$_.Uri -ne "None"} |
 Where {$_.MinerName -ne "None"}}

$ScreenedMiners = @()

$GetMiners | foreach {
if(-not ($GetPoolBlocks | Where Algo -eq $_.Algo | Where Name -eq $_.Name | Where Type -eq $_.Type | Where MinerPool -eq $_.Minerpool))
 {
  if(-not ($GetAlgoBlocks | Where Algo -eq $_.Algo | Where Name -eq $_.Name | Where Type -eq $_.Type))
   {
    if(-not ($GetMinerBlocks | Where Name -eq $_.Name | Where Type -eq $_.Type))
     {
      $ScreenedMiners += $_
     }
     else{$BadMessage = "Warning: Blocking $($_.Name) for $($_.Type)"}
   }
   else{Write-Host "Warning: Blocking $($_.Name) mining $($_.Algo) on all pools for $($_.Type)" -ForegroundColor Magenta}
 }
 else{Write-Host "Warning: Blocking $($_.Name) mining $($_.Algo) on $($_.MinerPool) for $($_.Type)" -ForegroundColor Magenta}
}

if($BadMessage -ne $Null){Write-Host "$BadMessage" -ForegroundColor Magenta}

#$GetPoolBlocks | foreach {
#if($_.Algo -eq $miner.Algo -and $_.Name -eq $miner.Name -and $_.Type -eq $miner.Type -and $_.MinerPool -eq $miner.MinerPool){ $miner | Add-Member "PoolBlock" "Yes"}
#}
   
#$GetAlgoBlocks | foreach {
#if($_.Algo -eq $miner.Algo -and $_.Name -eq $miner.Name -and $_.Type -eq $miner.Type){ $miner | Add-Member "AlgoBlock" "Yes"}
# }
#}  
#$MinerList = $GetMiners | Where PoolBlock -ne "Yes" | Where AlgoBlock -ne "Yes"

$ScreenedMiners
}