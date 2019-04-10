function Get-StatsXmrstak {
    $Message = "/api.json"
    $Request = Get-HTTP -Port $Port -Message $Message
    if ($Request) {
        try { $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop; }catch { Write-Host "Failed To gather summary" -ForegroundColor Red; break }
        $HashRate_Total = [Double]$Data.hashrate.total[0]
        if (-not $HashRate_Total) { $HashRate_Total = [Double]$Data.hashrate.total[1] } #fix
        if (-not $HashRate_Total) { $HashRate_Total = [Double]$Data.hashrate.total[2] } #fix
        $global:RAW = $HashRate_Total
        $global:GPUKHS += [Double]$HashRate_Total / 1000
        Write-Host "Note: XMR-STAK/XMRig API is not great. You can't match threads to specific GPU." -ForegroundColor Yellow
        Write-MinerData2
        try { 
            $Hash = for ($i = 0; $i -lt $Data.hashrate.threads.count; $i++) { 
                $Data.Hashrate.threads[$i] | Select-Object -First 1 
            } 
        }catch { }
        try { 
            for ($i = 0; $i -lt $Devices.Count; $i++) { 
                $GPU = $Devices[$i]; $global:GPUHashrates.$(Get-Gpus) = ($Hash[$GPU] | Select-Object -First 1) / 1000 
            } 
        }catch { Write-Host "Failed To parse threads" -ForegroundColor Red };
        $global:MinerACC += $Data.results.shares_good
        $global:MinerREJ += [Double]$Data.results.shares_total - [Double]$Data.results.shares_good
        $global:ALLACC += $global:MinerACC
        $global:ALLREJ += $global:MinerREJ
    }
    else { Set-APIFailure }
}