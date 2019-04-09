function Get-StatsGrinMiner {
    $global:HS = "hs"
    try { $Request = Get-Content ".\logs\$MinerType.log" -ErrorAction SilentlyContinue }catch { Write-Host "Failed to Read Miner Log" }
    if ($Request) {
        $Hash = @()
        $Devices | ForEach-Object {
            $DeviceData = $Null
            $DeviceData = $Request | Select-String "Device $($_)" | ForEach-Object { $_ | Select-String "Graphs per second: " } | Select-Object -Last 1
            $DeviceData = $DeviceData -split "Graphs per second: " | Select-Object -Last 1 | ForEach-Object { $_ -split " - Total" | Select-Object -First 1 }
            if ($DeviceData) { $Hash += $DeviceData; $global:BRAW += [Double]$DeviceData }else { $Hash += 0; $global:BRAW += 0 }
        }
        Write-MinerData2;
        try { for ($i = 0; $i -lt $Devices.Count; $i++) { $global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i) } }catch { Write-Host "Failed To parse GPU Threads" -ForegroundColor Red };
        $global:BACCepted = $null
        $global:BREJected = $null
        $global:BACCepted = $($Request | Select-String "Share Accepted!!").count
        $global:BREJected = $($Request | Select-String "Failed to submit a solution").count
        $global:BACC += $global:BACCepted
        $global:BREJ += $global:BREJected
        $global:BMinerACC += $global:BACCepted
        $global:BMinerREJ += $global:BREJected
        $global:BUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
        switch ($MinerType) {
            "NVIDIA1" { $global:BALGO.Add("Main", $global:BHiveAlgo); $global:TALGO.Add("Main", $MinerAlgo) }
            "AMD1" { $global:BALGO.Add("Main", $global:BHiveAlgo); $global:TALGO.Add("Main", $MinerAlgo) }
            default { $global:BALGO.Add($MinerType, $global:BHiveAlgo); $global:TALGO.Add($MinerType, $MinerAlgo) }
        }
    }
    else { Set-APIFailure; break }
}