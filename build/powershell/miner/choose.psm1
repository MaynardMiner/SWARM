function Remove-BadMiners {
    $BadMiners = @()
    if ($global:Config.Params.Threshold -ne 0) { $Global:Miners | ForEach-Object { if ($_.Profit -gt $global:Config.Params.Threshold) { $BadMiners += $_ } } }
    $BadMiners | ForEach-Object { $Global:Miners.Remove($_) }
    $BadMiners = $Null
}

function Get-BestMiners {

    $BestMiners = @()

    $global:Config.Params.Type | foreach {
        $SelType = $_
        $BestTypeMiners = @()
        $OldMiners = @()
        $OldTypeMiners = @()
        $MinerCombo = @()

        $TypeMiners = $Global:Miners | Where Type -EQ $SelType
        $BestActiveMiners | ForEach { $Global:Miners | Where Path -EQ $_.Path | Where Arguments -EQ $_.Arguments | Where Type -EQ $SelType | ForEach { $OldMiners += $_ } }
        if ($OldMiners) {
            $OldTypeMiners += $OldMiners | Where Profit -gt 0 | Sort-Object @{Expression = "Profit"; Descending = $true } | Select -First 1
            $OldTypeMiners += $OldMiners | Where Profit -lt 0 | Sort-Object @{Expression = "Profit"; Descending = $false } | Select -First 1
            $OldTypeMiners = $OldTypeMiners | Select -First 1
            $OldTypeMiners | foreach { $_ | Add-Member "Old" "Yes" }
        }
        if ($OldTypeMiners) { $MinerCombo += $OldTypeMiners }
        $MinerCombo += $TypeMiners | Where Profit -NE $NULL
        $BestTypeMiners += $TypeMiners | Where Profit -EQ $NULL | Select -First 1
        $BestTypeMiners += $MinerCombo | Where Profit -NE $Null | Where Profit -gt 0 | Sort-Object { ($_ | Measure Profit -Sum).Sum } -Descending | Select -First 1
        $BestTypeMiners += $MinerCombo | Where Profit -NE $Null | Where Profit -lt 0 | Sort-Object { ($_ | Measure Profit -Sum).Sum } -Descending | Select -First 1
        $BestMiners += $BestTypeMiners | Select -first 1
    }

    $BestMiners
}

function Get-Conservative {
    if ($global:Config.Params.Conserve -eq "Yes") {
        $global:bestminers_combo = @()
        $global:Config.Params.Type | ForEach-Object {
            $SelType = $_
            $ConserveArray = @()
            $ConserveArray += $global:Miners_Combo | Where-Object Type -EQ $SelType | Where-Object Profit -EQ $NULL
            $ConserveArray += $global:Miners_Combo | Where-Object Type -EQ $SelType | Where-Object Profit -GT 0
        }
        $global:bestminers_combo += $ConserveArray
    }
    else { $global:bestminers_combo = $Miners_Combo }
    $global:Miners_Combo = $Null
    $ConserveArray = $null
    $global:bestminers_combo
}