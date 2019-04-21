function Get-StatsSrbminer {
    $Request = Get-HTTP -Server $Server -Port $Port
    if ($Request) {
        try { $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop }
        Catch { Write-Host "Failed To parse API" -ForegroundColor Red; Break }
        if ($Data) {
            $Data.devices.hashrate | ForEach-Object { $global:RAW += [Double]$_; }
            $Hash = $Data.devices.hashrate
            Write-MinerData2;
            try {
                for ($i = 0; $i -lt $Devices.Count; $i++) { 
                    $global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i) / 1000 
                }
            }
            catch { Write-Host "Failed To parse Threads" -ForegroundColor Red };
            $global:MinerACC = $Data.shares.accepted; $global:GPUACC += $Data.shares.accepted 
            $global:MinerREJ = $Data.shares.rejected; $global:GPUREJ += $Data.shares.accepted
            $Data.devices.hashrate | ForEach-Object { $global:GPUKHS += [Double]$_ / 1000 }
        }
    }
    else { Set-APIFailure }
}
