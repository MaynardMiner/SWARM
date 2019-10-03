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

function Global:Remove-ASICPools {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$AIP,
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Port,
        [Parameter(Mandatory = $true, Position = 2)]
        [string]$Name
    )

    $ASIC_Pools = @{ }

    Switch ($Name) {
        "cgminer" {
            $ASICM = "cgminer"
            log "Clearing all previous miner pools." -ForegroundColor "Yellow"
            $ASIC_Pools.Add($ASICM, @{ })
            ##First we need to discover all pools
            $Commands = @{command = "pools"; parameter = 0 } | ConvertTo-Json -Compress
            $response = $Null
            $response = Global:Get-TCP -Server $AIP -Port $Port -Message $Commands -Timeout 10
            if ($response) {
                ##Windows screws up last character
                if ($response[-1] -notmatch "}") { $response = $Response.Substring(0, $Response.Length - 1) }
                $PoolList = $response | ConvertFrom-Json
                $PoolList = $PoolList.POOLS
                $PoolList | ForEach-Object { $ASIC_Pools.$ASICM.Add("Pool_$($_.Pool)", $_.Pool) }
                $ASIC_Pools.$ASICM.keys | ForEach-Object {
                    $PoolNo = $($ASIC_Pools.$ASICM.$_)
                    $Commands = @{command = "removepool"; parameter = "$PoolNo" } | ConvertTo-Json -Compress; 
                    $response = $Null; 
                    $response = Global:Get-TCP -Server $AIP -Port $Port -Message $Commands -Timeout 10
                    $response
                }
            }
            else { log "WARNING: Failed To Gather Miner Pool List!" -ForegroundColor Yellow }
        }
    }
}

