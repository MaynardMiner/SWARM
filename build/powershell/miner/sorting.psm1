function Start-MinerReduction {

    param (
        [Parameter(Mandatory = $true)]
        [array]$SortMiners,
        [Parameter(Mandatory = $true)]
        [decimal]$WattCalc
    )

    $CutMiners = @()
    $global:Config.Params.Type | ForEach-Object {
        $GetType = $_;
        $SortMiners.Symbol | Select-Object -Unique | ForEach-Object {
            $zero = $SortMiners | Where-Object Type -eq $GetType | Where-Object Symbol -eq $_ | Where-Object Quote -EQ 0; 
            $nonzero = $SortMiners | Where-Object Type -eq $GetType | Where-Object Symbol -eq $_ | Where-Object Quote -NE 0;

            if ($zero) {
                $GetMinersToCut = @()
                $GetMinersToCut += $zero
                $GetMinersToCut += $nonzero | Sort-Object @{Expression = "Quote"; Descending = $true }
                $GetMinersToCut = $GetMinersToCut | Select-Object -Skip 1;
                $GetMinersToCut | ForEach-Object { $CutMiners += $_ };
            }
            else {
                $GetMinersToCut = @()
                $GetMinersToCut = $nonzero | Sort-Object @{Expression = "Quote"; Descending = $true };
                $GetMinersToCut = $GetMinersToCut | Select-Object -Skip 1;
                $GetMinersToCut | ForEach-Object { $CutMiners += $_ };
            }
        }
    }

    $CutMiners
}


function Get-Volume {
    $global:Pool_Hashrates.keys | ForEach-Object {
        $SortAlgo = $_
        $Sorted = @()
        $global:Pool_HashRates.$SortAlgo.keys | ForEach-Object { $Sorted += [PSCustomObject]@{Name = "$($_)"; HashRate = [Decimal]$global:Pool_HashRates.$SortAlgo.$_.HashRate } }
        $BestHash = [Decimal]$($Sorted | Sort-Object HashRate -Descending | Select -First 1).HashRate
        $global:Pool_HashRates.$SortAlgo.keys | ForEach-Object { $global:Pool_HashRates.$SortAlgo.$_.Percent = (([Decimal]$BestHash - [Decimal]$global:Pool_HashRates.$SortAlgo.$_.HashRate) / [decimal]$BestHash) }
    }
}

function start-minersorting {
    param (
        [Parameter(Mandatory = $true)]
        [array]$SortMiners,
        [Parameter(Mandatory = $true)]
        [decimal]$WattCalc
    )

    $SortMiners | ForEach-Object {

        $Miner = $_
     
        $MinerPool = $Miner.MinerPool | Select-Object -Unique

        if ($Miner.Power -gt 0) { $WattCalc3 = (((([Double]$Miner.Power * 24) / 1000) * $WattCalc) * -1) }
        else { $WattCalc3 = 0 }
            
        if ($global:Pool_Hashrates.$($Miner.Algo).$MinerPool.Percent -gt 0) { $Hash_Percent = $global:Pool_Hashrates.$($Miner.Algo).$MinerPool.Percent * 100 }
        else { $Hash_Percent = 0 }

        $Miner_Volume = ([Double]($Miner.Quote * (1 - ($Hash_Percent / 100))))
        $Miner_Modified = ([Double]($Miner_Volume * (1 - ($Miner.Fees / 100))))

        $Miner | Add-Member Profit ([Double]($Miner_Modified + $WattCalc3)) ##Used to calculate BTC/Day and sort miners
        $Miner | Add-Member Profit_Unbiased ([Double]($Miner_Modified + $WattCalc3)) ##Uset to calculate Daily profit/day moving averages
        $Miner | Add-Member Pool_Estimate ([Double]($Miner.Quote)) ##RAW calculation for Live Value (Used On screen)
        $Miner | Add-Member Volume $( if ($global:Pool_Hashrates.$($Miner.Algo).$MinerPool.Percent -gt 0) { [Double]$global:Pool_Hashrates.$($Miner.Algo).$MinerPool.Percent * 100 } else { 0 } )
            
        if (-not $Miner.HashRates) {
            $miner.HashRates = $null
            $Miner.Profit = $null
            $Miner.Profit_Unbiased = $null
            $Miner.Pool_Estimate = $null
            $Miner.Volume = $null
            $Miner.Power = $null
        }
    }
}

function Add-SwitchingThreshold {
    $BestActiveMiners | ForEach-Object {
        $Sel = $_
        $SWMiner = $Global:Miners | Where-Object Path -EQ $Sel.path | Where-Object Arguments -EQ $Sel.Arguments | Where-Object Type -EQ $Sel.Type 
        if ($SWMiner -and $SWMiner.Profit -ne $NULL -and $SWMiner.Profit -ne "bench") {
            if ($global:Config.Params.Switch_Threshold) {
                write-Log "Switching_Threshold changes $($SWMiner.Name) $($SWMiner.Algo) base factored price from $(($SWMiner.Profit * $global:Rates.$($global:Config.Params.Currency)).ToString("N2"))" -ForegroundColor Cyan -NoNewLine -Start; 
                if ($SWMiner.Profit -GT 0) {
                    $($Global:Miners | Where Path -eq $SWMiner.path | Where Arguments -eq $SWMiner.Arguments | Where Type -eq $SWMINer.Type).Profit = [Decimal]$SWMiner.Profit * (1 + ($global:Config.Params.Switch_Threshold / 100)) 
                }
                else {
                    $($Global:Miners | Where Path -eq $SWMiner.path | Where Arguments -eq $SWMiner.Arguments | Where Type -eq $SWMINer.Type).Profit = [Decimal]$SWMiner.Profit * (1 + ($global:Config.Params.Switch_Threshold / -100))
                }  
                write-Log " to $(($SWMiner.Profit * $global:Rates.$($global:Config.Params.Currency)).ToString("N2"))" -ForegroundColor Cyan -End
            }
        }
    }
}