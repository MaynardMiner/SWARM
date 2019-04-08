function Get-StatsCcminer {
    $global:HS = "khs"
    $Request = $Null; $Request = Get-TCP -Server $Server -Port $port -Message "summary"
    if ($Request) {
        Write-Host "MinerName is $MinerName"
        switch ($MinerName) {
            "zjazz_cuda.exe" {if ($MinerAlgo -eq "cuckoo") {$Multiplier = 2000000}else {$Multiplier = 1000}}
            "zjazz_cuda" {if ($MinerAlgo -eq "cuckoo") {$Multiplier = 2000000}else {$Multiplier = 1000}}
            "zjazz_amd.exe" {if ($MinerAlgo -eq "cuckoo") {$Multiplier = 2000000}else {$Multiplier = 1000}}
            "zjazz_amd" {if ($MinerAlgo -eq "cuckoo") {$Multiplier = 2000000}else {$Multiplier = 1000}}
            default {$Multiplier = 1000}
        }
        Write-Host "Multiplier is $Multiplier"
        try {$GetKHS = $Request -split ";" | ConvertFrom-StringData -ErrorAction Stop}catch {Write-Warning "Failed To Get Summary"}
        $global:BRAW = if ([Double]$GetKHS.KHS -ne 0 -or [Double]$GetKHS.ACC -ne 0) {[Double]$GetKHS.KHS * $Multiplier}
        Write-MinerData2;
        $global:BKHS += if ([Double]$GetKHS.KHS -ne 0 -or [Double]$GetKHS.ACC -ne 0) {[Double]$GetKHS.KHS}
    }
    else {Set-APIFailure; break}
    $GetThreads = $Null; $GetThreads = Get-TCP -Server $Server -Port $port -Message "threads"
    if ($GetThreads) {
        $Data = $null; $Data = $GetThreads -split "\|"
        $Hash = $Null; $Hash = $Data -split ";" | Select-String "KHS" | foreach {$_ -replace ("KHS=", "")}
        try {for ($i = 0; $i -lt $Devices.Count; $i++) {$global:GPUHashrates.$(Get-Gpus) = Set-Array $Hash $i}}catch {Write-Host "Failed To parse Threads" -ForegroundColor Red};
        try {$global:BMinerACC += $Request -split ";" | Select-String "ACC=" | foreach {$_ -replace ("ACC=", "")}}catch {}
        try {$global:BMinerREJ += $Request -split ";" | Select-String "REJ=" | foreach {$_ -replace ("REJ=", "")}}catch {}
        try {$global:BACC += $Request -split ";" | Select-String "ACC=" | foreach {$_ -replace ("ACC=", "")}}catch {}
        try {$global:BREJ += $Request -split ";" | Select-String "REJ=" | foreach {$_ -replace ("REJ=", "")}}catch {}
        $global:BALGO.Add($MinerType,$MinerAlgo)
        $global:BUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
    }
    else {Write-Host "API Threads Failed"; break}
}