function Get-StatsCpuminer {
    $GetCPUSUmmary = $Null; $GetCPUSummary = Get-TCP -Server $Server -Port $Port -Message "summary"
    if ($GetCPUSummary) {
        $CPUSUM = $GetCPUSummary -split ";" | Select-String "KHS=" | foreach {$_ -replace ("KHS=", "")}
        $CPURAW = [double]$CPUSUM * 1000
        $CPURAW | Set-Content ".\build\txt\$MinerType-hash.txt"
    }
    else {Write-Host "API Summary Failed- Could Not Total Hashrate" -Foreground Red; $CPURAW = 0; $CPURAW | Set-Content ".\build\txt\$MinerType-hash.txt"}
    $GetCPUThreads = $Null
    $GetCPUThreads = Get-TCP -Server $Server -Port $Port -Message "threads"
    if ($GetCPUThreads) {
        $Data = $GetCPUThreads -split "\|"
        $kilo = $false
        $KHash = $Data | Select-String "kH/s"
        if ($KHash) {$Hash = $Data -split ";" | Select-String "kH/s"; $kilo = $true}
        else {$Hash = $Data -split ";" | Select-String "H/s"; $kilo = $false}
        $Hash = $Hash | foreach {$_ -split "=" | Select -Last 1 }
        $J = $Hash | % {iex $_}
        $CPUHash = @()
        if ($kilo -eq $true) {
            $global:BCPUKHS = 0
            if ($Hash) {for ($i = 0; $i -lt $Devices.Count; $i++) {$GPU = $Devices[$i]; $global:CPUHashrates.$($GCount.$TypeS.$GPU) = $(if ($J.Count -eq 1) {$J}else {$J[$i]})}}
            $J |Foreach {$global:BCPUKHS += $_}
            $CPUHS = "khs"
        }
        else {
            $global:BCPUKHS = 0
            if ($Hash) {for ($i = 0; $i -lt $Devices.Count; $i++) {$GPU = $Devices[$i]; $global:CPUHashrates.$($GCount.$TypeS.$GPU) = $(if ($J.Count -eq 1) {$J / 1000}else {$J[$i] / 1000})}}
            $J |Foreach {$global:BCPUKHS += $_}
            $CPUHS = "hs"
        }
        $global:CPUHashrates | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {$CPUHash += "CPU=$($global:CPUHashrates.$_)"}
        $global:BCPUACC = $GetCPUSummary -split ";" | Select-String "ACC=" | foreach {$_ -replace ("ACC=", "")}
        $global:BCPUREJ = $GetCPUSummary -split ";" | Select-String "REJ=" | foreach {$_ -replace ("REJ=", "")}
        $CPUUPTIME = $GetCPUSummary -split ";" | Select-String "UPTIME=" | foreach {$_ -replace ("UPTIME=", "")}
        $CPUALGO = $GetCPUSummary -split ";" | Select-String "ALGO=" | foreach {$_ -replace ("ALGO=", "")}
        $CPUTEMP = $GetCPUSummary -split ";" | Select-String "TEMP=" | foreach {$_ -replace ("TEMP=", "")}
        $CPUFAN = $GetCPUSummary -split ";" | Select-String "FAN=" | foreach {$_ -replace ("FAN=", "")}
    }
    else {Write-Host "API Threads Failed- Could Not Get Individual GPU Information" -Foreground Red}
}