function Global:Start-LaunchCode($MinerCurrent, $AIP) {

    

    if ($MinerCurrent.Type -notlike "*ASIC*") {
        ##Remove Old PID FIle
        $MinerTimer = New-Object -TypeName System.Diagnostics.Stopwatch
        $Export = Join-Path $($(vars).dir) "build\export"
        $PIDMiners = "$($MinerCurrent.Type)"
        if (Test-Path ".\build\pid\*$PIDMiners*") { Remove-Item ".\build\pid\*$PIDMiners*" }
        $Logs = Join-Path $($(vars).dir) "logs\$($MinerCurrent.Type).log" 

        switch -WildCard ($MinerCurrent.Type) {
            "*NVIDIA*" {
                if ($MinerCurrent.Devices -ne "none") {
                    switch ($MinerCurrent.DeviceCall) {
                        "multiminer" { $MinerArguments = "$($MinerCurrent.Arguments)" }
                        "ccminer" { $MinerArguments = "-d $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
                        "ewbf" { $MinerArguments = "--cuda_devices $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
                        "miniz" { $MinerArguments = "-cd $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
                        "energiminer" { $MinerArguments = "--cuda-devices $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
                        "gminer" { $MinerArguments = "-d $($MinerCurrent.ArgDevices) $($MinerCurrent.Arguments)" }
                        "dstm" { $MinerArguments = "--dev $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
                        "claymore" { $MinerArguments = "-di $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
                        "trex" { $MinerArguments = "-d $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
                        "ttminer" { $MinerArguments = "-d $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
                        "bminer" { $MinerArguments = "-devices $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
                        "lolminer" { $MinerArguments = "--devices $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
                        "xmrstak" { $MinerArguments = "--cuda-devices $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
                        "progminer" { $MinerArguments = "--cuda-devices $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
                        "grin-miner" { global:set-minerconfig $NewMiner $Logs }
                        "zjazz" {
                            $GetDevices = $($MinerCurrent.Devices) -split ","
                            $GetDevices | ForEach-Object { $LaunchDevices += "-d $($_) " }         
                            $MinerArguments = "$LaunchDevices$($MinerCurrent.Arguments)"
                        }
                        "excavator" {
                            $MinerDirectory = Split-Path ($MinerCurrent.Path)
                            $MinerArguments = "-c command.json -p $($MinerCurrent.Port)"
                            set-nicehash $($MinerCurrent.NPool) 3200 $($MinerCurrent.NUser) $($MinerCurrent.Algo) $($MinerCurrent.CommandFile) "$($MinerCurrent.Devices)" "$($MinerCurrent.NCommands)"
                        }
                        default { $MinerArguments = "$($MinerCurrent.Arguments)" }
                    }
                }
                else {
                    switch ($MinerCurrent.DeviceCall) {
                        "excavator" {
                            $MinerDirectory = Split-Path ($MinerCurrent.Path) -Parent
                            $CommandFilePath = Join-Path $($(vars).dir) "$($MinerDirectory)\command.json"
                            $MinerArguments = "-c command.json -p $($MinerCurrent.Port)"
                            $NHDevices = Get-Content ".\build\txt\devicelist.txt" | ConvertFrom-Json
                            $NiceDevices = Global:Get-DeviceString -TypeCount $NHDevices.NVIDIA.Count
                            set-nicehash $($MinerCurrent.NPool) 3200 $($MinerCurrent.NUser) $($MinerCurrent.Algo) $($MinerCurrent.CommandFile) "$NiceDevices"
                        }
                        "grin-miner" { global:set-minerconfig $NewMiner $Logs }
                        "gminer" { $MinerArguments = "-d $($MinerCurrent.ArgDevices) $($MinerCurrent.Arguments)" }
                        "lolminer" { $MinerArguments = "--devices NVIDIA $($MinerCurrent.Arguments)" }
                        default { $MinerArguments = "$($MinerCurrent.Arguments)" }
                    }
                }
            }

            "*AMD*" {
                if ($MinerCurrent.Devices -ne "none") {
                    switch ($MinerCurrent.DeviceCall) {
                        "claymore" { $MinerArguments = "-di $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
                        "xmrstak" { $MinerArguments = "$($MinerCurrent.Arguments)" }
                        "sgminer-gm" { log "Miner Has Devices"; $MinerArguments = "-d $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
                        "tdxminer" { $MinerArguments = "-d $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
                        "lolminer" { $MinerArguments = "--devices $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
                        "wildrig" { $MinerArguments = "$($MinerCurrent.Arguments)" }
                        "grin-miner" { Global:set-minerconfig $MinerCurrent $Logs }
                        "gminer" { $MinerArguments = "-d $($MinerCurrent.ArgDevices) $($MinerCurrent.Arguments)" }
                        "progminer" { $MinerArguments = "--opencl-devices $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
                        "lyclminer" {
                            $MinerArguments = ""
                            Set-Location (Split-Path $($MinerCurrent.Path))
                            $ConfFile = Get-Content ".\lyclMiner.conf" -Force
                            $Connection = $MinerCurrent.Connection
                            $Username = $MinerCurrent.Username
                            $Password = $MinerCurrent.Password
                            $NewLines = $ConfFile | ForEach-Object {
                                if ($_ -like "*<Connection Url =*") { $_ = "<Connection Url = `"stratum+tcp://$Connection`"" }
                                if ($_ -like "*Username =*") { $_ = "            Username = `"$Username`"    " }
                                if ($_ -like "*Password =*" ) { $_ = "            Password = `"$Password`">    " }
                                if ($_ -notlike "*<Connection Url*" -or $_ -notlike "*Username*" -or $_ -notlike "*Password*") { $_ }
                            }
                            Clear-Content ".\lyclMiner.conf" -force
                            $NewLines | Set-Content ".\lyclMiner.conf"
                            Set-Location $($(vars).dir)
                        }
                        "nanominer" { global:set-minerconfig $MinerCurrent $Logs }
                        default { $MinerArguments = "$($MinerCurrent.Arguments)" }           
                    }
                }
                else {
                    switch ($MinerCurrent.DeviceCall) {
                        "lyclminer" {
                            $MinerArguments = ""
                            Set-Location (Split-Path $($MinerCurrent.Path))
                            $ConfFile = Get-Content ".\lyclMiner.conf" -Force
                            $Connection = $MinerCurrent.Connection
                            $Username = $MinerCurrent.Username
                            $Password = $MinerCurrent.Password
                            $NewLines = $ConfFile | ForEach-Object {
                                if ($_ -like "*<Connection Url =*") { $_ = "<Connection Url = `"stratum+tcp://$Connection`"" }
                                if ($_ -like "*Username =*") { $_ = "            Username = `"$Username`"    " }
                                if ($_ -like "*Password =*" ) { $_ = "            Password = `"$Password`">    " }
                                if ($_ -notlike "*<Connection Url*" -or $_ -notlike "*Username*" -or $_ -notlike "*Password*") { $_ }
                            }
                            Clear-Content ".\lyclMiner.conf" -force
                            $NewLines | Set-Content ".\lyclMiner.conf"
                            Set-Location $($(vars).dir)
                        }
                        "grin-miner" { Global:set-minerconfig $MinerCurrent $Logs }
                        "gminer" { $MinerArguments = "-d $($MinerCurrent.ArgDevices) $($MinerCurrent.Arguments)" }
                        "lolminer" { $MinerArguments = "--devices AMD $($MinerCurrent.Arguments)" }
                        "nanominer" { global:set-minerconfig $MinerCurrent $Logs }
                        default { $MinerArguments = "$($MinerCurrent.Arguments)" }
                    }
                }
            }  
      
            "*CPU*" {
                if ($MinerCurrent.Devices -eq '') { $MinerArguments = "$($MinerCurrent.Arguments)" }
                elseif ($MinerCurrent.DeviceCall -eq "cpuminer-opt") { $MinerArguments = "-t $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
                elseif ($MinerCurrent.DeviceCall -eq "xmrig-opt") { $MinerArguments = "-t $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
            }
        }

        if ($(arg).Platform -eq "windows") {
            if ($MinerProcess -eq $null -or $MinerProcess.HasExited -eq $true) {
            
                #dir
                $WorkingDirectory = Join-Path $($(vars).dir) $(Split-Path $($MinerCurrent.Path))

                ##Classic Logo For Windows
                log "
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
   ``---..|; : (_) : ;-; : (_) : ;-'``--.|    \ing windows for $($MinerCurrent.Type) & Tracking
          ' '. _ .' ' ' '. _ .' '      /     \
           ``._ _ _,'   ``._ _ _,'       ``._____\        
   "

                ##Remove Old Logs
                Remove-Item ".\logs\*$($MinerCurrent.Type)*" -Force -ErrorAction SilentlyContinue
                Start-Sleep -S .5

                ##Make Test.bat for users
                $Algo = ($MinerCurrent.Algo).Replace("`/", "_")
                $minerbat = @()
                ## pwsh to launch powershell window to fully emulate SWARM launching
                $minerbat += "pwsh -ExecutionPolicy Bypass -command `"Start-Process pwsh -ArgumentList `"`"-noexit -executionpolicy Bypass -Command `"`"`"`".\swarm_start_$($Algo).ps1`"`"`"`"`"`""
                $miner_bat = Join-Path $WorkingDirectory "swarm_start_$($Algo).bat"
                $minerbat | Set-Content $miner_bat

                try { 
                    $Net = Get-NetFireWallRule | Where DisplayName -eq "SWARM $($MinerCurrent.MinerName)"
                    if (-not $net) {
                        $Program = Join-Path "$WorkingDirectory" "$($MinerCurrent.MinerName)"
                        New-NetFirewallRule -DisplayName "SWARM $($MinerCurrent.Minername)" -Direction Inbound -Program $Program -Action Allow | Out-Null
                    }
                }
                catch { }

                ##Build Start Script
                if ($MinerCurrent.Prestart) {
                    $Prestart = @()
                    $MinerCurrent.Prestart | ForEach-Object {
                        if ($_ -notlike "export LD_LIBRARY_PATH=$($(vars).dir)\build\export") {
                            $setx = $_ -replace "export ", "set "
                            $setx = $setx -replace "=", " "
                            $Prestart += "$setx`n"
                        }
                    }
                }
                ##Determine if Miner needs logging
                if ($MinerCurrent.Log -ne "miner_generated") {
                    Switch ($MinerCurrent.API) {
                        "lolminer" {
                            $start = "Invoke-Expression `'.\$($MinerCurrent.MinerName) $($MinerArguments) *>&1 | %{`$Output = `$_ -replace `"\\[\d+(;\d+)?m`"; `$OutPut | Out-File -FilePath ""$Logs"" -Append; `$Output | Out-Host;}`'" 
                        }
                        "ccminer" {
                            $start = "Invoke-Expression `'.\$($MinerCurrent.MinerName) $($MinerArguments) *>&1 | %{`$Output = `$_ -replace `"\\[\d+(;\d+)?m`"; `$OutPut | Out-File -FilePath ""$Logs"" -Append; `$Output | Out-Host;}`'" 
                        }
                        "cpuminer" {
                            $start = "Invoke-Expression `'.\$($MinerCurrent.MinerName) $($MinerArguments) *>&1 | %{`$Output = `$_ -replace `"\\[\d+(;\d+)?m`"; `$OutPut | Out-File -FilePath ""$Logs"" -Append; `$Output | Out-Host;}`'" 
                        }
                        "claymore" {
                            $start = "Invoke-Expression `'.\$($MinerCurrent.MinerName) $($MinerArguments) *>&1 | %{`$Output = `$_ -replace `"\\[\d+(;\d+)?m`"; `$OutPut | Out-File -FilePath ""$Logs"" -Append; `$Output | Out-Host;}`'" 
                        }
                        "xmrstak" {
                            $start = "Invoke-Expression `'.\$($MinerCurrent.MinerName) $($MinerArguments) *>&1 | %{`$Output = `$_ -replace `"\\[\d+(;\d+)?m`"; `$OutPut | Out-File -FilePath ""$Logs"" -Append; `$Output | Out-Host;}`'" 
                        }
                        "xmrig-opt" {
                            $start = "Invoke-Expression `'.\$($MinerCurrent.MinerName) $($MinerArguments) *>&1 | %{`$Output = `$_ -replace `"\\[\d+(;\d+)?m`"; `$OutPut | Out-File -FilePath ""$Logs"" -Append; `$Output | Out-Host;}`'" 
                        }
                        "wildrig" {
                            $start = "Invoke-Expression `'.\$($MinerCurrent.MinerName) $($MinerArguments) *>&1 | %{`$Output = `$_ -replace `"\\[\d+(;\d+)?m`"; `$OutPut | Out-File -FilePath ""$Logs"" -Append; `$Output | Out-Host;}`'" 
                        }
                        "sgminer-gm" {
                            $start = "Invoke-Expression `'.\$($MinerCurrent.MinerName) $($MinerArguments) *>&1 | %{`$Output = `$_ -replace `"\\[\d+(;\d+)?m`"; `$OutPut | Out-File -FilePath ""$Logs"" -Append; `$Output | Out-Host;}`'" 
                        }
                        "multiminer" {
                            $start = "Invoke-Expression `'.\$($MinerCurrent.MinerName) $($MinerArguments) *>&1 | %{`$Output = `$_ -replace `"\\[\d+(;\d+)?m`"; `$OutPut | Out-File -FilePath ""$Logs"" -Append; `$Output | Out-Host;}`'" 
                        }
                        default { 
                            $start = "Invoke-Expression `'.\$($MinerCurrent.MinerName) $($MinerArguments) *>&1 | %{`$Output += `$_ -replace `"\\[\d+(;\d+)?m`"; if(`$Output -cmatch `"`\n`"){`$OutPut | Out-File -FilePath ""$Logs"" -Append; `$Output | Out-Host; `$Output = `$null}}`'" 
                        }
                    }
                }
                else { $start += "Invoke-Expression "".\$($MinerCurrent.MinerName) $MinerArguments""" }

                $script = 

                "
`#`# Window Title
`$host.ui.RawUI.WindowTitle = `'$($MinerCurrent.Name) - $($MinerCurrent.Algo)`';
`#`# set encoding for logging
`$OutputEncoding = [System.Text.Encoding]::ASCII
`#`# Has to be powershell 5.0 to set icon
 `$proc = Start-Process `"powershell`" -ArgumentList `"Set-Location ``'$($(vars).dir)``'; .\build\powershell\scripts\icon.ps1 ``'$($(vars).dir)\build\apps\icons\miner.ico``'`" -NoNewWindow -Passthru
 `$proc | Wait-Process
 remove-variable `$proc -ErrorAction Ignore
`#`# Start Miner - Logging if needed.
$Prestart
$start
"

                $script | Out-File "$WorkingDirectory\swarm_start_$($Algo).ps1"
                Start-Sleep -S .5

                ##Start Miner Job
                $Job = Start-Job -ArgumentList $PID, $WorkingDirectory, (Convert-Path ".\build\apps\launchcode.dll"), ".\swarm_start_$($Algo).ps1" {
                    param($ControllerProcessID, $WorkingDirectory, $dll, $ps1)
                    Set-Location $WorkingDirectory
                    $ControllerProcess = Get-Process -Id $ControllerProcessID
                    if ($null -eq $ControllerProcess) { return }
                    Add-Type -Path $dll
                    $start = [launchcode]::New()
                    $FilePath = "$PSHome\pwsh.exe"
                    $CommandLine = '"' + $FilePath + '"'
                    $arguments = "-executionpolicy bypass -command `"$ps1`""
                    $CommandLine += " " + $arguments
                    $New_Miner = $start.New_Miner($filepath, $CommandLine, $WorkingDirectory)
                    $Process = Get-Process -id $New_Miner.dwProcessId -ErrorAction Ignore
                    if ($null -eq $Process) { 
                        [PSCustomObject]@{ProcessId = $null }
                        return
                    }            
                    [PSCustomObject]@{ProcessId = $Process.Id; ProcessHandle = $Process.Handle };
                    $ControllerProcess.Handle | Out-Null; $Process.Handle | Out-Null; 
                    do { if ($ControllerProcess.WaitForExit(1000)) { $Process.CloseMainWindow() | Out-Null } }while ($Process.HasExited -eq $false)
                }
      
                do { sleep 1; $JobOutput = Receive-Job $Job }
                while ($JobOutput -eq $null)
      
                $Process = Get-Process | Where-Object Id -EQ $JobOutput.ProcessId
                $Process.Handle | Out-Null
                $Process
            }
            else { $MinerProcess }
        } 

        elseif ($(arg).Platform -eq "linux") {

            ##Specified Dir Again For debugging / Testing - No Harm
            $MinerDir = Join-Path $($(vars).dir) $(Split-Path $($MinerCurrent.Path))
            $MinerDir = $(Resolve-Path $MinerDir).Path
            $MinerEXE = Join-Path $($(vars).dir) $MinerCurrent.Path
            $MinerEXE = $(Resolve-Path $MinerExe).Path
            $StartDate = Get-Date

            ##PID Tracking Path & Date
            $PIDPath = Join-Path $($(vars).dir) "build\pid\$($MinerCurrent.InstanceName)_pid.txt"
            $PIDInfoPath = Join-Path $($(vars).dir) "build\pid\$($MinerCurrent.InstanceName)_info.txt"
            $PIDInfo = @{miner_exec = "$MinerEXE"; start_date = "$StartDate"; pid_path = "$PIDPath"; }
            $PIDInfo | ConvertTo-Json | Set-Content $PIDInfoPath

            ##Clear Old PID information
            if (Test-Path $PIDPath) { Remove-Item $PIDPath -Force }
            if (Test-Path $PIDInfo) { Remove-Item $PIDInfo -Force }

            ##Get Full Path Of Miner Executable and its dir
        
            ##Add Logging To Arguments if needed
            if ($MinerCurrent.Log -ne "miner_generated") { $MinerArgs = "$MinerArguments 2>&1 | tee `'$($MinerCurrent.Log)`'" }
            else { $MinerArgs = "$MinerArguments" }

            ##Build Daemon
            $Daemon = "start-stop-daemon --start --make-pidfile --chdir $MinerDir --pidfile $PIDPath --exec $MinerEXE -- $MinerArgs"

            ##Actual Config - config.sh has already +x chmod from git.
            $Daemon | Set-Content ".\build\bash\config.sh" -Force

            ##Classic Logo For Linux
            log "
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
            ##Terminate Previous Miner Screens Of That Type.
            $proc = Start-Process ".\build\bash\killall.sh" -ArgumentList "$($MinerCurrent.Type)" -PassThru
            $proc | Wait-Process

            ##Remove Old Logs
            $MinerLogs = Get-ChildItem "logs" | Where-Object Name -like "*$($MinerCurrent.Type)*"
            $MinerLogs | ForEach-Object { if (Test-Path "$($_)") { Remove-Item "$($_)" -Force } }
            Start-Sleep -S .5

            ##Ensure bestminers.txt has been written (for slower storage drives)
            $FileTimer = New-Object -TypeName System.Diagnostics.Stopwatch
            $FileTimer.Restart()
            $FileChecked = $false
            do {
                $FileCheck = ".\build\txt\bestminers.txt"
                if (Test-Path $FileCheck) { $FileChecked = $true }
                Start-Sleep -s .1
            }until($FileChecked -eq $true -or $FileTimer.Elapsed.TotalSeconds -gt 9)
            $FileTimer.Stop()
            if ($FileChecked -eq $false) { Write-Warning "Failed To Write Miner Details To File" }

            ##Bash Script to free Port
            if ($MinerCurrent.Port -ne 0) {
                Write-Log "Clearing Miner Port `($($MinerCurrent.Port)`).." -ForegroundColor Cyan
                $warn = 0;
                $proc = Start-Process ".\build\bash\killcx.sh" -ArgumentList $MinerCurrent.Port -PassThru
                do {
                    $proc | Wait-Process -Timeout 5 -ErrorAction Ignore
                    if ($proc.HasExited -eq $false) {
                        log "Still Waiting For Port To Clear..." -ForegroundColor Cyan
                        $warn += 5 
                    }
                    else { $warn = $(arg).time_wait }
                }while ($warn -lt $(arg).time_wait)
                
                if ($warn -eq 2) { 
                    log "Warning: Port still listed as TIME_WAIT, but launching anyway" -ForegroundColor Yellow 
                    if ($Proc.HasExited -eq $false) {
                        kill $Proc.Id -ErrorAction Ignore
                    }
                } 
                elseif ($Warn -eq 10) { log "Port Was Cleared" -ForegroundColor Cyan }
            }
            ##Notification To User That Miner Is Attempting To start
            log "Starting $($MinerCurrent.Name) Mining $($MinerCurrent.Symbol) on $($MinerCurrent.Type)" -ForegroundColor Cyan

            ##FilePaths
            $Export = Join-Path $($(vars).dir) "build\export"

            ##Build Two Bash Scripts: First script is to start miner while SWARM is running
            ##Second Script is to build a "test script" written in bin folder for users to
            ##to test. The reason this is done, is because build\bash\config.sh already has
            ##exectuble permissions, so SWARM does not need to be ran in root. The other file
            ##is made when miner is launched, and is chmod +x on the spot. Users not running in
            ##root may not be able to do this, but at least SWARM will still work for them.
            $Script = @()
            $TestScript = @()
            $Script += "`#`!/usr/bin/env bash"
            $TestScript += "`#`!/usr/bin/env bash"

            ##Make A New Screen
            $Script += "screen -S $($MinerCurrent.Type) -d -m", "sleep .1"

            ##Add All exports / miner Pre-starts
            ##I added a sleep .1 to each, because it is one script writing to
            ##screen, and not being initiated through current terminal.
            if ($MinerCurrent.Prestart) {
                $MinerCurrent.Prestart | ForEach-Object {
                    $Script += "screen -S $($MinerCurrent.Type) -X stuff $`"$($_)\n`"", "sleep .1"; 
                    $TestScript += "$($_)", "sleep .1"
                }
            }

            ##Navigate to the miner dir, so if you wanted to fiddle with miner if it crashed
            ##You are already in dir.
            $Script += "screen -S $($MinerCurrent.Type) -X stuff $`"cd\n`"", "sleep .1"
            $Script += "screen -S $($MinerCurrent.Type) -X stuff $`"cd $MinerDir\n`"", "sleep .1"

            ##This launches the previous generated configs.
            $Script += "screen -S $($MinerCurrent.Type) -X stuff $`"`$(< $($(vars).dir)/build/bash/config.sh)\n`""
            $TestScript += $Daemon

            ##Write Both Scripts
            $Script | Set-Content ".\build\bash\startup.sh"
            ## Test config for users.
            $Algo = ($MinerCurrent.Algo).Replace("`/", "_")
            $TestScript | Set-Content "$MinerDir/swarm_start_$($Algo).sh"
    
            ## .5 Second Delay After Read/Write Of Config Files. For Slower Drives.
            Start-Sleep -S .5

            ##chmod again, to be safe.
            $Proc = Start-Process "chmod" -ArgumentList "+x build/bash/startup.sh" -PassThru
            $Proc | Wait-Process
            $Proc = Start-Process "chmod" -ArgumentList "+x $MinerDir/swarm_start_$($Algo).sh" -PassThru
            $Proc | Wait-Process

            ##chmod miner (sometimes they don't set permissions correctly)
            $MinerFP = $(Resolve-Path $MinerCurrent.Path).Path
            $Proc = Start-Process "chmod" -ArgumentList "+x $MinerFP" -PassThru
            $Proc | Wait-Process

            ##Launch The Config
            $Proc = Start-Process ".\build\bash\startup.sh" -PassThru
            $Proc | Wait-Process

            ##Miner Should have started, PID will be written to specified file.
            ##For up to 10 seconds, we want to check for the specified PID, and
            ##Confirm the miner is running
            $MinerTimer.Restart()
            Do {
                #Sleep for 1 every second
                Start-Sleep -S 1
                #Write We Are getting ID
                log "Getting Process ID for $($MinerCurrent.MinerName)"
                if (Test-Path $PIDPath) { $MinerPID = Get-Content $PIDPath | Select-Object -First 1 }
                ##Powershell Get Process Instance
                if ($MinerPID) { $MinerProcess = Get-Process -ID $MinerPid -ErrorAction SilentlyContinue }
            }until($MinerProcess -ne $null -or ($MinerTimer.Elapsed.TotalSeconds) -ge 10)  
            ##Stop Timer
            $MinerTimer.Stop()
            $MinerProcess
        }
    }
    else {
        $clear = Global:Remove-ASICPools $AIP $MinerCurrent.Port $MinerCurrent.API
        $Commands = "addpool|$($MinerCurrent.Arguments)"
        log "Adding New Pool"
        $response = Global:Get-TCP -Server $AIP -Port $MinerCurrent.Port -Timeout 10 -Message $Commands
        $response = $null
        log "Switching To New Pool"
        $Commands = "switchpool|1"
        $response = Global:Get-TCP -Server $AIP -Port $MinerCurrent.Port -Timeout 10 -Message $Commands
        if ($response) {
            $MinerProcess = @{StartTime = (Get-Date); HasExited = $false }
        }
        $MinerProcess
    }
}
