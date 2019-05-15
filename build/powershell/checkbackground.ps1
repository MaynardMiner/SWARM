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
function Start-Background {
  
    $BackgroundTimer = New-Object -TypeName System.Diagnostics.Stopwatch
    $command = Start-Process "pwsh" -WorkingDirectory "$($global:Dir)\build\powershell" -ArgumentList "-executionpolicy bypass -NoExit -windowstyle minimized -command `"&{`$host.ui.RawUI.WindowTitle = `'Background Agent`'; &.\Background.ps1 -WorkingDir `'$($global:Dir)`'}`"" -WindowStyle Minimized -PassThru -Verb Runas
    $command.ID | Set-Content ".\build\pid\background_pid.txt"
    $BackgroundTimer.Restart()
    do {
        Start-Sleep -S 1
        write-log "Getting Process ID for Background Agent"
        $ProcessId = if (Test-Path ".\build\pid\background_pid.txt") {Get-Content ".\build\pid\background_pid.txt"}
        if ($ProcessID -ne $null) {$Process = Get-Process $ProcessId -ErrorAction SilentlyContinue}
    }until($ProcessId -ne $null -or ($BackgroundTimer.Elapsed.TotalSeconds) -ge 10)  
    $BackgroundTimer.Stop()
}

function Start-BackgroundCheck {

    if ($global:Config.Params.Platform -eq "windows") {
        $oldbackground = ".\build\pid\background_pid.txt"
        if (Test-Path $oldbackground) {
            $bprocess = Get-Content $oldbackground
            if (Get-Process -id $bprocess -ErrorAction SilentlyContinue) {Stop-Process -id $bprocess; remove-item $oldbackground}
        }
    }
    elseif ($global:Config.Params.Platform -eq "linux") {
        Start-Process ".\build\bash\killall.sh" -ArgumentList "background" -Wait
        Start-Sleep -S .25
        Start-Process "screen" -ArgumentList "-S background -d -m" -Wait
        Start-Sleep -S .25
        Start-Process ".\build\bash\background.sh" -ArgumentList "background $Global:Dir" -Wait
    }
}