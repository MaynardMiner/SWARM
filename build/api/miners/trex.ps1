function Get-StatsTrex {
    $global:HS = "khs"
    $Request = $Null; $Request = Get-HTTP -Port $Port -Message "/summary"
    if ($Request) {
        try { $Data = $Null; $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop; }catch { Write-Host "Failed To parse API" -ForegroundColor Red }
        $global:BRAW = if ([Double]$Data.hashrate_minute -ne 0 -or [Double]$Data.accepted_count -ne 0) { [Double]$Data.hashrate_minute }
        Write-MinerData2;
        $Hash = $Null; $Hash = $Data.gpus.hashrate_minute
        try { for ($i = 0; $i -lt $Devices.Count; $i++) { $global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i) / 1000 } }catch { Write-Host "Failed To parse Threads" -ForegroundColor Red };
        $Data.accepted_count | ForEach-Object { $global:BMinerACC += $_ }
        $Data.rejected_count | ForEach-Object { $global:BMinerREJ += $_ }
        $Data.accepted_count | ForEach-Object { $global:BACC += $_ }
        $Data.rejected_count | ForEach-Object { $global:BREJ += $_ }
        $global:BKHS += if ([Double]$Data.hashrate_minute -ne 0 -or [Double]$Data.accepted_count -ne 0) { [Double]$Data.hashrate_minute / 1000 }
        $global:BUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
        if ($MinerType -eq "NVIDIA1" -or $MinerType -eq "AMD1") { $global:BALGO.Add("Main", $global:BHiveAlgo) }
        else { $global:BALGO.Add($MinerType, $global:BHiveAlgo) }
        if ($MinerType -eq "NVIDIA1" -or $MinerType -eq "AMD1") { $global:TALGO.Add("Main", $MinerAlgo) }
        else { $global:TALGO.Add($MinerType, $MinerAlgo) }
    }
    else { Set-APIFailure; break }
}