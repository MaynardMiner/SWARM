function Global:Get-StatsNanominer {
    $Request = Global:Get-HTTP -Server $global:Server -Port $global:Port -Message "/stat" -Timeout 5
    if ($Request) {
        try { $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop } 
        Catch { Write-Host "Failed To parse API" -ForegroundColor Red; Break }
        if ($Data) {
            $Data = $Data.Statistics
            switch ($global:MinerAlgo) {
                "ethash" { $Data.Devices | % { $global:RAW += [Double]$_.hashrates.hashrate * 1000000 } }
                default { $Data.Devices | % { $global:RAW += [Double]$_.hashrates.hashrate } }
            }
            Global:Write-MinerData2;
            try { 
                for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) {
                    $Hash = $($Data.Devices[$global:i]).hashrates.hashrate
                    switch ($global:MinerAlgo) {
                        "ethash" { $global:GPUHashrates.$(Global:Get-GPUs) = $Hash * 1000 }
                        default { $global:GPUHashrates.$(Global:Get-GPUs) = $Hash / 1000 }
                    }
                }
            }
            catch { Write-Host "Failed To parse Threads" -ForegroundColor Red };
            $Data.Devices | % { $global:MinerACC += [Double]$_.hashrates.gpuAccepted; $global:ALLACC += [Double]$_.hashrates.gpuAccepted }
            $Data.Devices | % { $global:MinerREJ += [Double]$_.hashrates.gpuDenied; $global:ALLREJ += [Double]$_.hashrates.gpuDenied }
            $Data.devices.speed | ForEach-Object { $global:GPUKHS += [Double]$_.hashrates.hashrate / 1000 }
        }
    }
    else { Global:Set-APIFailure }
}