function Get-StatsMiniz {
    $global:HS = "hs"
    try {$Request = $Null; $Request = Invoke-Webrequest "http://$($server):$port" -UseBasicParsing -TimeoutSec 10}catch {}
    if ($Request) {
        $Data = $null; $Data = $Request.Content -split " "
        $Hash = $Null; $Hash = $Data | Select-String "Sol/s" | Select-STring "data-label" | foreach {$_ -split "</td>" | Select -First 1} | foreach {$_ -split ">" | Select -Last 1}
        $global:BRAW = $Hash | Select -Last 1
        Write-MinerData2;
        $global:BKHS += [Double]$global:BRAW / 1000
        $Shares = $Data | Select-String "Shares" | Select -Last 1 | foreach {$_ -split "</td>" | Select -First 1} | Foreach {$_ -split ">" | Select -Last 1}
        $global:BACC += $Shares -split "/" | Select -first 1
        $global:BREJ += $Shares -split "/" | Select -Last 1
        $global:BMinerACC = $Shares -split "/" | Select -first 1
        $global:BMinerREJ = $Shares -split "/" | Select -Last 1
        try {for ($i = 0; $i -lt $Devices.Count; $i++) {$global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i) / 1000}}catch {Write-Host "Failed To parse Threads" -ForegroundColor Red};
        $global:BALGO += "$MinerAlgo"
        $global:BUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
    }
    else {Set-APIFailure; break}
}