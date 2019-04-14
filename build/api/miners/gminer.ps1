function Get-StatsGminer {
    $Request = Get-HTTP -Server $server -Port $Port -Message "/stat" -Timeout 5
    if ($Request) {
        try { $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop }
        Catch { Write-Host "Failed To parse API" -ForegroundColor Red; Break }
        if ($Data) {
            $Data.devices.speed | ForEach-Object { $global:RAW += [Double]$_; }
            $Hash = $Data.devices.speed
            Write-MinerData2;
            try { 
                for ($i = 0; $i -lt $Devices.Count; $i++) { 
                    $global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i) / 1000 
                }
            }
            catch { Write-Host "Failed To parse Threads" -ForegroundColor Red };
            $Data.devices.accepted_shares | Select-Object -First 1 | ForEach-Object { $global:MinerACC = $_; $global:GPUACC += $_ }
            $Data.devices.rejected_shares | Select-Object -First 1 | ForEach-Object { $global:MinerREJ = $_; $global:GPUREJ += $_ }
            $Data.devices.speed | ForEach-Object { $global:GPUKHS += [Double]$_ / 1000 }
        }
    }
    else { Set-APIFailure }
}