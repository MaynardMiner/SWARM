function Get-StatsExcavator {
    $global:HS = "khs"
    $global:BRAW = 0
    $Message = $null; $Message = @{id = 1; method = "algorithm.list"; params = @() } | ConvertTo-Json -Compress
    $Request = $null; $Request = Get-TCP -Server $Server -Port $port -Message $Message
    if ($Request) {
        try { $Data = $Null; $Data = $Request | ConvertFrom-Json -ErrorAction Stop; }catch { Write-Host "Failed To parse API" -ForegroundColor Red }
        $global:BRAW = $Summary.algorithms.speed
        Write-MinerData2;
        $global:BKHS += [Double]$Summary.algorithms.speed / 1000
    }
    else { Set-APIFailure; break }
    $Message = @{id = 1; method = "worker.list"; params = @() } | ConvertTo-Json -Compress
    $GetThreads = $Null; $GetThreads = Get-TCP -Server $Server -Port $port -Message $Message
    if ($GetThreads) {
        $Threads = $GetThreads | ConvertFrom-Json -ErrorAction Stop
        $Hash = $Null; $Hash = $Threads.workers.algorithms.speed
        try { for ($i = 0; $i -lt $Devices.Count; $i++) { $global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i) / 1000 } }catch { Write-Host "Failed To parse threads" -ForegroundColor Red };
        $global:BACC += $Summary.algorithms.accepted_shares
        $global:BREJ += $Summary.algorithms.rejected_shares
        $global:BMinerACC += $Summary.algorithms.accepted_shares
        $global:BMinerREJ += $Summary.algorithms.rejected_shares
        $global:BUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
        if ($MinerType -eq "NVIDIA1" -or $MinerType -eq "AMD1") { $global:BALGO.Add("Main", $global:BHiveAlgo) }
        else { $global:BALGO.Add($MinerType, $global:BHiveAlgo) }
        if ($MinerType -eq "NVIDIA1" -or $MinerType -eq "AMD1") { $global:TALGO.Add("Main", $MinerAlgo) }
        else { $global:TALGO.Add($MinerType, $MinerAlgo) }
    }
    else { Write-Host "API Threads Failed"; break }
}