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
    [parameter(Position = 0, Mandatory = $true)]
    [String]$command,
    [parameter(Position = 1, Mandatory = $false)]
    [String]$Name = $Null,
    [parameter(Position = 2, Mandatory = $false)]
    [String]$Arg1 = $Null
)
Set-Location (Split-Path (Split-Path (Split-Path $script:MyInvocation.MyCommand.Path)))

Write-Host "Checking For $command Benchmarks"
$Get = @()

Switch ($command) {
    "help" {
    $Get += 
"benchmark help guide

benchmark miner [minername]
    -This will benchmark miner of given name. [minername] must match name
     on 'get stats' screen.
    -By Extension This will lift all bans on miner

benchmark algorithm [algoname]
    -This will benchmark algorithm of given name. [algoname] must match name
     on 'get stats' screen.

benchmark miner [minername] [algoname]
    -This will benchmark on the algorithm of given name on the miner of the
     given name. Both must match names on 'get stats' screen.
     -By Extension This will lift all bans on miner

benchmark timeout
    -This will remove all bans.

benchmark all
    -This will benchmark everything. CANNOT BE UNDONE!
"
    }
    "timeout" {
        if (Test-Path ".\timeout") {Remove-Item ".\timeout" -Recurse -Force}
        $Get += "Removed All Timeouts and Bans"
    }
    "all" {
        if (Test-Path ".\stats\*_hashrate.txt*") {
            $Get += "Removed all Hashrates"
            Remove-Item ".\stats\*_hashrate.txt*" -Force
        }
        if (Test-Path ".\backup\*_hashrate.txt*") {
            $Get += "Removed all backup Hashrates"
            Remove-Item ".\stats\*_hashrate.txt*" -Force
        }
        if (Test-Path ".\timeout\pool_block\pool_block.txt") {
            $Get += "Removed all pool blocks"
            Remove-Item ".\timeout\pool_block\pool_block.txt" -Force
        }
        if (Test-Path ".\timeout\algo_block\algo_block.txt") {
            $Get += "Removed all algo blocks"
            Remove-Item ".\timeout\algo_block\algo_block.txt" -Force
        }
        if (Test-Path ".\timeout\download_block\download_block.txt") {
            $Get += "Removed all download blocks"
            Clear-Content ".\timeout\download_block\download_block.txt"
        }
        if (Test-Path ".\timeout\miner_block\miner_block.txt") {
            $Get += "Removed all miner blocks" 
            Clear-Content ".\timeout\miner_block\miner_block.txt"
        }
        $Get += "Removed All Benchmarks and Bans"
    }
    "miner" {
        if ($Name) {
            if($Arg1){
                if (Test-Path ".\stats\$($Name)_$($Arg1)_hashrate.txt") {Remove-Item ".\stats\$($Name)_$($Arg1)_hashrate.txt" -Force}
                if (Test-Path ".\backup\$($Name)_$($Arg1)_hashrate.txt") {Remove-Item ".\backup\$($Name)_$($Arg1)_hashrate.txt" -Force}
                $Get += "Removed all $Name bans."
                $Get += "Removed all $Name $Arg1 stats."
             }
            else {
              if (Test-Path ".\stats\*$Name*") {Remove-Item ".\stats\*$Name*" -Force}
              if (Test-Path ".\backup\*$Name*") {Remove-Item ".\backup\*$Name*" -Force}
              $Get += "Removed all $Name stats and bans."
            }
            if (Test-Path ".\timeout\pool_block\pool_block.txt") {
                $GetPoolBlock = Get-Content ".\timeout\pool_block\pool_block.txt" | ConvertFrom-Json
                if($Name -in $GetPoolBlock.Name) {
                    $Get += "Found $($Name) in Pool Block file"
                    $NewPoolBlock = $GetPoolBlock | Where Name -ne $Name | ConvertTo-Json
                    if($NewPoolBlock){$NewPoolBlock | Set-Content ".\timeout\pool_block\pool_block.txt"}
                    else{Clear-Content ".\timeout\pool_block\pool_block.txt"}
                }
            }
            if (Test-Path ".\timeout\algo_block\algo_block.txt") {
                $GetPoolBlock = Get-Content ".\timeout\algo_block\algo_block.txt" | ConvertFrom-Json
                if($Name -in $GetPoolBlock.Name) {
                    $Get += "Found $($Name) in Algo Block file"
                    $NewPoolBlock = $GetPoolBlock | Where Name -ne $Name | ConvertTo-Json
                    if($NewPoolBlock){$NewPoolBlock | Set-Content ".\timeout\algo_block\algo_block.txt"}
                    else{Clear-Content ".\timeout\algo_block\algo_block.txt"}
                }
            }
            if (Test-Path ".\timeout\miner_block\miner_block.txt") {
                $GetPoolBlock = Get-Content ".\timeout\miner_block\miner_block.txt" | ConvertFrom-Json
                if($Name -in $GetPoolBlock.Name) {
                    $Get += "Found $($Name) in Miner Block file"
                    $NewPoolBlock = $GetPoolBlock | Where Name -ne $Name | ConvertTo-Json
                    if($NewPoolBlock){$NewPoolBlock | Set-Content ".\timeout\miner_block\miner_block.txt"}
                    else{Clear-Content ".\timeout\miner_block\miner_block.txt"}
                }
            }
            if (Test-Path ".\timeout\download_block\download_block.txt") {
                $NewPoolBlock = @()
                $GetPoolBlock = Get-Content ".\timeout\download_block\download_block.txt"
                if($Name -in $GetPoolBlock) {
                    $Get += "Found $($Name) in Download Block file"
                    $NewPoolBlock = $GetPoolBlock | Where Name -ne $Name | ConvertTo-Json
                    if($NewPoolBlock){$NewPoolBlock | Set-Content ".\timeout\download_block\download_block.txt"}
                    else{Clear-Content ".\timeout\download_block\download_block.txt"}
                }
            }
        }
    }
    "algorithm" {
        if ($Name -ne "" -or $Name -ne $Null) {
            if (Test-Path ".\stats\*$($Name)_hashrate.txt*") {Remove-Item ".\stats\*$($Name)_hashrate.txt*" -Force}
            if (Test-Path ".\stats\*$($Name)_power.txt*") {Remove-Item ".\stats\*$($Name)_power.txt*" -Force}
            if (Test-Path ".\backup\*$($Name)_hashrate.txt*") {Remove-Item ".\backup\*$($Name)_hashrate.txt*" -Force}
            if (Test-Path ".\backup\*$($Name)_power.txt*") {Remove-Item ".\backup\*$($Name)_power.txt*" -Force}
            if (Test-Path ".\timeout\pool_block\pool_block.txt") {
                $GetPoolBlock = Get-Content ".\timeout\pool_block\pool_block.txt" | ConvertFrom-Json
                if($Name -in $GetPoolBlock.Algo) {
                    $Get += "Found $($Name) in Pool Block file"
                    $NewPoolBlock = $GetPoolBlock | Where Algo -ne $Name | ConvertTo-Json
                    if($NewPoolBlock){$NewPoolBlock | Set-Content ".\timeout\pool_block\pool_block.txt"}
                    else{Clear-Content ".\timeout\pool_block\pool_block.txt"}
                }
            }
            if (Test-Path ".\timeout\algo_block\algo_block.txt") {
                $GetPoolBlock = Get-Content ".\timeout\algo_block\algo_block.txt" | ConvertFrom-Json
                if($Name -in $GetPoolBlock.Algo) {
                    $Get += "Found $($Name) in Algo Block file"
                    $NewPoolBlock = $GetPoolBlock | Where Algo -ne $Name | ConvertTo-Json
                    if($NewPoolBlock){$NewPoolBlock | Set-Content ".\timeout\algo_block\algo_block.txt"}
                    else{Clear-Content ".\timeout\algo_block\algo_block.txt"}
                }
            }
            $Get += "Removed all $Name stats and bans."
        }
    }
    default {
        $Get += "No Command Given"
    }
}
$Get += "Effects will taked place after next miner benchmark/interval period."
$Get
$Get | Out-File ".\build\txt\get.txt"