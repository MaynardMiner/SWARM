function Global:Get-StatsMultiminer {
    $GetSummary = Global:Get-TCP -Server $global:Server -Port $global:Port -Message "summary"
    if ($GetSummary) {
        $SUM = $GetSummary -split ";" | Select-String "KHS=" | ForEach-Object { $_ -replace ("KHS=", "") }
        $global:RAW = [double]$SUM * 1000
        Global:Write-MinerData2
    }
    else { Write-Host "API Summary Failed- Could Not Total Hashrate" -Foreground Red; break }
    $GetThreads = Global:Get-TCP -Server $global:Server -Port $global:Port -Message "threads"
    if ($GetThreads) {
        $Data = $GetThreads -split "\|"
        $kilo = $false
        $KHash = $Data | Select-String "kH/s"
        if ($KHash) { $Hash = $Data -split ";" | Select-String "kH/s"; $kilo = $true }
        else { $Hash = $Data -split ";" | Select-String "H/s"; $kilo = $false }
        $Hash = $Hash | ForEach-Object { $_ -split "=" | Select-Object -Last 1 }
        $J = $Hash | ForEach-Object { Invoke-Expression [Double]$_ }
        if ($kilo -eq $true) {
            if ($Hash) { 
                for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) { $global:GPUHashrates.$(Global:Get-GPUs) = (Global:Set-Array $Hash $global:i) }
            }
            $J | ForEach-Object { $global:CPUKHS += $_ }
        }
        else {
            if ($Hash) { 
                for ($global:i = 0; $global:i -lt $Devices.Count; $global:i++) { $global:GPUHashrates.$(Global:Get-GPUs) = (Global:Set-Array $Hash $global:i) / 1000 } 
            }
            $J | ForEach-Object { $global:GPUKHS += $_ }
        }
        $global:MinerACC = $GetSummary -split ";" | Select-String "ACC=" | ForEach-Object { $_ -replace ("ACC=", "") }
        $global:MinerREJ = $GetSummary -split ";" | Select-String "REJ=" | ForEach-Object { $_ -replace ("REJ=", "") }
        $global:ALLACC += $global:MinerACC
        $global:ALLREJ += $global:MinerREJ
    }
    else { Write-Host "API Threads Failed- Could Not Get Individual GPU Information" -Foreground Red }
}