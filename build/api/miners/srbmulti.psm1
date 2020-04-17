function Global:Get-StatsSrbmulti {
    $Request = Global:Get-HTTP -Server $global:Server -Port $global:Port
    if ($Request) {
        try { $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop }
        Catch { Write-Host "Failed To parse API" -ForegroundColor Red; Break }
        if ($Data) {
            $global:RAW += $Data.hashrate_total_1min;
            $Hash = @()
            Global:Write-MinerData2;
            $Data.gpu_hashrate | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                if($_ -ne "total") {
                    $Hash += $Data.gpu_hashrate.$_
                }
            }
            
            try {
                for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) { 
                    $global:GPUHashrates.$(Global:Get-GPUs) = (Global:Set-Array $Hash $global:i) / 1000 
                }
            }
            catch { Write-Host "Failed To parse Threads" -ForegroundColor Red };
            $global:MinerACC = $Data.shares.accepted; $global:ALLACC += $Data.shares.accepted 
            $global:MinerREJ = $Data.shares.rejected; $global:ALLREG += $Data.shares.accepted
            $Hash | ForEach-Object { $global:GPUKHS += [Double]$_ / 1000 }
        }
    }
    else { Global:Set-APIFailure }
}
