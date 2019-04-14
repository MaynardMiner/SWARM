$sum | % {
    $Sel = "NVIDIA2"
    $Algo = $_.algo
    $CoinName = $_.algo
    $Percent = $_.Share
    try{if ([Double]$Percent -gt 0) {$SPercent = $Percent}else {$SPercent = 0}}catch{Write-Warning "A Share Value On Site Could Not Be Read on $Pool"}
    $Symbol = $Algo.ToLower()
    $global:Share_Table.$Sel.$Pool.Add($Symbol,@{})
    $global:Share_Table.$Sel.$Pool.$Symbol.Add("Name",$CoinName)
    $global:Share_Table.$Sel.$Pool.$Symbol.Add("Percent",$SPercent)
    $global:Share_Table.$Sel.$Pool.$Symbol.Add("Algo",$Algo)
}
