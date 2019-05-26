function Start-CrashReporting {
    if ($global:Config.Params.Platform -eq "windows") { Get-CimInstance -ClassName win32_operatingsystem | Select-Object lastbootuptime | ForEach-Object { $Boot = [math]::Round(((Get-Date) - $_.LastBootUpTime).TotalSeconds) } }
    elseif ($global:Config.Params.Platform -eq "linux") { $Boot = Get-Content "/proc/uptime" | ForEach-Object { $_ -split " " | Select-Object -First 1 } };
    if ([Double]$Boot -lt 600) {
        if ((Test-Path ".\build\txt") -and (Test-Path ".\logs")) {
            Write-Warning "SWARM was started in 600 seconds of last boot. Generating a crash report to logs directory";
            $Report = "crash_report_$(Get-Date)";
            $Report = $Report | ForEach-Object { $_ -replace ":", "_" } | ForEach-Object { $_ -replace "\/", "-" } | ForEach-Object { $_ -replace " ", "_" };
            New-Item -Path ".\logs" -Name $Report -ItemType "Directory" | Out-Null;
            Get-ChildItem ".\build\txt" | Copy-Item -Destination ".\logs\$Report";
            $TypeLogs = @("NVIDIA1", "AMD1", "NVIDIA2", "NVIDIA3", "CPU", "ASIC")
            $TypeLogs | ForEach-Object { $TypeLog = ".\logs\$($_).log"; if (Test-Path $TypeLog) { Copy-Item -Path $TypeLog -Destination ".\logs\$Report" | Out-Null } }
            $ActiveLog = Get-ChildItem "logs"; $ActiveLog = $ActiveLog.Name | Select-String "active"
            if ($ActiveLog) { if (Test-Path ".\logs\$ActiveLog") { Copy-Item -Path ".\logs\$ActiveLog" -Destination ".\logs\$Report" | Out-Null } }
            Start-Sleep -S 3
        }
    }
}
