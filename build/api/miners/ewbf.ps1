function Get-StatsEWBF {
    $global:HS = "hs"
    $Message = $null; $Message = @{id = 1; method = "getstat" } | ConvertTo-Json -Compress
    $Request = $Null; $Request = Get-TCP -Server $Server -Port $port -Message $Message
    if ($Request) { 
        try { $Data = $Null; $Data = $Request | ConvertFrom-Json -ErrorAction Stop; }catch { Write-Host "Failed To parse API" -ForegroundColor Red }
        $Data = $Data.result
        $Data.speed_sps | ForEach-Object { $global:BRAW += [Double]$_ }
        $Hash = $Null; $Hash = $Data.speed_sps
        Write-MinerData2;
        try { for ($i = 0; $i -lt $Devices.Count; $i++) { $global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i) / 1000 } }catch { Write-Host "Failed To parse Threads" -ForegroundColor Red };
        $Data.accepted_shares | ForEach-Object { $global:BMinerACC += $_ }
        $Data.rejected_shares | ForEach-Object { $global:BMinerREJ += $_ }
        $Data.accepted_shares | ForEach-Object { $global:BACC += $_ }
        $Data.rejected_shares | ForEach-Object { $global:BREJ += $_ }
        $Data.speed_sps | ForEach-Object { $global:BKHS += [Double]$_ }
        $global:BUPTIME = ((Get-Date) - [DateTime]$Data.start_time[0]).seconds
        if ($MinerType -eq "NVIDIA1" -or $MinerType -eq "AMD1") { $global:BALGO.Add("Main", $global:BHiveAlgo) }
        else { $global:BALGO.Add($MinerType, $global:BHiveAlgo) }
        if ($MinerType -eq "NVIDIA1" -or $MinerType -eq "AMD1") { $global:TALGO.Add("Main", $MinerAlgo) }
        else { $global:TALGO.Add($MinerType, $MinerAlgo) }
    }
    else { Set-APIFailure; break }
}