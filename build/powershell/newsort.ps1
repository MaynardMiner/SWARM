
function Get-BestMiners {

    $BestMiners = @()

    $Type | foreach {
        $SelType = $_
        $BestTypeMiners = @()
        $OldMiners = @()
        $OldTypeMiners = @()
        $MinerCombo = @()

        $TypeMiners = $Miners | Where Type -EQ $SelType
        $BestActiveMiners | ForEach {$Miners | Where Path -EQ $_.Path | Where Arguments -EQ $_.Arguments | Where Type -EQ $SelType | ForEach {$OldMiners += $_}}
        if ($OldMiners) {
            $OldTypeMiners += $OldMiners | Where Profit -gt 0 | Sort-Object @{Expression = "Profit"; Descending = $true} | Select -First 1
            $OldTypeMiners += $OldMiners | Where Profit -lt 0 | Sort-Object @{Expression = "Profit"; Descending = $false} | Select -First 1
            $OldTypeMiners = $OldTypeMiners | Select -First 1
            $OldTypeMiners | foreach { $_ | Add-Member "Old" "Yes"}
        }
        if ($OldTypeMiners) {$MinerCombo += $OldTypeMiners}
        $MinerCombo += $TypeMiners | Where Profit -NE $NULL
        $BestTypeMiners += $TypeMiners | Where Profit -EQ $NULL | Select -First 1
        $BestTypeMiners += $MinerCombo | Where Profit -NE $Null | Where Profit -gt 0 | Sort-Object {($_ | Measure Profit -Sum).Sum} -Descending | Select -First 1
        $BestTypeMiners += $MinerCombo | Where Profit -NE $Null | Where Profit -lt 0 | Sort-Object {($_ | Measure Profit -Sum).Sum} -Descending | Select -First 1
        $BestMiners += $BestTypeMiners | Select -first 1
    }

    $BestMiners
}