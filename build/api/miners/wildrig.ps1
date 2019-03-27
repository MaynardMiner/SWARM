function Get-StatsWildrig {
    $global:HS = "khs"
    $Message = $Null; $Message = '/api.json'
    $Request = $Null; $Request = Get-HTTP -Port $Port -Message $Message
    if ($Request) {
        try {$Data = $Null; $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop; }catch {Write-Host "Failed To parse API" -ForegroundColor Red}
        try {$global:BRAW = $Data.hashrate.total[0]}catch {}
        Write-MinerData2;
        $Hash = $Data.hashrate.threads
        try {for ($i = 0; $i -lt $Devices.Count; $i++) {$GPU = $Devices[$i]; $global:GPUHashrates.$(Get-Gpus) = [Double]($Hash[$GPU] | Select -First 1) / 1000}}catch {Write-Host "Failed To parse GPU Array" -ForegroundColor Red}
        $global:BMinerACC += $Data.results.shares_good
        $global:BMinerREJ += [Double]$Data.results.shares_total - [Double]$Data.results.shares_good 
        $global:BACC += $Data.results.shares_good
        $global:BREJ += [Double]$Data.results.shares_total - [Double]$Data.results.shares_good
        $global:BUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
        $global:BALGO += "$MinerAlgo"
        try {$global:BKHS += [Double]$Data.hashrate.total[0] / 1000}catch {}
    }
    else {Set-APIFailure; break}
}