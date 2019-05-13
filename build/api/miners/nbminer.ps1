function Get-StatsNebutech {
    $Request = Invoke-RestMethod "http://$($Server):$($Port)/api/v1/status" -UseBasicParsing -Method Get -TimeoutSec 5
    if ($Request) {
        $Data = $Request
        $global:RAW += [Double]$Data.miner.total_hashrate_raw
        $global:GPUKHS += [Double]$Data.miner.total_hashrate_raw / 1000
        Write-MinerData2;
        $Hash = $Data.Miner.devices.hashrate_raw | %{[Double]$_ / 1000}
        try {
            for ($i = 0; $i -lt $Devices.Count; $i++) {
                $global:GPUHashrates.$(Get-Gpus) = Set-Array $Hash $i
            } 
        }
        catch { Write-Host "Failed To parse Threads" -ForegroundColor Red };
        $Data.stratum.accepted_shares | ForEach-Object { $global:MinerACC += $_ }
        $Data.stratum.rejected_shares | ForEach-Object { $global:MinerREJ += $_ }
        $global:ALLACC += $global:MinerACC
        $global:ALLREJ += $global:MinerREJ
    }
    else { Set-APIFailure }
}