function Get-StatsDSTM {
    $global:HS = "hs"
    $Request = $Null; $Request = $null; $Request = Get-TCP -Server $Server -Port $port -Message "summary"
    if ($Request) {
        try { $Data = $Null; $Data = $Request | ConvertFrom-Json -ErrorAction Stop; }catch { Write-Host "Failed To parse GPU Array" -ForegroundColor Red }
        $Data = $Data.result
        $Data.sol_ps | ForEach-Object { $global:BRAW += [Double]$_ }
        Write-MinerData2;
        $Hash = $Null; $Hash = $Data.sol_ps
        try { for ($i = 0; $i -lt $Devices.Count; $i++) { $global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i) / 1000 } }catch { Write-Host "Failed To parse GPU Array" -ForegroundColor Red };
        $Data.rejected_shares | ForEach-Object { $global:BMinerREJ += $_ }
        $Data.accepted_shares | ForEach-Object { $global:BMinerACC += $_ }  
        $Data.rejected_shares | ForEach-Object { $global:BREJ += $_ }
        $Data.accepted_shares | ForEach-Object { $global:BACC += $_ }
        $Data.sol_ps | ForEach-Object { $global:BKHS += [Double]$_ }
        if ($MinerType -eq "NVIDIA1" -or $MinerType -eq "AMD1") { $global:BALGO.Add("Main", $global:BHiveAlgo) }
        else { $global:BALGO.Add($MinerType, $global:BHiveAlgo) }
        if ($MinerType -eq "NVIDIA1" -or $MinerType -eq "AMD1") { $global:TALGO.Add("Main", $MinerAlgo) }
        else { $global:TALGO.Add($MinerType, $MinerAlgo) }
        $global:BUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
    }
    else { Set-APIFailure; break }
}