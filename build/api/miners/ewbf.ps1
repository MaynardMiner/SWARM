function Get-StatsEWBF {
    $Message = @{id = 1; method = "getstat" } | ConvertTo-Json -Compress
    $Request = Get-TCP -Server $Server -Port $port -Message $Message
    if ($Request) { 
        try { $Data = $Null; $Data = $Request | ConvertFrom-Json -ErrorAction Stop; }
        catch { Write-Host "Failed To parse API" -ForegroundColor Red; break }
        $Data = $Data.result
        $Data.speed_sps | ForEach-Object { $global:RAW += [Double]$_; $global:GPUKHS += [Double]$_ /1000}
        $Hash = $Data.speed_sps
        Write-MinerData2;
        try {
            for ($i = 0; $i -lt $Devices.Count; $i++) { 
                $global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i) / 1000 
            }
        } catch { Write-Host "Failed To parse Threads" -ForegroundColor Red };
        $Data.accepted_shares | ForEach-Object { $global:MinerACC += $_ }
        $Data.rejected_shares | ForEach-Object { $global:MinerREJ += $_ }
        $global:ALLACC += $global:MinerACC
        $global:ALLREJ += $global:MinerREJ
    }
    else { Set-APIFailure }
}