function Get-StatsDSTM {
    $Request = $null; $Request = Get-TCP -Server $Server -Port $port -Message "summary"
    if ($Request) {
        try { $Data = $Null; $Data = $Request | ConvertFrom-Json -ErrorAction Stop; }catch { Write-Host "Failed To parse GPU Array" -ForegroundColor Red; break }
        $Data = $Data.result
        $Data.sol_ps | ForEach-Object { $global:RAW += [Double]$_; $global:GPUKHS += [Double]$_ / 1000 }
        Write-MinerData2;
        $Hash = $Data.sol_ps
        try { 
            for ($i = 0; $i -lt $Devices.Count; $i++) { 
                $global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i) / 1000 
            } 
        }
        catch { Write-Host "Failed To parse GPU Array" -ForegroundColor Red };
        $Data.rejected_shares | ForEach-Object { $global:MinerREJ += $_ }
        $Data.accepted_shares | ForEach-Object { $global:MinerACC += $_ }  
        $global:ALLACC += $global:MinerACC
        $global:ALLREJ += $global:MinerREJ
    }
    else { Set-APIFailure }
}