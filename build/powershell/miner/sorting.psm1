function Global:Start-MinerReduction {

    $CutMiners = @()
    $(arg).Type | ForEach-Object {
        $GetType = $_;
        $(vars).Miners.Symbol | Select-Object -Unique | ForEach-Object {
            $zero = $(vars).Miners | Where-Object Type -eq $GetType | Where-Object Symbol -eq $_ | Where-Object Quote -EQ 0; 
            $nonzero = $(vars).Miners | Where-Object Type -eq $GetType | Where-Object Symbol -eq $_ | Where-Object Quote -NE 0;

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


function Global:Get-Volume {
    $(vars).Pool_Hashrates.keys | ForEach-Object {
        $SortAlgo = $_
        $Sorted = @()
        $(vars).Pool_Hashrates.$SortAlgo.keys | ForEach-Object { $Sorted += [PSCustomObject]@{Name = "$($_)"; HashRate = [Decimal]$(vars).Pool_Hashrates.$SortAlgo.$_.HashRate } }
        $BestHash = [Decimal]$($Sorted | Sort-Object HashRate -Descending | Select -First 1).HashRate
        $(vars).Pool_Hashrates.$SortAlgo.keys | ForEach-Object { $(vars).Pool_Hashrates.$SortAlgo.$_.Percent = (([Decimal]$BestHash - [Decimal]$(vars).Pool_Hashrates.$SortAlgo.$_.HashRate) / [decimal]$BestHash) }
    }
}

function Global:Start-Sorting {

    $(vars).Miners | ForEach-Object {

        $Miner = $_
     
        $MinerPool = $Miner.MinerPool | Select-Object -Unique

        if ($Miner.Power -gt 0) { $WattCalc3 = (((([Double]$Miner.Power * 24) / 1000) * $(vars).WattEx) * -1) }
        else { $WattCalc3 = 0 }
            
        if ($(vars).Pool_Hashrates.$($Miner.Algo).$MinerPool.Percent -gt 0) { $Hash_Percent = $(vars).Pool_Hashrates.$($Miner.Algo).$MinerPool.Percent * 100 }
        else { $Hash_Percent = 0 }

        $Miner_Volume = ([Double]($Miner.Quote * (1 - ($Hash_Percent / 100))))
        $Miner_Modified = ([Double]($Miner_Volume * (1 - ($Miner.Fees / 100))))

        $Miner | Add-Member Profit ([Double]($Miner_Modified + $WattCalc3)) ##Used to calculate BTC/Day and sort miners
        $Miner | Add-Member Profit_Unbiased ([Double]($Miner_Modified + $WattCalc3)) ##Uset to calculate Daily profit/day moving averages
        $Miner | Add-Member Pool_Estimate ([Double]($Miner.Quote)) ##RAW calculation for Live Value (Used On screen)
        $Miner | Add-Member Volume $( if ($(vars).Pool_Hashrates.$($Miner.Algo).$MinerPool.Percent -gt 0) { [Double]$(vars).Pool_Hashrates.$($Miner.Algo).$MinerPool.Percent * 100 } else { 0 } )
            
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

function Global:Add-SwitchingThreshold {
    $(vars).BestActiveMiners | ForEach-Object {
        $Sel = $_
        $SWMiner = $(vars).Miners | Where-Object Path -EQ $Sel.path | Where-Object Arguments -EQ $Sel.Arguments | Where-Object Type -EQ $Sel.Type 
        if ($SWMiner -and $SWMiner.Profit -ne $NULL -and $SWMiner.Profit -ne "bench") {
            if ($(arg).Switch_Threshold) {
                log "Switching_Threshold changes $($SWMiner.Name) $($SWMiner.Algo) base factored price from $(($SWMiner.Profit * $(vars).Rates.$($(arg).Currency)).ToString("N2"))" -ForegroundColor Cyan -NoNewLine -Start; 
                if ($SWMiner.Profit -GT 0) {
                    $($(vars).Miners | Where Path -eq $SWMiner.path | Where Arguments -eq $SWMiner.Arguments | Where Type -eq $SWMINer.Type).Profit = [Decimal]$SWMiner.Profit * (1 + ($(arg).Switch_Threshold / 100)) 
                }
                else {
                    $($(vars).Miners | Where Path -eq $SWMiner.path | Where Arguments -eq $SWMiner.Arguments | Where Type -eq $SWMINer.Type).Profit = [Decimal]$SWMiner.Profit * (1 + ($(arg).Switch_Threshold / -100))
                }  
                log " to $(($SWMiner.Profit * $(vars).Rates.$($(arg).Currency)).ToString("N2"))" -ForegroundColor Cyan -End
            }
        }
    }
}