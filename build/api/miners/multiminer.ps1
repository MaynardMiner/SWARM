function Get-StatsMultiminer {
    $GetSummary = Get-TCP -Server $Server -Port $Port -Message "summary"
    if ($GetSummary) {
        $SUM = $GetSummary -split ";" | Select-String "KHS=" | ForEach-Object { $_ -replace ("KHS=", "") }
        $global:RAW = [double]$SUM * 1000
        Write-MinerData2
    }
    else { Write-Host "API Summary Failed- Could Not Total Hashrate" -Foreground Red; break }
    $GetThreads = Get-TCP -Server $Server -Port $Port -Message "threads"
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
                for ($i = 0; $i -lt $Devices.Count; $i++) { $global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i) }
            }
            $J | ForEach-Object { $global:CPUKHS += $_ }
        }
        else {
            if ($Hash) { 
                for ($i = 0; $i -lt $Devices.Count; $i++) { $global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i) / 1000 } 
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