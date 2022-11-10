function Global:Get-StatsSrbcpu {
    $Request = Global:Get-HTTP -Server $global:Server -Port $global:Port
    if ($Request) {
        try { $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop }
        Catch { Write-Host "Failed To parse API" -ForegroundColor Red; Break }
        if ($Data) {
            $global:RAW += $Data.algorithms.hashrate.'1min';
            $global:CPUKHS = $Data.algorithms.hashrate.'1min' / 1000
            Global:Write-MinerData2;
            catch { Write-Host "Failed To parse Threads" -ForegroundColor Red };
            $global:MinerACC = $Data.algorithms.shares.accepted; $global:ALLACC += $Data.algorithms.shares.accepted 
            $global:MinerREJ = $Data.algorithms.shares.rejected; $global:ALLREJ += $Data.algorithms.shares.rejected
        }
    }
    else { Global:Set-APIFailure }
}
