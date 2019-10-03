<#
SWARM is open-source software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
SWARM is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>

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
