function Get-StatsBminer {
    $Request = Get-HTTP -Port $Port -Message "/api/status"
    if ($Request) {
        try { $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop; }
        catch { Write-Host "Failed To parse API" -ForegroundColor Red }
        for ($i = 0; $i -lt $Devices.Count; $i++) { 
            $GPU = $Devices[$i]; $global:RAW += [Double]$Data.Miners.$GPU.solver.solution_rate / 1
            $global:GPUKHS += [Double]$Data.Miners.$GPU.solver.solution_rate / 1000
        }
        Write-MinerData2;
        $Hash = $Data.Miners
        try {
            for ($i = 0; $i -lt $Devices.Count; $i++) { 
                $GPU = $Devices[$i]; $global:GPUHashrates.$(Get-Gpus) = [Double]$Hash.$GPU.solver.solution_rate / 1000
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