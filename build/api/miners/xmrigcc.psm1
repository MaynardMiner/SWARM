function Global:Get-Statsxmrigcc {
    $Request = Global:Get-HTTP -Port $global:Port
    if ($Request) {
        try { $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop; }catch { Write-Host "Failed To gather summary" -ForegroundColor Red; break }
        $HashRate_Total = [Double]$Data.hashrate.total[0]
        if (-not $HashRate_Total) { $HashRate_Total = [Double]$Data.hashrate.total[1] } #fix
        if (-not $HashRate_Total) { $HashRate_Total = [Double]$Data.hashrate.total[2] } #fix
        $global:RAW = $HashRate_Total
        $global:GPUKHS += $HashRate_Total / 1000
        Global:Write-MinerData2
        Write-Host "Note: XMR-STAK/XMRig API is not great. You can't match threads to specific CPU." -ForegroundColor Yellow
        $Hash = @()
        try { 
            for ($global:i = 0; $global:i -lt $Data.hashrate.threads.count; $global:i++) {
                $Hash += 
                ## If there is more than one count
                if ($Data.hashrate.threads[$global:i].count -gt 1) {
                    $Data.Hashrate.threads[$global:i] | Select-Object -First 1 
                }
                ## If not select that singular item.
                else { $Data.Hashrate.threads[$Global:i] }
            }
        }
        catch { }
        try { 
            for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) { 
                $global:GPUHashrates.$(Global:Get-GPUs) = ($Hash[$global:i]) / 1000 
            } 
        }
        catch { Write-Host "Failed To parse threads" -ForegroundColor Red };
        $global:MinerACC += $Data.results.shares_good
        $global:MinerREJ += [Double]$Data.results.shares_total - [Double]$Data.results.shares_good
        $global:ALLACC += $global:MinerACC
        $global:ALLREJ += $global:MinerREJ
    }
    else { Write-Host "$MinerAPI API Failed- Could Not Get Stats" -Foreground Red; $global:BCPURAW = 0; }
}