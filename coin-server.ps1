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

param(
[Parameter(Mandatory=$false)]
[Array]$Type = ("NVIDIA1"), #AMD/NVIDIA/CPU
[Parameter(Mandatory=$false)]
[array]$No_Algo = "myr-gr",
[Parameter(Mandatory=$false)]
[Array]$PoolName = ("zergpool_algo","zergpool_coin")
)

While ($True)
{

Clear-Host

Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
Get-ChildItem . -Recurse -Force | Out-Null 
. .\Build\Unix\IncludeCoin.ps1
. .\Build\Unix\Hive\HiveCmd.ps1

$Stat_Coin = "Live"
$Type = "NVIDIA1"
$Dir = (Split-Path $script:MyInvocation.MyCommand.Path)
$Poolname = "zergpool_coin"
$Algorithm = @()
$Algorithm = Get-AlgorithmList -DeviceType $Type -No_Algo $No_Algo -CmdDir $Dir
$CoinAlgo = $Algorithm

Write-Host "Contacting Coin Servers"

$AllCoinPools = if(Test-Path "Server"){Get-ChildItemContent "Server" | ForEach {$_.Content | Add-Member @{Name = $_.Name} -PassThru} |
Where {$PoolName.Count -eq 0 -or (Compare-Object $PoolName $_.Name -IncludeEqual -ExcludeDifferent | Measure).Count -gt 0}}

$AllCoinPools

Write-Host "Waiting A Minute"

Start-Sleep -s 60

}
