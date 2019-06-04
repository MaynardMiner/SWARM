function Global:Get-StatsMiniz {
    try { $Request = Invoke-WebRequest "http://$($global:Server):$global:Port" -UseBasicParsing -TimeoutSec 10 }catch { }
    if ($Request) {
        $Data = $Request.Content -split " "
        $Hash = $Data | Select-String "Sol/s" | Select-String "data-label" | ForEach-Object { $_ -split "</td>" | Select-Object -First 1 } | ForEach-Object { $_ -split ">" | Select-Object -Last 1 }
        $global:RAW = $Hash | Select-Object -Last 1
        Global:Write-MinerData2;
        $global:GPUKHS += [Double]$global:BRAW / 1000
        $Shares = $Data | Select-String "Shares" | Select-Object -Last 1 | ForEach-Object { $_ -split "</td>" | Select-Object -First 1 } | ForEach-Object { $_ -split ">" | Select-Object -Last 1 }
        try { 
            for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) { 
                $global:GPUHashrates.$(Global:Get-GPUs) = (Global:Set-Array $Hash $global:i) / 1000 
            } 
        }
        catch { Write-Host "Failed To parse Threads" -ForegroundColor Red };
        $global:MinerACC += $Shares -split "/" | Select-Object -first 1
        $global:MinerREJ += $Shares -split "/" | Select-Object -Last 1
        $global:ALLACC += $global:MinerACC
        $global:ALLREJ += $global:MinerREJ
    }
    else { Global:Set-APIFailure; break }
}