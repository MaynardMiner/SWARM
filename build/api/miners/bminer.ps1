function Get-StatsBminer {
    $Request = $Null; $Request = Get-HTTP -Port $Port -Message "/api/status"
    if ($Request) {
        try {$Data = $Null; $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop; }catch {Write-Host "Failed To parse API" -ForegroundColor Red}
        for ($i = 0; $i -lt $Devices.Count; $i++) {$GPU = $Devices[$i]; $global:BRAW += [Double]$Data.Miners.$GPU.solver.solution_rate}
        Write-MinerData2;
        $Hash = $Null; $Hash = $Data.Miners
        if ($global:HS -eq "hs") {$HashFactor = 1}
        if ($global:HS -eq "khs") {$Hashfactor = 1000}
        try {for ($i = 0; $i -lt $Devices.Count; $i++) {$GPU = $Devices[$i]; $global:GPUHashrates.$(Get-Gpus) = [Double]$Hash.$GPU.solver.solution_rate / 1000}}catch {Write-Host "Failed To parse Threads" -ForegroundColor Red};
        $Data.stratum.accepted_shares | Foreach {$global:BMinerACC += $_}
        $Data.stratum.rejected_shares | Foreach {$global:BMinerREJ += $_}
        $Data.stratum.accepted_shares | Foreach {$global:BACC += $_}
        $Data.stratum.rejected_shares | Foreach {$global:BREJ += $_}
        for ($i = 0; $i -lt $Devices.Count; $i++) {$GPU = $Devices[$i]; $global:BKHS += [Double]$Data.Miners.$GPU.solver.solution_rate / 1000}
        $global:BUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
        $global:BALGO += "$MinerAlgo"
    }
    else {Set-APIFailure; break}
}