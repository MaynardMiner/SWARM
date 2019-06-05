function Global:Get-StatsSrbminer {
    $Request = Global:Get-HTTP -Server $global:Server -Port $global:Port
    if ($Request) {
        try { $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop }
        Catch { Write-Host "Failed To parse API" -ForegroundColor Red; Break }
        if ($Data) {
            $Data.devices.hashrate | ForEach-Object { $global:RAW += [Double]$_; }
            $Hash = $Data.devices.hashrate
            Global:Write-MinerData2;
            try {
                for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) { 
                    $global:GPUHashrates.$(Global:Get-GPUs) = (Global:Set-Array $Hash $global:i) / 1000 
                }
            }
            catch { Write-Host "Failed To parse Threads" -ForegroundColor Red };
            $global:MinerACC = $Data.shares.accepted; $global:ALLACC += $Data.shares.accepted 
            $global:MinerREJ = $Data.shares.rejected; $global:ALLREG += $Data.shares.accepted
            $Data.devices.hashrate | ForEach-Object { $global:GPUKHS += [Double]$_ / 1000 }
        }
    }
    else { Global:Set-APIFailure }
}
