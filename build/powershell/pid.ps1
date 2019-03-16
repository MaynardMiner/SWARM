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

param(
    [Parameter(Mandatory = $true)]
    [Array]$Name
)

. .\build\powershell\killall.ps1;

While ($true) {
    $Name | foreach {
        if ($_ -eq "miner") {$Title = "SWARM"}
        else {$Title = "$($_)"}
        Write-Host "Checking To See if Miner $($_) Is Running"
        $MinerPIDPath = ".\build\pid\$($_)_pid.txt"
        if ($MinerPIDPath) {
            $MinerContent = Get-Content ".\build\\pid\$($_)_pid.txt"
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
                    $Miners = Get-ChildItem ".\build\pid.txt"
                    $Miners.Name | % {
                     if($_ -like "*info*")
                      {
                        $Info = Get-Content ".\build\pid\$($_)" | ConvertFrom-Json
                        $Exec = Split-Path $Info.miner_exec -Leaf
                        Start-Process "start-stop-daemon" -ArgumentList "--stop --name $Exec --pidfile $($Info.pid_path) --retry 5" -Wait
                      }
                    }
                    start-killscript
                }
            }
        }
        else {
            Write-Host "Closing SWARM" -foregroundcolor red
            Get-Date | Out-File ".\build\data\timetable.txt"
            Clear-Content ".\build\txt\hivestats.txt"
            $Miners = Get-ChildItem ".\build\pid.txt"
            $Miners.Name | % {
             if($_ -like "*info*")
              {
                $Info = Get-Content ".\build\pid\$($_)" | ConvertFrom-Json
                $Exec = Split-Path $Info.miner_exec -Leaf
                Start-Process "start-stop-daemon" -ArgumentList "--stop --name $Exec --pidfile $($Info.pid_path) --retry 5" -Wait
              }
            }
            start-killscript
        }
    }
    Start-Sleep -S 3.75
}

  
