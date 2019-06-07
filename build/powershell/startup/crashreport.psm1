function Global:Start-CrashReporting {
    if ($(arg).Platform -eq "windows") { Get-CimInstance -ClassName win32_operatingsystem | Select-Object lastbootuptime | ForEach-Object { $Boot = [math]::Round(((Get-Date) - $_.LastBootUpTime).TotalSeconds) } }
    elseif ($(arg).Platform -eq "linux") { $Boot = Get-Content "/proc/uptime" | ForEach-Object { $_ -split " " | Select-Object -First 1 } };
    if ([Double]$Boot -lt 600) {
        if ((Test-Path ".\build\txt") -and (Test-Path ".\logs")) {
            Write-Warning "SWARM was started in 600 seconds of last boot. Generating a crash report to logs directory";
            $Report = "crash_report_$(Get-Date)";
            $Report = $Report | ForEach-Object { $_ -replace ":", "_" } | ForEach-Object { $_ -replace "\/", "-" } | ForEach-Object { $_ -replace " ", "_" };
            New-Item -Path ".\logs" -Name $Report -ItemType "Directory" | Out-Null;
            Get-ChildItem ".\build\txt" | Copy-Item -Destination ".\logs\$Report";
            $TypeLogs = @("NVIDIA1", "AMD1", "NVIDIA2", "NVIDIA3", "CPU")
            Get-ChildItem "logs" | Where BaseName -in $TypeLogs | Foreach-Object { Copy-Item -Path $_.FullName -Destination ".\logs\$Report" | Out-Null }
            Get-ChildItem "logs" | Where BaseName -like "*miner*" | Foreach-Object { Copy-Item -Path $_.FullName -Destination ".\logs\$Report" | Out-Null }
            Start-Sleep -S 3
        }
    }
}
