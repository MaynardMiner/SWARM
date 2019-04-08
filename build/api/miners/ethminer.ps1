function Get-StatsEthminer {
    if ($MinerName -eq "PhoenixMiner" -or $MinerName -eq "Phoenixminer.exe") { $Message = @{id = 1; jsonrpc = "2.0"; method = "miner_getstat2" } | ConvertTo-Json -Compress
    }
    else { $Message = @{id = 1; jsonrpc = "2.0"; method = "miner_getstat1" } | ConvertTo-Json -Compress
    }
    $Request = $null; $Request = Get-TCP -Server $Server -Port $Port -Message $Message 
    if ($Request) {
        try { $Data = $Null; $Data = $Request | ConvertFrom-Json -ErrorAction STop; }catch { Write-Host "Failed To parse API" -ForegroundColor Red }
        if ($Data) { $Summary = $Data.result[2]; $Threads = $Data.result[3]; }
        if ($Minername -eq "TT-Miner.exe" -or $MinerName -eq "TT-Miner") { $global:BRAW += $Summary -split ";" | Select-Object -First 1 | ForEach-Object { [Double]$_ } }
        else { $global:BRAW += $Summary -split ";" | Select-Object -First 1 | ForEach-Object { [Double]$_ * 1000 } }
        Write-MinerData2;
        if ($Minername -eq "TT-Miner.exe" -or $MinerName -eq "TT-Miner") { $global:BKHS += $Summary -split ";" | Select-Object -First 1 | ForEach-Object { [Double]$_ / 1000 } }
        else { $global:BKHS += $Summary -split ";" | Select-Object -First 1 | ForEach-Object { [Double]$_ } }
        if ($Minername -eq "TT-Miner.exe" -or $MinerName -eq "TT-Miner") { $Hash = $Null; $Hash = $Threads -split ";" | ForEach-Object { [double]$_ / 1000 } }
        else { $Hash = $Null; $Hash = $Threads -split ";" }
        try { for ($i = 0; $i -lt $Devices.Count; $i++) { $global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i) } }catch { Write-Host "Failed To parse GPU Threads" -ForegroundColor Red };
        $global:MinerACC = $Summary -split ";" | Select-Object -skip 1 -first 1
        $global:MinerREJ = $Summary -split ";" | Select-Object -skip 2 -first 1
        $global:BACC += $Summary -split ";" | Select-Object -skip 1 -first 1
        $global:BREJ += $Summary -split ";" | Select-Object -skip 2 -first 1
        $global:BUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
        if ($MinerType -eq "NVIDIA1" -or $MinerType -eq "AMD1") { $global:BALGO.Add("Main", $global:BHiveAlgo) }
        else { $global:BALGO.Add($MinerType, $global:BHiveAlgo) }
        if ($MinerType -eq "NVIDIA1" -or $MinerType -eq "AMD1") { $global:TALGO.Add("Main", $MinerAlgo) }
        else { $global:TALGO.Add($MinerType, $MinerAlgo) }
    }
    else { Set-APIFailure; break }

}