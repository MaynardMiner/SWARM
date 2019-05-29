function Get-DateFiles {
    param (
        [Parameter(Mandatory = $false)]
        [String]$CmdDir
    )
    
    if (Test-Path ".\build\pid") {Remove-Item ".\build\pid\*" -Force | Out-Null}
    else {New-Item -Path ".\build" -Name "pid" -ItemType "Directory" | Out-Null}
    Start-Sleep -S 1
    $PID | Out-File ".\build\pid\miner_pid.txt"
    if ($global:Config.Params.Platform -eq "windows") { $host.ui.RawUI.WindowTitle = "SWARM"; }
}

function get-argnotice {
    if ((Test-Path ".\config\parameters\newarguments.json") -or $Debug -eq $true) {
        write-Log "Detected New Arguments- Changing Parameters" -ForegroundColor Cyan
        write-Log "These arguments can be found/modified in config < parameters < newarguments.json" -ForegroundColor Cyan
        Start-Sleep -S 2
    }    
}

function Clear-Stats {
    $FileClear = @()
    $FileClear += ".\build\txt\minerstats.txt"
    $FileClear += ".\build\txt\mineractive.txt"
    $FileClear += ".\build\bash\hivecpu.sh"
    $FileClear += ".\build\txt\profittable.txt"
    $FileClear += ".\build\txt\bestminers.txt"
    $FileClear | ForEach-Object { if (Test-Path $_) { Remove-Item $_ -Force } }
}

function Set-NewType {
    $global:Config.Params.Type | ForEach-Object {
        if ($_ -eq "amd1") { $_ = "AMD1" }
        if ($_ -eq "nvidia1") { $_ = "NVIDIA1" }
        if ($_ -eq "nvidia2") { $_ = "NVIDIA2" }
        if ($_ -eq "nvidia2") { $_ = "NVIDIA3" }
        if ($_ -eq "cpu") { $_ = "CPU" }
        if ($_ -eq "asic") { $_ = "ASIC" }
    }    
}

function get-NIST {
    $AllProtocols = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12' 
    [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
    
    $progressPreference = 'silentlyContinue'
    try {
        $WebRequest = Invoke-WebRequest -Uri 'http://nist.time.gov/actualtime.cgi' -UseBasicParsing -TimeoutSec 10
        $GetDate = $WebRequest.Content -Split "<timestamp time=`"" | Select -Last 1 | % {$_ -split "`" delay" | Select -First 1}
        $GetNIST = (Get-Date -Date '1970-01-01 00:00:00Z').AddMilliseconds([Double]$GetDate/ 1000)
    }
    Catch {
        Write-Warning "Failed To Get NIST time. Using Local Time."
        $GetNIST = Get-Date
    }
    $progressPreference = 'Continue'
    $GetNIST
}