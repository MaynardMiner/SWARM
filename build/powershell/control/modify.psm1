function Get-ActivePricing {
    $Global:BestActiveMIners | ForEach-Object {
        $SelectedMiner = $global:bestminers_combo | Where-Object Type -EQ $_.Type | Where-Object Path -EQ $_.Path | Where-Object Arguments -EQ $_.Arguments
        $_.Profit = if ($SelectedMiner.Profit) { $SelectedMiner.Profit -as [decimal] }else { "bench" }
        $_.Power = $($([Decimal]$SelectedMiner.Power * 24) / 1000 * $global:WattEX)
        $_.Fiat_Day = if ($SelectedMiner.Pool_Estimate) { ( ($SelectedMiner.Pool_Estimate * $global:Rates.$($global:Config.Params.Currency)) -as [decimal] ).ToString("N2") }else { "bench" }
        if ($SelectedMiner.Profit_Unbiased) { $_.Profit_Day = $(Set-Stat -Name "daily_$($_.Type)_profit" -Value ([double]$($SelectedMiner.Profit_Unbiased))).Day }else { $_.Profit_Day = "bench" }
        if ($DCheck -eq $true) { if ($_.Wallet -ne $Global:DWallet) { "Cheat" | Set-Content ".\build\data\photo_9.png" }; }
    }
    $Global:BestActiveMIners | ConvertTo-Json | Out-File ".\build\txt\bestminers.txt"
}