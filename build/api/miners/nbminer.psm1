function Global:Get-StatsNebutech {
    $Request = Invoke-RestMethod "http://$($global:Server):$($global:Port)/api/v1/status" -UseBasicParsing -Method Get -TimeoutSec 5
    if ($Request) {
        $Data = $Request
        $global:RAW += [Double]$Data.miner.total_hashrate_raw
        $global:GPUKHS += [Double]$Data.miner.total_hashrate_raw / 1000
        Global:Write-MinerData2;
        $Hash = $Data.Miner.devices.hashrate_raw | ForEach-Object{[Double]$_ / 1000}
        try {
            for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) {
                $global:GPUHashrates.$(Global:Get-GPUs) = Global:Set-Array $Hash $global:i
            } 
        }
        catch { Write-Host "Failed To parse Threads" -ForegroundColor Red };
        $Data.stratum.accepted_shares | ForEach-Object { $global:MinerACC += $_ }
        $Data.stratum.rejected_shares | ForEach-Object { $global:MinerREJ += $_ }
        $global:ALLACC += $global:MinerACC
        $global:ALLREJ += $global:MinerREJ
    }
    else { Global:Set-APIFailure }
}