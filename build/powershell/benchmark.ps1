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
    [parameter(Position=0,Mandatory=$true)]
    [String]$Name,
    [parameter(Position=1,Mandatory=$false)]
    [String]$Platform
)
Set-Location (Split-Path (Split-Path (Split-Path $script:MyInvocation.MyCommand.Path)))
Write-Host "Checking For $Name Bechmarks"

Switch($Name)
 {
  "timeout"
   {
    if(Test-Path ".\timeout"){Remove-Item ".\timeout" -Recurse -Force}
    Write-Host "Removed All Timeouts" -ForegroundColor Green
    if($Platform -eq "windows"){"Removed All Bans" | Out-File ".\build\txt\benchcom.txt"}
   }
   "all"
   {
   if(Test-Path ".\stats\*_hashrate.txt*"){Remove-Item ".\stats\*_hashrate.txt*" -Force}
   if(Test-Path ".\backup\*_hashrate.txt*"){Remove-Item ".\stats\*_hashrate.txt*" -Force}
   if(Test-Path ".\timeout\pool_block\pool_block.txt"){Clear-Content ".\timeout\pool_block\pool_block.txt"}
   if(Test-Path ".\timeout\algo_block\algo_block.txt"){Clear-Content ".\timeout\pool_block\algo_block.txt"}
   Write-Host "Removed All Benchmarks and Bans" -ForegroundColor Green

   if($Platform -eq "windows"){"Removed All Benchmarks and Bans" | Out-File ".\build\txt\benchcom.txt"}
   }
   default
   {
    if(Test-Path ".\stats\*$($Name)_hashrate.txt*"){Remove-Item ".\stats\*$($Name)_hashrate.txt*" -Force}
    if(Test-Path ".\stats\*$($Name)_power.txt*"){Remove-Item ".\stats\*$($Name)_power.txt*" -Force}
    if(Test-Path ".\backup\*$($Name)_hashrate.txt*"){Remove-Item ".\backup\*$($Name)_hashrate.txt*" -Force}
    if(Test-Path ".\backup\*$($Name)_power.txt*"){Remove-Item ".\backup\*$($Name)_power.txt*" -Force}
    if(Test-Path ".\timeout\pool_block\pool_block.txt")
    {
     $NewPoolBlock = @()
     $GetPoolBlock = Get-Content ".\timeout\pool_block\pool_block.txt" | ConvertFrom-Json
     $GetPoolBlock | foreach {if($_.Algo -ne $Name){$NewPoolBlock += $_}else{Write-Host "Found $($_.Algo) in Pool Block file"}}
     if($NewPoolBlock){$NewPoolBlock | ConvertTo-Json | Set-Content ".\timeout\pool_block\pool_block.txt"}
    }
    if(Test-Path ".\timeout\algo_block\algo_block.txt")
    {
     $NewPoolBlock = @()
     $GetPoolBlock = Get-Content ".\timeout\algo_block\algo_block.txt" | ConvertFrom-Json
     $GetPoolBlock | foreach {if($_.Algo -ne $Name){$NewPoolBlock += $_}else{Write-Host "Found $($_.Algo) in Pool Block file"}}
     if($NewPoolBlock){$NewPoolBlock | ConvertTo-Json | Set-Content ".\timeout\pool_block\pool_block.txt"}
    }
    Write-Host "Removed all $Name stats and bans." -ForegroundColor Green
    "Removed all $Name stats and bans." | Out-File ".\build\txt\benchcom.txt"
   }
 }