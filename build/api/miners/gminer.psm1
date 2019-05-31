function Global:Get-StatsGminer {
    $Request = Global:Get-HTTP -Server $global:Server -Port $global:Port -Message "/stat" -Timeout 5
    if ($Request) {
        try { $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop }
        Catch { Write-Host "Failed To parse API" -ForegroundColor Red; Break }
        if ($Data) {
            $Data.devices.speed | ForEach-Object { $global:RAW += [Double]$_; }
            $Hash = $Data.devices.speed
            Global:Write-MinerData2;
            try { 
                for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) { 
                    $global:GPUHashrates.$(Global:Get-GPUs) = (Global:Set-Array $Hash $global:i) / 1000 
                }
            }
            catch { Write-Host "Failed To parse Threads" -ForegroundColor Red };
            $Data.devices.accepted_shares | Select-Object -First 1 | ForEach-Object { $global:MinerACC = $_; $global:ALLACC += $_ }
            $Data.devices.rejected_shares | Select-Object -First 1 | ForEach-Object { $global:MinerREJ = $_; $global:ALLREJ += $_ }
            $Data.devices.speed | ForEach-Object { $global:GPUKHS += [Double]$_ / 1000 }
        }
    }
    else { Global:Set-APIFailure }
}