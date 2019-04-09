function Get-StatsCpuminer {
    $GetCPUSUmmary = $Null; $GetCPUSummary = Get-TCP -Server $Server -Port $Port -Message "summary"
    if ($GetCPUSummary) {
        $CPUSUM = $GetCPUSummary -split ";" | Select-String "KHS=" | ForEach-Object { $_ -replace ("KHS=", "") }
        $global:BCPURAW = [double]$CPUSUM * 1000
        Write-MinerData2
    }
    else { Write-Host "API Summary Failed- Could Not Total Hashrate" -Foreground Red; $global:BCPURAW = 0; $global:BCPURAW | Set-Content ".\build\txt\$MinerType-hash.txt" }
    $GetCPUThreads = $Null
    $GetCPUThreads = Get-TCP -Server $Server -Port $Port -Message "threads"
    if ($GetCPUThreads) {
        $Data = $GetCPUThreads -split "\|"
        $kilo = $false
        $KHash = $Data | Select-String "kH/s"
        if ($KHash) { $Hash = $Data -split ";" | Select-String "kH/s"; $kilo = $true }
        else { $Hash = $Data -split ";" | Select-String "H/s"; $kilo = $false }
        $Hash = $Hash | ForEach-Object { $_ -split "=" | Select-Object -Last 1 }
        $J = $Hash | ForEach-Object { Invoke-Expression $_ }
        $CPUHash = @()
        if ($kilo -eq $true) {
            $global:BCPUKHS = 0
            if ($Hash) { for ($i = 0; $i -lt $Devices.Count; $i++) { $GPU = $Devices[$i]; $global:CPUHashrates.$($GCount.$TypeS.$GPU) = $(if ($J.Count -eq 1) { $J }else { $J[$i] }) } }
            $J | ForEach-Object { $global:BCPUKHS += $_ }
        }
        else {
            $global:BCPUKHS = 0
            if ($Hash) { for ($i = 0; $i -lt $Devices.Count; $i++) { $GPU = $Devices[$i]; $global:CPUHashrates.$($GCount.$TypeS.$GPU) = $(if ($J.Count -eq 1) { $J / 1000 }else { $J[$i] / 1000 }) } }
            $J | ForEach-Object { $global:BCPUKHS += $_ }
        }
        $global:CPUHashrates | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $CPUHash += "CPU=$($global:CPUHashrates.$_)" }
        $global:BCPUACC = $GetCPUSummary -split ";" | Select-String "ACC=" | ForEach-Object { $_ -replace ("ACC=", "") }
        $global:BCPUREJ = $GetCPUSummary -split ";" | Select-String "REJ=" | ForEach-Object { $_ -replace ("REJ=", "") }
        $global:BCPUUPTIME = $GetCPUSummary -split ";" | Select-String "UPTIME=" | ForEach-Object { $_ -replace ("UPTIME=", "") }
        switch ($MinerType) {
            "NVIDIA1" { $global:BALGO.Add("Main", $global:BHiveAlgo); $global:TALGO.Add("Main", $MinerAlgo) }
            "AMD1" { $global:BALGO.Add("Main", $global:BHiveAlgo); $global:TALGO.Add("Main", $MinerAlgo) }
            default { $global:BALGO.Add($MinerType, $global:BHiveAlgo); $global:TALGO.Add($MinerType, $MinerAlgo) }
        }
        $CPUTEMP = $GetCPUSummary -split ";" | Select-String "TEMP=" | ForEach-Object { $_ -replace ("TEMP=", "") }
        $CPUFAN = $GetCPUSummary -split ";" | Select-String "FAN=" | ForEach-Object { $_ -replace ("FAN=", "") }
    }
    else { Write-Host "API Threads Failed- Could Not Get Individual GPU Information" -Foreground Red }
}