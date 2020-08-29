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

function Global:Start-Background {
    $start = [launchcode]::New()
    $FilePath = "$PSHome\pwsh.exe"
    $CommandLine = '"' + $FilePath + '"'
    $Windowstyle = "minimized"
    if ($(arg).Hidden -eq "Yes") {
        $Windowstyle = "Hidden"
    }            
    $arguments = "-executionpolicy bypass -Windowstyle $WindowStyle -command `"Set-Location $($(vars).dir); .\build\powershell\scripts\background.ps1`""
    $CommandLine += " " + $arguments
    $New_Miner = $start.New_Miner($filepath,$CommandLine,$(vars).Dir)
    $Process = Get-Process | Where-Object id -eq $New_Miner.dwProcessId
    $Process.ID | Set-Content ".\build\pid\background_pid.txt"
}

function Global:Start-AgentCheck {
    log "Stopping Previous Agent"
    $ID = ".\build\pid\background_pid.txt"
    if (Test-Path $ID) { $Agent = Get-Content $ID }
    if ($Agent) { $BackGroundID = Get-Process | Where-Object id -eq $Agent }
    if ($BackGroundID.name -eq "pwsh") { Stop-Process $BackGroundID | Out-Null }
    $ID = ".\build\pid\pill_pid.txt"
    if (Test-Path $ID) { $Agent = Get-Content $ID }
    if ($Agent) { $BackGroundID = Get-Process | Where-Object id -eq $Agent }
    if ($BackGroundID.name -eq "pwsh") { Stop-Process $BackGroundID | Out-Null }
    log "Stopping Previous Autofan"
    $ID = ".\build\pid\autofan.txt"
    if (Test-Path $ID) { $Agent = Get-Content $ID }
    if ($Agent) { $BackGroundID = Get-Process | Where-Object id -eq $Agent }
    if ($BackGroundID.name -eq "pwsh") { Stop-Process $BackGroundID | Out-Null }       
}


function Global:Get-Optional {
    Get-ChildItem ".\miners\optional_and_old" | Where-Object BaseName -in $(arg).Optional | ForEach-Object {
        $Path = $_.FullName
        $FileType = Get-Content $Path
        if ( $FileType[0] -like "*`$(vars).AMDTypes*" ) {
            $CheckA = Join-Path "$($(vars).dir)\miners\gpu\amd" $_.Name
            if (-not (Test-Path $CheckA)) { Move-Item -Path $Path -Destination ".\miners\gpu\amd" }
        }
        if ( $FileType[0] -like "*`$(vars).NVIDIATypes*" ) {
            $CheckN = Join-Path "$($(vars).dir)\miners\gpu\nvidia" $_.Name
            if (-not (Test-Path $CheckN)) { Move-Item -Path $Path -Destination ".\miners\gpu\nvidia" }
        }
    }
    ## Move Out Additional Miners
    if ($IsLinux) {
        $AMD = Get-Content ".\config\update\amd-linux.json" | ConvertFrom-Json 
        $AMD = $AMD | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object { $AMD.$_.optional -eq "Yes" } | ForEach-Object { $AMD.$_ }
        $NVIDIA = Get-Content ".\config\update\nvidia-linux.json" | ConvertFrom-Json
        $NVIDIA = $NVIDIA | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object { $NVIDIA.$_.optional -eq "Yes" } | ForEach-Object { $NVIDIA.$_ }
    }
    else {
        $AMD = Get-Content ".\config\update\amd-win.json" | ConvertFrom-Json
        $AMD = $AMD | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object { $AMD.$_.optional -eq "Yes" } | ForEach-Object { $AMD.$_ }
        $NVIDIA = Get-Content ".\config\update\nvidia-win.json" | ConvertFrom-Json
        $NVIDIA = $NVIDIA | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object { $NVIDIA.$_.optional -eq "Yes" } | ForEach-Object { $NVIDIA.$_ }
    }
    ##AMD
    if ($(arg).Type -like "*AMD*") {
        $list = Get-ChildItem ".\miners\gpu\amd"
        $AMD | ForEach-Object {
            if ($_.Name -in $list.basename -and $_.Name -notin $(arg).optional) {
                Write-Log "Found $($_.Name) in active miner folder, not specified in -optional parameter, moving to optional_and_old" -ForegroundColor Yellow
                $file = $List | Where-Object BaseName -eq $($_.Name)
                Move-Item -path $file -Destination ".\miners\optional_and_old\$($_.Name).ps1" -Force
            }
        }
    }
    ##NVIDIA
    if ($(arg).Type -like "*NVIDIA*") {
        $list = Get-ChildItem ".\miners\gpu\nvidia"
        $NVIDIA | ForEach-Object {
            if ($_.Name -in $list.basename -and $_.Name -notin $(arg).optional) {
                Write-Log "Found $($_.Name) in active miner folder, not specified in -optional parameter, moving to optional_and_old" -ForegroundColor Yellow
                $file = $List | Where-Object BaseName -eq $($_.Name)
                Move-Item -path $file -Destination ".\miners\optional_and_old\$($_.Name).ps1" -Force
            }
        }
    }
}