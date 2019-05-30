function Get-StatsCcminer {
    switch ($global:MinerName) {
        "zjazz_cuda.exe" { if ($Global:MinerAlgo -eq "cuckoo_cycle") { $Multiplier = 2000000 }else { $Multiplier = 1000 } }
        "zjazz_cuda" { if ($Global:MinerAlgo -eq "cuckoo_cycle") { $Multiplier = 2000000 }else { $Multiplier = 1000 } }
        "zjazz_amd.exe" { if ($Global:MinerAlgo -eq "cuckoo_cycle") { $Multiplier = 2000000 }else { $Multiplier = 1000 } }
        "zjazz_amd" { if ($Global:MinerAlgo -eq "cuckoo_cycle") { $Multiplier = 2000000 }else { $Multiplier = 1000 } }
        default { $Multiplier = 1000 }
    }

    $Request = $Null; $Request = Get-TCP -Server $global:Server -Port $global:Port -Message "summary"
    if ($Request) {
        try { $GetKHS = $Request -split ";" | ConvertFrom-StringData -ErrorAction Stop }catch { Write-Warning "Failed To Get Summary"; break }
        $global:RAW = if ([Double]$GetKHS.KHS -ne 0 -or [Double]$GetKHS.ACC -ne 0) { [Double]$GetKHS.KHS * $Multiplier }
        Write-MinerData2;
        $global:GPUKHS += if ([Double]$GetKHS.KHS -ne 0 -or [Double]$GetKHS.ACC -ne 0) { [Double]$GetKHS.KHS }
    }
    else { Set-APIFailure }
    $GetThreads = $Null; $GetThreads = Get-TCP -Server $global:Server -Port $global:Port -Message "threads"
    if ($GetThreads) {
        $Data = $GetThreads -split "\|"
        $Hash = $Data -split ";" | Select-String "KHS" | ForEach-Object { $_ -replace ("KHS=", "") }
        try { 
            for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) { 
                $global:GPUHashrates.$(Get-Gpus) = Set-Array $Hash $global:i 
            } 
        }
        catch { Write-Host "Failed To parse Threads" -ForegroundColor Red };
        try { $global:MinerACC += $Request -split ";" | Select-String "ACC=" | ForEach-Object { $_ -replace ("ACC=", "") } }catch { }
        try { $global:MinerREJ += $Request -split ";" | Select-String "REJ=" | ForEach-Object { $_ -replace ("REJ=", "") } }catch { }
        $global:ALLACC += $global:MinerACC
        $global:ALLREJ += $global:MinerREJ
    }
    else { Write-Host "API Threads Failed" }
}