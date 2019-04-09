function Get-StatsMiniz {
    $global:HS = "hs"
    try { $Request = $Null; $Request = Invoke-WebRequest "http://$($server):$port" -UseBasicParsing -TimeoutSec 10 }catch { }
    if ($Request) {
        $Data = $null; $Data = $Request.Content -split " "
        $Hash = $Null; $Hash = $Data | Select-String "Sol/s" | Select-String "data-label" | ForEach-Object { $_ -split "</td>" | Select-Object -First 1 } | ForEach-Object { $_ -split ">" | Select-Object -Last 1 }
        $global:BRAW = $Hash | Select-Object -Last 1
        Write-MinerData2;
        $global:BKHS += [Double]$global:BRAW / 1000
        $Shares = $Data | Select-String "Shares" | Select-Object -Last 1 | ForEach-Object { $_ -split "</td>" | Select-Object -First 1 } | ForEach-Object { $_ -split ">" | Select-Object -Last 1 }
        $global:BACC += $Shares -split "/" | Select-Object -first 1
        $global:BREJ += $Shares -split "/" | Select-Object -Last 1
        $global:BMinerACC = $Shares -split "/" | Select-Object -first 1
        $global:BMinerREJ = $Shares -split "/" | Select-Object -Last 1
        try { for ($i = 0; $i -lt $Devices.Count; $i++) { $global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i) / 1000 } }catch { Write-Host "Failed To parse Threads" -ForegroundColor Red };
        switch ($MinerType) {
            "NVIDIA1" { $global:BALGO.Add("Main", $global:BHiveAlgo); $global:TALGO.Add("Main", $MinerAlgo) }
            "AMD1" { $global:BALGO.Add("Main", $global:BHiveAlgo); $global:TALGO.Add("Main", $MinerAlgo) }
            default { $global:BALGO.Add($MinerType, $global:BHiveAlgo); $global:TALGO.Add($MinerType, $MinerAlgo) }
        }
        $global:BUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
    }
    else { Set-APIFailure; break }
}