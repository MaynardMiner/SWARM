function Global:Get-StatsBminer {
    $Request = Global:Get-HTTP -Port $global:Port -Message "/api/status"
    if ($Request) {
        try { $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop; }
        catch { Write-Host "Failed To parse API" -ForegroundColor Red }
        for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) { 
            $GPU = $Devices[$global:i]; $global:RAW += [Double]$Data.Miners.$GPU.solver.solution_rate / 1
            $global:GPUKHS += [Double]$Data.Miners.$GPU.solver.solution_rate / 1000
        }
        Global:Write-MinerData2;
        $Hash = $Data.Miners
        try {
            for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) { 
                $GPU = $Devices[$global:i]; $global:GPUHashrates.$(Global:Get-GPUs) = [Double]$Hash.$GPU.solver.solution_rate / 1000
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