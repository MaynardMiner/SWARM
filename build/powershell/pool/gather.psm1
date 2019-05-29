function Get-Pools {
    param (
        [Parameter(Mandatory = $false)]
        [String]$PoolType,
        [Parameter(Mandatory = $false)]
        [array]$Items
    )

    Switch($PoolType)
    {
     "Algo"{$GetPools = if ($Items) {Get-ChildItemContent -Items $Items | ForEach {if($_ -ne $Null){$_.Content | Add-Member @{Name = $_.Name} -PassThru}}}}
     "Coin"{$GetPools = if ($Items) {Get-ChildItemContent -Items $Items | ForEach {if($_ -ne $Null){$_.Content | Add-Member @{Name = $_.Name} -PassThru}}}}
     "Custom"{$GetPools = if ($Items) {Get-ChildItemContent -Items $Items | ForEach {if($_ -ne $Null){$_.Content | Add-Member @{Name = $_.Name} -PassThru}}}}
    }

    $GetPools
  
}
function Get-AlgoPools {
    $global:QuickTimer.Restart()
    $Files = Get-ChildItem "algopools" | Where BaseName -in $global:Config.params.poolname #| Select -First 1
    write-Log "Checking Algo Pools." -Foregroundcolor yellow;
    $AllAlgoPools = Get-Pools -PoolType "Algo" -Items $Files
    ##Get Custom Pools
    write-Log "Adding Custom Pools. ." -ForegroundColor Yellow;
    $Files = Get-ChildItem "custompools" | Where BaseName -in $global:Config.params.poolname #| Select -First 1
    $AllCustomPools = Get-Pools -PoolType "Custom" -Items $Files

    if ($global:Config.Params.Auto_Algo -eq "Yes" -or $SingleMode -eq $True) {

        ## Select the best 3 of each algorithm
        $Top_3_Algo = $AllAlgoPools.Symbol | Select-Object -Unique | ForEach-Object { $AllAlgoPools | Where-Object Symbol -EQ $_ | Sort-Object Price -Descending | Select-Object -First 3 };
        $Top_3_Custom = $AllCustomPools.Symbol | Select-Object -Unique | ForEach-Object { $AllCustomPools | Where-Object Symbol -EQ $_ | Sort-Object Price -Descending | Select-Object -First 3 };
        $AllAlgoPools = $Null
        $AllCustomPools = $Null

        ## Combine Stats From Algo and Custom
        $global:AlgoPools = New-Object System.Collections.ArrayList
        if ($Top_3_Algo) { $Top_3_Algo | ForEach-Object { $global:AlgoPools.Add($_) | Out-Null } }
        if ($Top_3_Custom) { $Top_3_Custom | ForEach-Object { $global:AlgoPools.Add($_) | Out-Null } }
        $Top_3_Algo = $Null;
        $Top_3_Custom = $Null;
        $global:QuickTimer.Stop()
        Write-Log "Algo Pools Loading Time: $([math]::Round($global:QuickTimer.Elapsed.TotalSeconds)) seconds" -Foreground Green
    }
}
function Get-CoinPools {
        ##Optional: Load Coin Database
        if ($global:Config.Params.Auto_Coin -eq "Yes") {
            $global:QuickTimer.Restart()
            $coin_files = Get-ChildItem "coinpools" | Where BaseName -in $global:Config.params.poolname
            write-Log "Adding Coin Pools. . ." -ForegroundColor Yellow
            $AllCoinPools = Get-Pools -PoolType "Coin" -Items $coin_files
            $global:CoinPools = New-Object System.Collections.ArrayList
            $AllCoinPools.algorithm | Select-Object -Unique | ForEach-Object { $SelAlgo = $_; $Sel = $AllCoinPools | Where-Object algorithm -EQ $SelAlgo | Sort-Object Price -Descending | Select-Object -First 3; $Sel | % {$global:CoinPools.ADD($_) | Out-Null} }
            $CoinPoolNames = $global:CoinPools.Name | Select-Object -Unique
            if ($CoinPoolNames) { 
                $CoinPoolNames | ForEach-Object { 
                    $CoinName = $_; 
                    $RemovePools = $Global:AlgoPools | Where-Object Name -eq $CoinName; 
                    $RemovePools | ForEach-Object { $Global:AlgoPools.Remove($_) | Out-Null } 
                } 
            }
            $RemovePools = $null
            $global:QuickTimer.Stop()
            Write-Log "Coin Pools Loading Time: $([math]::Round($global:QuickTimer.Elapsed.TotalSeconds)) seconds" -Foreground Green
        }
}

