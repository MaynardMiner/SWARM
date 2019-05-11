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

Set-Location (Split-Path (Split-Path (Split-Path $script:MyInvocation.MyCommand.Path)))

. .\build\powershell\killall.ps1;
[cultureinfo]::CurrentCulture = 'en-US'
$MinerContent = Get-Content ".\build\pid\miner_pid.txt"


While ($true) {
       $Title = "SWARM"
        Write-Host "Checking To See if SWARM Is Running"
            if ($MinerContent -ne $null) {
                Write-Host "Miner Name is $Title"
                Write-Host "Miner Process Id is Currently $($MinerContent)" -foregroundcolor yellow
                $MinerProcess = Get-Process -Id $MinerContent -ErrorAction SilentlyContinue
                if ($MinerProcess -ne $null -or $MinerProcess.HasExited -eq $false) {
                    Write-Host "$($Title) Status: Is Currently Running" -foregroundcolor green
                }
                else {
                    Write-Host "Closing SWARM" -foregroundcolor red
                    Get-Date | Out-File ".\build\data\timetable.txt"
                    Clear-Content ".\build\txt\hivestats.txt"
                    $Miners = Get-ChildItem ".\build\pid"
                    start-killscript
                    Start-Process ".\build\bash\killall.sh" -ArgumentList "pidinfo" -Wait
                }
            }
    Start-Sleep -S 3.75
}

  
