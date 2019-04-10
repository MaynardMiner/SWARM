function Get-StatsEthminer {

    if ($MinerName -eq "PhoenixMiner" -or $MinerName -eq "Phoenixminer.exe") { 
        $Message = @{id = 1; jsonrpc = "2.0"; method = "miner_getstat2" } | ConvertTo-Json -Compress
    } else {
        $Message = @{id = 1; jsonrpc = "2.0"; method = "miner_getstat1" } | ConvertTo-Json -Compress
    }

    $Request = Get-TCP -Server $Server -Port $Port -Message $Message
    if ($Request) {
        try { $Data = $Request | ConvertFrom-Json -ErrorAction Stop; }
        catch { Write-Host "Failed To parse API" -ForegroundColor Red; Break }
        if ($Data) { $Summary = $Data.result[2]; $Threads = $Data.result[3]; }
        $global:RAW += $Summary -split ";" | Select-Object -First 1 | ForEach-Object { [Double]$_ } 
        Write-MinerData2;
        $global:GPUKHS += $Summary -split ";" | Select-Object -First 1 | ForEach-Object { [Double]$_ / 1000 } 
        $Hash = $Threads -split ";" | ForEach-Object { [Double]$_ / 1000 }
        
        try { 
            for ($i = 0; $i -lt $Devices.Count; $i++) { 
                $global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i) 
            } 
        }catch { Write-Host "Failed To parse GPU Threads" -ForegroundColor Red };

        $global:MinerACC = $Summary -split ";" | Select-Object -skip 1 -first 1
        $global:MinerREJ = $Summary -split ";" | Select-Object -skip 2 -first 1
        $global:ALLACC += $global:MinerACC
        $global:ALLREJ += $global:MinerREJ

    }
    else { Set-APIFailure }
}