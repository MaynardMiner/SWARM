function Global:Get-StatsXmrstak {
    if( $global:MinerName -like "*xmrig*"){$message = "/1/summary"}
    else{ $Message = "/api.json" }
    $Request = Global:Get-HTTP -Port $global:Port -Message $Message
    if ($Request) {
        try { $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop; }catch { Write-Host "Failed To gather summary" -ForegroundColor Red; break }
        $HashRate_Total = [Double]$Data.hashrate.total[0]
        if (-not $HashRate_Total) { $HashRate_Total = [Double]$Data.hashrate.total[1] } #fix
        if (-not $HashRate_Total) { $HashRate_Total = [Double]$Data.hashrate.total[2] } #fix
        $global:RAW = $HashRate_Total
        $global:GPUKHS += [Double]$HashRate_Total / 1000
        Write-Host "Note: XMR-STAK/XMRig API is not great. You can't match threads to specific GPU." -ForegroundColor Yellow
        Global:Write-MinerData2
        try { 
            $Hash = for ($global:i = 0; $global:i -lt $Data.hashrate.threads.count; $global:i++) { 
                $Data.Hashrate.threads[$global:i] | Select-Object -First 1 
            } 
        }
        catch { }
        try { 
            for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) { 
                $GPU = $Devices[$global:i]; $global:GPUHashrates.$(Global:Get-GPUs) = ($Hash[$GPU] | Select-Object -First 1) / 1000 
            } 
        }
        catch { Write-Host "Failed To parse threads" -ForegroundColor Red };
        $global:MinerACC += $Data.results.shares_good
        $global:MinerREJ += [Double]$Data.results.shares_total - [Double]$Data.results.shares_good
        $global:ALLACC += $global:MinerACC
        $global:ALLREJ += $global:MinerREJ
    }
    else { Global:Set-APIFailure }
}