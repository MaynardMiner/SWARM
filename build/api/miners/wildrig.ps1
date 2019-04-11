function Get-StatsWildrig {
    $Message = '/api.json'
    $Request = Get-HTTP -Port $Port -Message $Message
    if ($Request) {
        try { $Data = $Null; $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop; }catch { Write-Host "Failed To parse API" -ForegroundColor Red; break }
        try { $global:RAW = $Data.hashrate.total[0]; $global:GPUKHS += [Double]$Data.hashrate.total[0] / 1000 }catch { }
        Write-MinerData2;
        $Hash = $Data.hashrate.threads
        try { for ($i = 0; $i -lt $Devices.Count; $i++) {
            $GPU = $Devices[$i]; $global:GPUHashrates.$(Get-Gpus) = [Double]($Hash[$GPU] | Select-Object -First 1) / 1000
         } 
        }catch { Write-Host "Failed To parse GPU Array" -ForegroundColor Red }
        $global:MinerACC += $Data.results.shares_good
        $global:MinerREJ += [Double]$Data.results.shares_total - [Double]$Data.results.shares_good
        $global:ALLACC += $global:MinerACC
        $global:ALLREJ += $global:MinerREJ
    }
    else { Set-APIFailure }
}