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

function Global:Get-Pools {
    param (
        [Parameter(Mandatory = $false)]
        [String]$PoolType,
        [Parameter(Mandatory = $false)]
        [array]$Items
    )

    Switch ($PoolType) {
        "Algo" { $GetPools = if ($Items) { Global:Get-ChildItemContent -Items $Items | ForEach-Object { if ($_ -ne $Null) { $_.Content | Add-Member @{Name = $_.Name } -PassThru } } } }
        "Coin" { $GetPools = if ($Items) { Global:Get-ChildItemContent -Items $Items | ForEach-Object { if ($_ -ne $Null) { $_.Content | Add-Member @{ Name = $_.Name } -PassThru } } } }
        "Custom" { $GetPools = if ($Items) { Global:Get-ChildItemContent -Items $Items | ForEach-Object { if ($_ -ne $Null) { $_.Content | Add-Member @{Name = $_.Name } -PassThru } } } }
    }

    $GetPools
  
}

function Global:Get-AlgoPools {
    $start_time = (Get-Date).ToUniversalTime()
    log "Checking Algo Pools." -Foregroundcolor yellow;
    $Files = @()
    $(vars).AlgoPools = New-Object System.Collections.ArrayList
    Get-ChildItem "pools\prop" | Where-Object BaseName -in $(arg).poolname | ForEach-Object { $Files += $_ }
    Get-ChildItem "pools\pplns" | Where-Object BaseName -in $(arg).poolname | ForEach-Object { $Files += $_ }
    Get-ChildItem "pools\pps" | Where-Object BaseName -in $(arg).poolname | ForEach-Object { $Files += $_ }
    $AllAlgoPools = Global:Get-Pools -PoolType "Algo" -Items $Files

    if ($(arg).Auto_Algo -eq "Yes") {
        ## Select the best 3 of each algorithm
        $AllAlgoPools.Symbol | Select-Object -Unique | ForEach-Object { 
            $AllAlgoPools | 
                Where-Object Symbol -EQ $_ | 
                Sort-Object Price -Descending | 
                Select-Object -First 3 |
                ForEach-Object { $null = $(vars).AlgoPools.Add($_) }
        };
        $time = [math]::Round(((Get-Date).ToUniversalTime() - $start_time).TotalSeconds)      
        log "Algo Pools Loading Time: $time seconds" -Foreground Green
    }
}

function Global:Get-CoinPools {
    ##Optional: Load Coin Database
    if ($(arg).Auto_Coin -eq "Yes") {
        $start_time = (Get-Date).ToUniversalTime()
        $coin_files = Get-ChildItem "pools\coin" | Where-Object BaseName -in $(arg).poolname
        log "Adding Coin Pools. . ." -ForegroundColor Yellow
        $AllCoinPools = Global:Get-Pools -PoolType "Coin" -Items $coin_files        
        $(vars).CoinPools = New-Object System.Collections.ArrayList
        $AllCoinPools.algorithm | Select-Object -Unique | ForEach-Object { 
            $AllCoinPools | 
                Where-Object algorithm -EQ $_ | 
                Sort-Object Price -Descending | 
                Select-Object -First 3 | 
                ForEach-Object { 
                    $(vars).CoinPools.ADD($_) | Out-Null 
                } 
        }
        $(vars).CoinPools.Name | Select-Object -Unique | ForEach-Object {
            $Remove = $(vars).AlgoPools | Where-Object Name -eq $_
            $Remove | ForEach-Object { $(vars).AlgoPools.Remove($_) | Out-Null }
        }
        $time = [math]::Round(((Get-Date).ToUniversalTime() - $start_time).TotalSeconds)      
        log "Coin Pools Loading Time: $time seconds" -Foreground Green
    }
}

