function Get-StatsXmrstak {
    $global:HS = "hs"
    $Message = $Null; $Message = "/api.json"
    $Request = $Null; $Request = Get-HTTP -Port $Port -Message $Message
    if ($Request) {
        try {$Data = $Null; $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop; }catch {Write-Host "Failed To gather summary" -ForegroundColor Red}
        $HashRate_Total = [Double]$Data.hashrate.total[0]
        if (-not $HashRate_Total) {$HashRate_Total = [Double]$Data.hashrate.total[1]} #fix
        if (-not $HashRate_Total) {$HashRate_Total = [Double]$Data.hashrate.total[2]} #fix
        $global:BRAW = $HashRate_Total
        Write-Host "Note: XMR-STAK/XMRig API is not great. You can't match threads to specific GPU." -ForegroundColor Yellow
        Write-MinerData2
        try {$Hash = for ($i = 0; $i -lt $Data.hashrate.threads.count; $i++) {$Data.Hashrate.threads[$i] | Select -First 1}}catch {}
        try {for ($i = 0; $i -lt $Devices.Count; $i++) {$GPU = $Devices[$i]; $global:GPUHashrates.$(Get-Gpus) = ($Hash[$GPU] | Select -First 1) / 1000}}catch {Write-Host "Failed To parse threads" -ForegroundColor Red};
        $global:BMinerACC += $Data.results.shares_good
        $global:BMinerREJ += [Double]$Data.results.shares_total - [Double]$Data.results.shares_good
        $global:BACC += $Data.results.shares_good
        $global:BREJ += [Double]$Data.results.shares_total - [Double]$Data.results.shares_good
        $global:BUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
        $global:BALGO.Add($MinerType,$MinerAlgo)
        try {$global:BKHS += [Double]$HashRate_Total / 1000}catch {}
    }
    else {Set-APIFailure; break}
}