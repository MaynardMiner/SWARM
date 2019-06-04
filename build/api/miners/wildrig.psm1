function Global:Get-StatsWildrig {
    $Message = '/api.json'
    $Request = Global:Get-HTTP -Port $global:Port -Message $Message
    if ($Request) {
        try { $Data = $Null; $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop; }catch { Write-Host "Failed To parse API" -ForegroundColor Red; break }
        try { $global:RAW = $Data.hashrate.total[0]; $global:GPUKHS += [Double]$Data.hashrate.total[0] / 1000 }catch { }
        Global:Write-MinerData2;
        $Hash = $Data.hashrate.threads
        try {
            for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) {
                $GPU = $Devices[$global:i]; $global:GPUHashrates.$(Global:Get-GPUs) = [Double]($Hash[$GPU] | Select-Object -First 1) / 1000
            } 
        }
        catch { Write-Host "Failed To parse GPU Array" -ForegroundColor Red }
        $global:MinerACC += $Data.results.shares_good
        $global:MinerREJ += [Double]$Data.results.shares_total - [Double]$Data.results.shares_good
        $global:ALLACC += $global:MinerACC
        $global:ALLREJ += $global:MinerREJ
    }
    else { Global:Set-APIFailure }
}