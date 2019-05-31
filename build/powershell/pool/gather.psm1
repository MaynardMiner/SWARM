function Global:Get-Pools {
    param (
        [Parameter(Mandatory = $false)]
        [String]$PoolType,
        [Parameter(Mandatory = $false)]
        [array]$Items
    )

    Switch ($PoolType) {
        "Algo" { $GetPools = if ($Items) { Global:Get-ChildItemContent -Items $Items | ForEach { if ($_ -ne $Null) { $_.Content | Add-Member @{Name = $_.Name } -PassThru } } }
        }
        "Coin" { $GetPools = if ($Items) { Global:Get-ChildItemContent -Items $Items | ForEach { if ($_ -ne $Null) { $_.Content | Add-Member @{Name = $_.Name } -PassThru } } }
        }
        "Custom" { $GetPools = if ($Items) { Global:Get-ChildItemContent -Items $Items | ForEach { if ($_ -ne $Null) { $_.Content | Add-Member @{Name = $_.Name } -PassThru } } }
        }
    }

    $GetPools
  
}
function Global:Get-AlgoPools {
    $global:QuickTimer.Restart()
    $Files = Get-ChildItem "algopools" | Where BaseName -in $global:Config.params.poolname
    Global:Write-Log "Checking Algo Pools." -Foregroundcolor yellow;
    $AllAlgoPools = Global:Get-Pools -PoolType "Algo" -Items $Files
    ##Get Custom Pools
    Global:Write-Log "Adding Custom Pools. ." -ForegroundColor Yellow;
    $Files = Get-ChildItem "custompools" | Where BaseName -in $global:Config.params.poolname
    $AllCustomPools = Global:Get-Pools -PoolType "Custom" -Items $Files

    if ($global:Config.Params.Auto_Algo -eq "Yes" -or $SingleMode -eq $True) {

        ## Select the best 3 of each algorithm
        $global:AlgoPools = New-Object System.Collections.ArrayList
        $AllAlgoPools.Symbol | Select-Object -Unique | ForEach-Object { 
            $AllAlgoPools | 
            Where-Object Symbol -EQ $_ | 
            Sort-Object Price -Descending | 
            Select-Object -First 3 |
            ForEach-Object { $global:AlgoPools.Add($_) | Out-Null }
        };
        $AllCustomPools.Symbol | Select-Object -Unique | ForEach-Object { 
            $AllCustomPools | 
            Where-Object Symbol -EQ $_ | 
            Sort-Object Price -Descending | 
            Select-Object -First 3 
            ForEach-Object { $global:AlgoPools.Add($_) | Out-Null }
        };
        $global:QuickTimer.Stop()
        Global:Write-Log "Algo Pools Loading Time: $([math]::Round($global:QuickTimer.Elapsed.TotalSeconds)) seconds" -Foreground Green
    }
}
function Global:Get-CoinPools {
    ##Optional: Load Coin Database
    if ($global:Config.Params.Auto_Coin -eq "Yes") {
        $global:QuickTimer.Restart()
        $coin_files = Get-ChildItem "coinpools" | Where BaseName -in $global:Config.params.poolname
        Global:Write-Log "Adding Coin Pools. . ." -ForegroundColor Yellow
        $AllCoinPools = Get-Pools -PoolType "Coin" -Items $coin_files
        $global:CoinPools = New-Object System.Collections.ArrayList
        $AllCoinPools.algorithm | Select-Object -Unique | ForEach-Object { 
            $AllCoinPools | 
            Where-Object algorithm -EQ $SelAlgo | 
            Sort-Object Price -Descending | 
            Select-Object -First 3 |
            ForEach-Object { $global:CoinPools.ADD($_) | Out-Null } 
        }
        $global:CoinPools.Name | Select-Object -Unique | ForEach-Object { 
            $Global:AlgoPools | 
            Where-Object Name -EQ $_ | 
            ForEach-Object { $Global:AlgoPools.Remove($_) | Out-Null } 
        } 
        $global:QuickTimer.Stop()
        Global:Write-Log "Coin Pools Loading Time: $([math]::Round($global:QuickTimer.Elapsed.TotalSeconds)) seconds" -Foreground Green
    }
}

