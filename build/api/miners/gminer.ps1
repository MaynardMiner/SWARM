function Get-StatsGminer {
    $global:HS = "hs"
    $Request = $null; $Request = Get-HTTP -Server $server -Port $Port -Message "/stat" -Timeout 5
    if ($Request) {
        try { $Data = $null; $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop }Catch { Write-Host "Failed To parse API" -ForegroundColor Red }
        $Data.devices.speed | ForEach-Object { $global:BRAW += [Double]$_; }
        $Hash = $Null; $Hash = $Data.devices.speed
        Write-MinerData2;
        try { for ($i = 0; $i -lt $Devices.Count; $i++) { $global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i) / 1000 } } catch { Write-Host "Failed To parse Threads" -ForegroundColor Red };
        $Data.devices.accepted_shares | Select-Object -First 1 | ForEach-Object { $global:BMinerACC += $_;  $global:BACC += $_  }
        $Data.devices.rejected_shares | Select-Object -First 1 | ForEach-Object { $global:BMinerREJ += $_;  $global:BREJ += $_  }
        $Data.devices.speed | ForEach-Object { $global:BKHS += [Double]$_ / 1000 }
        $global:BUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
        switch ($MinerType) {
            "NVIDIA1" { $global:BALGO.Add("Main", $global:BHiveAlgo); $global:TALGO.Add("Main", $MinerAlgo) }
            "AMD1" { $global:BALGO.Add("Main", $global:BHiveAlgo); $global:TALGO.Add("Main", $MinerAlgo) }
            default { $global:BALGO.Add($MinerType, $global:BHiveAlgo); $global:TALGO.Add($MinerType, $MinerAlgo) }
        }
    }
    else { Set-APIFailure; break }
}