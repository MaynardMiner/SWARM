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

function Start-LaunchCode {

    param(
        [Parameter(Mandatory = $true)]
        [String]$Platforms,
        [Parameter(Mandatory = $true)]
        [String]$NewMiner,
        [Parameter(Mandatory = $true)]
        [String]$MinerRound,
        [Parameter(Mandatory = $false)]
        [String]$PP
    ) 

    $MinerCurrent = $NewMiner | ConvertFrom-Json
    $BestMiners = $MinerRound | ConvertFrom-Json
    $MinerTimer = New-Object -TypeName System.Diagnostics.Stopwatch
    $Export = (Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) "build\export")  
    ##Remove Old PID FIle
    $PIDMiners = "$($MinerCurrent.Type)"
    if (Test-Path ".\build\pid\*$PIDMiners*") {Remove-Item ".\build\pid\*$PIDMiners*"}
    if (Test-Path ".\build\*$($MinerCurrent.Type)*-hash.txt") {Clear-Content ".\build\*$($MinerCurrent.Type)*-hash.txt"}

    switch -WildCard ($MinerCurrent.Type) {
        "*NVIDIA*" {
            if ($MinerCurrent.Devices -ne $null) {
                switch ($MinerCurrent.DeviceCall) {
                    "ccminer" {$MinerArguments = "-d $($MinerCurrent.Devices) $($MinerCurrent.Arguments)"}
                    "ewbf" {$MinerArguments = "--cuda_devices $($MinerCurrent.Devices) $($MinerCurrent.Arguments)"}
                    "miniz" {$MinerArguments = "--cuda-devices $($MinerCurrent.Devices) $($MinerCurrent.Arguments)"}
                    "energiminer" {$MinerArguments = "--cuda-devices $($MinerCurrent.Devices) $($MinerCurrent.Arguments)"}
                    "gminer" {$MinerArguments = "-d $($MinerCurrent.Devices) $($MinerCurrent.Arguments)"}
                    "dstm" {$MinerArguments = "--dev $($MinerCurrent.Devices) $($MinerCurrent.Arguments)"}
                    "claymore" {$MinerArguments = "-di $($MinerCurrent.Devices) $($MinerCurrent.Arguments)"}
                    "trex" {$MinerArguments = "-d $($MinerCurrent.Devices) $($MinerCurrent.Arguments)"}
                    "bminer" {$MinerArguments = "-devices $($MinerCurrent.Devices) $($MinerCurrent.Arguments)"}
                    "lolminer" {$MinerArguments = "--devices $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
                    "zjazz" {
                        $GetDevices = $($MinerCurrent.Devices) -split ","
                        $GetDevices | foreach {$LaunchDevices += "-d $($_) "}         
                        $MinerArguments = "$LaunchDevices$($MinerCurrent.Arguments)"
                    }
                    "excavator" {
                        $MinerDirectory = Split-Path ($MinerCurrent.Path)
                        $MinerArguments = "-c command.json -p $($MinerCurrent.Port)"
                        set-nicehash $($MinerCurrent.NPool) 3200 $($MinerCurrent.NUser) $($MinerCurrent.Algo) $($MinerCurrent.CommandFile) "$($MinerCurrent.Devices)" "$($MinerCurrent.NCommands)"
                    }
                }
            }
            else {
                if ($MinerCurrent.DeviceCall -eq "excavator") {
                    $MinerDirectory = Split-Path ($MinerCurrent.Path) -Parent
                    $CommandFilePath = Join-Path $dir "$($MinerDirectory)\command.json"
                    $MinerArguments = "-c command.json -p $($MinerCurrent.Port)"
                    $NHDevices = Get-Content ".\build\txt\devicelist.txt" | ConvertFrom-Json
                    $NiceDevices = Get-DeviceString -TypeCount $NHDevices.NVIDIA.Count
                    set-nicehash $($MinerCurrent.NPool) 3200 $($MinerCurrent.NUser) $($MinerCurrent.Algo) $($MinerCurrent.CommandFile) "$NiceDevices"
                }
                else {$MinerArguments = "$($MinerCurrent.Arguments)"}
            }
        }

        "*AMD*" {
            if ($MinerCurrent.Devices -ne $null) {   
                switch ($MinerCurrent.DeviceCall) {
                    "claymore" {$MinerArguments = "-di $($MinerCurrent.Devices) $($MinerCurrent.Arguments)"}
                    "xmrstak" {$MinerArguments = "$($MinerCurrent.Arguments)"}
                    "sgminer-gm" {Write-Host "Miner Has Devices"; $MinerArguments = "-d $($MinerCurrent.Devices) $($MinerCurrent.Arguments)"}
                    "tdxminer" {$MinerArguments = "-d $($MinerCurrent.Devices) $($MinerCurrent.Arguments)"}
                    "lolminer" {$MinerArguments = "--devices $($MinerCurrent.Devices) $($MinerCurrent.Arguments)"}
                    "wildrig" {$MinerArguments = "$($MinerCurrent.Arguments)"}        
                    "lyclminer" {
                        $MinerArguments = ""
                        Set-Location (Split-Path $($MinerCurrent.Path))
                        $ConfFile = Get-Content ".\lyclMiner.conf" -Force
                        $Connection = $MinerCurrent.Connection
                        $Username = $MinerCurrent.Username
                        $Password = $MinerCurrent.Password
                        $NewLines = $ConfFile | ForEach {
                            if ($_ -like "*<Connection Url =*") {$_ = "<Connection Url = `"stratum+tcp://$Connection`""}
                            if ($_ -like "*Username =*") {$_ = "            Username = `"$Username`"    "}
                            if ($_ -like "*Password =*" ) {$_ = "            Password = `"$Password`">    "}
                            if ($_ -notlike "*<Connection Url*" -or $_ -notlike "*Username*" -or $_ -notlike "*Password*") {$_}
                        }
                        Clear-Content ".\lyclMiner.conf" -force
                        $NewLines | Set-Content ".\lyclMiner.conf"
                        Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
                    }           
                }
            }
            else {
                if ($MinerCurrent.DeviceCall -eq "lyclminer") {
                    $MinerArguments = ""
                    Set-Location (Split-Path $($MinerCurrent.Path))
                    $ConfFile = Get-Content ".\lyclMiner.conf" -Force
                    $Connection = $MinerCurrent.Connection
                    $Username = $MinerCurrent.Username
                    $Password = $MinerCurrent.Password
                    $NewLines = $ConfFile | ForEach {
                        if ($_ -like "*<Connection Url =*") {$_ = "<Connection Url = `"stratum+tcp://$Connection`""}
                        if ($_ -like "*Username =*") {$_ = "            Username = `"$Username`"    "}
                        if ($_ -like "*Password =*" ) {$_ = "            Password = `"$Password`">    "}
                        if ($_ -notlike "*<Connection Url*" -or $_ -notlike "*Username*" -or $_ -notlike "*Password*") {$_}
                    }
                    Clear-Content ".\lyclMiner.conf" -force
                    $NewLines | Set-Content ".\lyclMiner.conf"
                    Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
                }
                else {$MinerArguments = "$($MinerCurrent.Arguments)"}
            }
        }  
      
        "*CPU*" {
            if ($MinerCurrent.Devices -eq '') {$MinerArguments = "$($MinerCurrent.Arguments)"}
            elseif ($MinerCurrent.DeviceCall -eq "cpuminer-opt") {$MinerArguments = "-t $($MinerCurrent.Devices) $($MinerCurrent.Arguments)"}
            elseif ($MinerCurrent.DeviceCall -eq "cryptozeny") {$MinerArguments = "-t $($MinerCurrent.Devices) $($MinerCurrent.Arguments)"}
            elseif ($MinerCurrent.DeviceCall -eq "xmrstak-opt") {$MinerArguments = "$($MinerCurrent.Devices) $($MinerCurrent.Arguments)"}
        }
    }

    switch($MinerCurrent.name)
    {
     "gminer"{Write-Host "WARNING: SOME ALGOS MAY REQUIRE 6GB VRAM TO WORK" -ForegroundColor Green}
     "bminer"{Write-Host "WARNING: SOME ALGOS MAY REQUIRE 6GB VRAM TO WORK" -ForegroundColor Green}
    }

    if ($Platforms -eq "windows") {
        if ($MinerProcess -eq $null -or $MinerProcess.HasExited -eq $true) {
            Start-Sleep -S $MinerCurrent.Delay
            $Logs = Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) "logs\$($MinerCurrent.Type).log" 
            $WorkingDirectory = Split-Path $($MinerCurrent.Path)
            if (Test-Path $Logs) {Clear-Content $Logs -ErrorAction SilentlyContinue}
            $script = @()
            $script += "`$OutputEncoding = [System.Text.Encoding]::ASCII"
            $script += ". `"$dir\build\powershell\output.ps1`";"
            $script += "$dir\build\powershell\icon.ps1 `"$dir\build\apps\miner.ico`"" 
            $script += "`$host.ui.RawUI.WindowTitle = ""$($MinerCurrent.Name)"";"
            $MinerCurrent.Prestart | foreach {
                if ($_ -notlike "export LD_LIBRARY_PATH=$dir\build\export") {
                    $setx = $_ -replace "export ", "setx "
                    $setx = $setx -replace "=", " "
                    $script += "$setx"
                }
            }
            if (-not (Test-Path "$WorkingDirectory\swarm-start.bat")) {
                $minerbat = @()
                $minerbat += "CMD /r powershell -ExecutionPolicy Bypass -command `".\swarm-start.ps1`""
                $minerbat += "cmd.exe"
                $miner_bat = Join-Path $WorkingDirectory "swarm-start.bat"
                $minerbat | Set-Content $miner_bat
            }
            $script += "Invoke-Expression `'.\$($MinerCurrent.MinerName) $($MinerArguments) 2>&1 | %{`$Output = `$_ -replace `"\\[\d+(;\d+)?m`"; `$OutPut | Out-File -FIlePath ""$Logs"" -Append; `$_ | Out-Host}`'"
            $script | out-file "$WorkingDirectory\swarm-start.ps1"
            Start-Sleep -S .5

            $Job = Start-Job -ArgumentList $PID, $WorkingDirectory {
                param($ControllerProcessID, $WorkingDirectory)
                Set-Location $WorkingDirectory
                $ControllerProcess = Get-Process -Id $ControllerProcessID
                if ($ControllerProcess -eq $null) {return}
                $Process = Start-Process "CMD" -ArgumentList "/c powershell.exe -executionpolicy bypass -command "".\swarm-start.ps1""" -PassThru -WindowStyle Minimized
                if ($Process -eq $null) {[PSCustomObject]@{ProcessId = $null}; return
                };
                [PSCustomObject]@{ProcessId = $Process.Id; ProcessHandle = $Process.Handle};
                $ControllerProcess.Handle | Out-Null; $Process.Handle | Out-Null; 
                do {if ($ControllerProcess.WaitForExit(1000)) {$Process.CloseMainWindow() | Out-Null}}while ($Process.HasExited -eq $false)
            }
      
            do {sleep 1; $JobOutput = Receive-Job $Job}
            while ($JobOutput -eq $null)
      
            $Process = Get-Process | Where Id -EQ $JobOutput.ProcessId
            $Process.Handle | Out-Null
            $Process
        }
        else {$MinerProcess}
    } 

    elseif ($Platforms -eq "linux") {
        $Logs = Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) "logs\$($MinerCurrent.Type).log" 
        if (Test-Path $Logs) {Clear-Content $Logs}
        Set-Location (Split-Path $($MinerCurrent.Path))
        Rename-Item "$($MinerCurrent.Path)" -NewName "$($MinerCurrent.InstanceName)" -Force
        Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
        $MinerConfig = "./$($MinerCurrent.InstanceName) $MinerArguments 2>&1 | tee $Logs"
        $MinerConfig | Set-Content ".\build\bash\config.sh" -Force  
        Write-Host "
         ______________
       /.----------..-'
-.     ||           \\
.----'-||-.          \\
|o _   || |           \\
| [_]  || |_...-----.._\\
| [_]  ||.'            ``-._ _
| [_]  '.O)_...-----....._ ``.\
/ [_]o .' _ _'''''''''_ _ `. ``.       __
|______/.'  _  ``.---.'  _  ``.\  ``._./  \Cl
|'''''/, .' _ '. . , .' _ '. .``. .o'|   \ear
``---..|; : (_) : ;-; : (_) : ;-'``--.|    \ing Screen $($MinerCurrent.Type) & Tracking
       ' '. _ .' ' ' '. _ .' '      /     \
        ``._ _ _,'   ``._ _ _,'       ``._____\        
"
        Start-Process ".\build\bash\killall.sh" -ArgumentList "$($MinerCurrent.Type)" -Wait
        $FileTimer = New-Object -TypeName System.Diagnostics.Stopwatch
        $FileTimer.Restart()
        $FileChecked = $false
        do {
            $FileCheck = ".\build\txt\bestminers.txt"
            if (Test-Path $FileCheck) {$FileChecked = $true}
            Start-Sleep -s 1
        }until($FileChecked -eq $true -or $FileTimer.Elapsed.TotalSeconds -gt 9)
        $FileTimer.Stop()
        if ($FileChecked -eq $false) {Write-Warning "Failed To Write Miner Details To File"}
        Start-Process "killcx.sh" -ArgumentList $MinerCurrent.Port -Wait
        Start-Sleep -S $MinerCurrent.Delay
        Set-Location (Split-Path $($MinerCurrent.Path))
        Start-Process "chmod" -ArgumentList "+x $($MinerCurrent.InstanceName)" -Wait
        Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
        Start-Sleep -S .25
        Write-Host "Starting $($MinerCurrent.Name) Mining $($MinerCurrent.Coins) on $($MinerCurrent.Type)" -ForegroundColor Cyan
        Start-Sleep -S .25
        $MinerDir = $(Split-Path $($MinerCurrent.Path))
        $Dir = (Split-Path $script:MyInvocation.MyCommand.Path)
        $Export = Join-Path $Dir "build\export"

        $Startup = @()
        $Startup += "`#`!/usr/bin/env bash"
        $Startup += "screen -S $($MinerCurrent.Type) -d -m", "sleep .1"
        if ($MinerCurrent.Prestart) {$MinerCurrent.Prestart | foreach {$Startup += "screen -S $($MinerCurrent.Type) -X stuff $`"$($_)\n`"", "sleep .1"}}
        $Startup += "screen -S $($MinerCurrent.Type) -X stuff $`"cd\n`"", "sleep .1"
        $Startup += "screen -S $($MinerCurrent.Type) -X stuff $`"cd $MinerDir\n`"", "sleep .1"
        $Startup += "screen -S $($MinerCurrent.Type) -X stuff $`"`$(< $Dir/build/bash/config.sh)\n`""

        $Startup | Set-Content ".\build\bash\startup.sh"
        Start-Sleep -S 1
        Start-Process "chmod" -ArgumentList "+x build/bash/startup.sh" -Wait
        Start-Process ".\build\bash\startup.sh" -Wait

        $MinerTimer.Restart()
        Do {
            Start-Sleep -S 1
            Write-Host "Getting Process ID for $($MinerCurrent.MinerName)"           
            $MinerProcess = Get-Process -Name "$($MinerCurrent.InstanceName)" -ErrorAction SilentlyContinue
            $MinerProcess = $MinerProcess | Select -First 1
        }until($MinerProcess -ne $null -or ($MinerTimer.Elapsed.TotalSeconds) -ge 10)  
        if ($MinerProcess -ne $null) {
            $MinerProcess.Id | Set-Content ".\build\pid\$($MinerCurrent.Name)_$($MinerCurrent.Coins)_$($MinerCurrent.InstanceName)_pid.txt"
            Get-Date | Set-Content ".\build\pid\$($MinerCurrent.Name)_$($MinerCurrent.Coins)_$($MinerCurrent.InstanceName)_date.txt"
            Start-Sleep -S 1
        }
        $MinerTimer.Stop()
        Rename-Item "$MinerDir\$($MinerCurrent.InstanceName)" -NewName "$($MinerCurrent.MinerName)" -Force
        Start-Sleep -S .25
        Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
        $MinerProcess
    }
}
