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

function Remove-ASICPools {
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
            Write-Log "Clearing all previous cgminer pools." -ForegroundColor "Yellow"
            $ASIC_Pools.Add($ASICM, @{ })
            ##First we need to discover all pools
            $Commands = @{command = "pools"; parameter = 0 } | ConvertTo-Json -Compress
            $response = $Null
            $response = Get-TCP -Server $AIP -Port $Port -Message $Commands -Timeout 10
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
                    $response = Get-TCP -Server $AIP -Port $Port -Message $Commands -Timeout 10
                    $response
                }
            }
            else { Write-Log "WARNING: Failed To Gather cgminer Pool List!" -ForegroundColor Yellow }
        }
    }
}

function Start-LaunchCode {

    param(
        [Parameter(Mandatory = $true)]
        [String]$NewMiner,
        [Parameter(Mandatory = $false)]
        [String]$PP,
        [Parameter(Mandatory = $false)]
        [String]$AIP
    ) 

    $MinerCurrent = $NewMiner | ConvertFrom-Json

    if ($MinerCurrent.Type -notlike "*ASIC*") {
        ##Remove Old PID FIle
        $MinerTimer = New-Object -TypeName System.Diagnostics.Stopwatch
        $Export = Join-Path $Global:Dir "build\export"
        $PIDMiners = "$($MinerCurrent.Type)"
        if (Test-Path ".\build\pid\*$PIDMiners*") { Remove-Item ".\build\pid\*$PIDMiners*" }
        if (Test-Path ".\build\*$($MinerCurrent.Type)*-hash.txt") { Clear-Content ".\build\*$($MinerCurrent.Type)*-hash.txt" }
        $Logs = Join-Path $Global:Dir "logs\$($MinerCurrent.Type).log" 

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
                        "grin-miner" { set-minerconfig $NewMiner $Logs }
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
                    }
                }
                else {
                    switch ($MinerCurrent.DeviceCall) {
                        "excavator" {
                            $MinerDirectory = Split-Path ($MinerCurrent.Path) -Parent
                            $CommandFilePath = Join-Path $Global:Dir "$($MinerDirectory)\command.json"
                            $MinerArguments = "-c command.json -p $($MinerCurrent.Port)"
                            $NHDevices = Get-Content ".\build\txt\devicelist.txt" | ConvertFrom-Json
                            $NiceDevices = Get-DeviceString -TypeCount $NHDevices.NVIDIA.Count
                            set-nicehash $($MinerCurrent.NPool) 3200 $($MinerCurrent.NUser) $($MinerCurrent.Algo) $($MinerCurrent.CommandFile) "$NiceDevices"
                        }
                        "grin-miner" { set-minerconfig $NewMiner $Logs }
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
                        "sgminer-gm" { Write-Log "Miner Has Devices"; $MinerArguments = "-d $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
                        "tdxminer" { $MinerArguments = "-d $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
                        "lolminer" { $MinerArguments = "--devices $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
                        "wildrig" { $MinerArguments = "$($MinerCurrent.Arguments)" }
                        "grin-miner" { set-minerconfig $NewMiner $Logs }
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
                            Set-Location $Global:Dir
                        }           
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
                            Set-Location $Global:Dir
                        }
                        "grin-miner" { set-minerconfig $NewMiner $Logs }
                        "gminer" { $MinerArguments = "-d $($MinerCurrent.ArgDevices) $($MinerCurrent.Arguments)" }
                        "lolminer" { $MinerArguments = "--devices AMD $($MinerCurrent.Arguments)" }
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

        switch ($MinerCurrent.DeviceCall) {
            "gminer" { Write-Log "SOME ALGOS MAY REQUIRE 6GB+ VRAM TO WORK" -ForegroundColor Green }
            "bminer" { Write-Log "SOME ALGOS MAY REQUIRE 6GB+ VRAM TO WORK" -ForegroundColor Green }
        }

    

        if ($Global:Config.Params.Platform -eq "windows") {
            if ($MinerProcess -eq $null -or $MinerProcess.HasExited -eq $true) {
            
                #dir
                $WorkingDirectory = Join-Path $Global:Dir $(Split-Path $($MinerCurrent.Path))

                ##Classic Logo For Windows
                Write-Log "
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
                Start-Sleep -S 1

                ##Make Test.bat for users
                if (-not (Test-Path "$WorkingDirectory\swarm-start.bat")) {
                    $minerbat = @()
                    $minerbat += "CMD /r pwsh -ExecutionPolicy Bypass -command `".\swarm-start.ps1`""
                    $minerbat += "cmd.exe"
                    $miner_bat = Join-Path $WorkingDirectory "swarm-start.bat"
                    $minerbat | Set-Content $miner_bat
                }

                try { 
                    $Net = Get-NetFireWallRule | Where DisplayName -eq "SWARM $($MinerCurrent.MinerName)"
                    if (-not $net) {
                        $Program = Join-Path "$WorkingDirectory" "$($MinerCurrent.MinerName)"
                        New-NetFirewallRule -DisplayName "SWARM $($MinerCurrent.Minername)" -Direction Inbound -Program $Program -Action Allow | Out-Null
                    }
                } catch {}

                ##Build Start Script
                $script = @()
                $script += "`$OutputEncoding = [System.Text.Encoding]::ASCII"
                $script += "Start-Process `"powershell`" -ArgumentList `"Set-Location ``'$global:dir``'; .\build\powershell\scripts\icon.ps1 ``'$global:dir\build\apps\miner.ico``'`" -NoNewWindow"
                $script += "`$host.ui.RawUI.WindowTitle = `'$($MinerCurrent.Name) - $($MinerCurrent.Algo)`';"
                $MinerCurrent.Prestart | ForEach-Object {
                    if ($_ -notlike "export LD_LIBRARY_PATH=$($global:Dir)\build\export") {
                        $setx = $_ -replace "export ", "set "
                        $setx = $setx -replace "=", " "
                        $script += "$setx"
                    }
                }
                ##Determine if Miner needs logging
                if ($MinerCurrent.Log -ne "miner_generated") {
                    Switch ($MinerCurrent.API) {
                        "lolminer" {
                            $script += "Invoke-Expression `'.\$($MinerCurrent.MinerName) $($MinerArguments) *>&1 | %{`$Output = `$_ -replace `"\\[\d+(;\d+)?m`"; `$OutPut | Out-File -FilePath ""$Logs"" -Append; `$Output | Out-Host;}`'" 
                        }
                        "ccminer" {
                            $script += "Invoke-Expression `'.\$($MinerCurrent.MinerName) $($MinerArguments) *>&1 | %{`$Output = `$_ -replace `"\\[\d+(;\d+)?m`"; `$OutPut | Out-File -FilePath ""$Logs"" -Append; `$Output | Out-Host;}`'" 
                        }
                        "cpuminer" {
                            $script += "Invoke-Expression `'.\$($MinerCurrent.MinerName) $($MinerArguments) *>&1 | %{`$Output = `$_ -replace `"\\[\d+(;\d+)?m`"; `$OutPut | Out-File -FilePath ""$Logs"" -Append; `$Output | Out-Host;}`'" 
                        }
                        "claymore" {
                            $script += "Invoke-Expression `'.\$($MinerCurrent.MinerName) $($MinerArguments) *>&1 | %{`$Output = `$_ -replace `"\\[\d+(;\d+)?m`"; `$OutPut | Out-File -FilePath ""$Logs"" -Append; `$Output | Out-Host;}`'" 
                        }
                        "xmrstak" {
                            $script += "Invoke-Expression `'.\$($MinerCurrent.MinerName) $($MinerArguments) *>&1 | %{`$Output = `$_ -replace `"\\[\d+(;\d+)?m`"; `$OutPut | Out-File -FilePath ""$Logs"" -Append; `$Output | Out-Host;}`'" 
                        }
                        "xmrig-opt" {
                            $script += "Invoke-Expression `'.\$($MinerCurrent.MinerName) $($MinerArguments) *>&1 | %{`$Output = `$_ -replace `"\\[\d+(;\d+)?m`"; `$OutPut | Out-File -FilePath ""$Logs"" -Append; `$Output | Out-Host;}`'" 
                        }
                        "wildrig" {
                            $script += "Invoke-Expression `'.\$($MinerCurrent.MinerName) $($MinerArguments) *>&1 | %{`$Output = `$_ -replace `"\\[\d+(;\d+)?m`"; `$OutPut | Out-File -FilePath ""$Logs"" -Append; `$Output | Out-Host;}`'" 
                        }
                        "multiminer" {
                            $script += "Invoke-Expression `'.\$($MinerCurrent.MinerName) $($MinerArguments) *>&1 | %{`$Output = `$_ -replace `"\\[\d+(;\d+)?m`"; `$OutPut | Out-File -FilePath ""$Logs"" -Append; `$Output | Out-Host;}`'" 
                        }
                        "nebutech" {
                            $script += "Invoke-Expression `'.\$($MinerCurrent.MinerName) $($MinerArguments) *>&1 | %{`$Output = `$_ -replace `"\\[\d+(;\d+)?m`"; `$OutPut | Out-File -FilePath ""$Logs"" -Append; `$Output | Out-Host;}`'" 
                        }
                        default { 
                            $script += "Invoke-Expression `'.\$($MinerCurrent.MinerName) $($MinerArguments) *>&1 | %{`$Output += `$_ -replace `"\\[\d+(;\d+)?m`"; if(`$Output -cmatch `"`\n`"){`$OutPut | Out-File -FilePath ""$Logs"" -Append; `$Output | Out-Host; `$Output = `$null}}`'" 
                        }
                    }
                }
                else { $script += "Invoke-Expression "".\$($MinerCurrent.MinerName) $MinerArguments""" }            
                $script | Out-File "$WorkingDirectory\swarm-start.ps1"
                Start-Sleep -S .5

                ##Start Miner Job
                $Job = Start-Job -ArgumentList $PID, $WorkingDirectory {
                    param($ControllerProcessID, $WorkingDirectory)
                    Set-Location $WorkingDirectory
                    $ControllerProcess = Get-Process -Id $ControllerProcessID
                    if ($ControllerProcess -eq $null) { return }
                    $Process = Start-Process "CMD" -ArgumentList "/c pwsh -executionpolicy bypass -command "".\swarm-start.ps1""" -PassThru -WindowStyle Minimized
                    if ($Process -eq $null) { [PSCustomObject]@{ProcessId = $null }; return
                    };
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

        elseif ($Global:Config.Params.Platform -eq "linux") {

            ##Specified Dir Again For debugging / Testing - No Harm
            $MinerDir = Join-Path $($global:Dir) $(Split-Path $($MinerCurrent.Path))
            $MinerDir = $(Resolve-Path $MinerDir).Path
            $MinerEXE = Join-Path $($global:Dir) $MinerCurrent.Path
            $MinerEXE = $(Resolve-Path $MinerExe).Path
            $StartDate = Get-Date

            ##PID Tracking Path & Date
            $PIDPath = Join-Path $($global:Dir) "build\pid\$($MinerCurrent.InstanceName)_pid.txt"
            $PIDInfoPath = Join-Path $($global:Dir) "build\pid\$($MinerCurrent.InstanceName)_info.txt"
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

            ##Test config -- Allows users to test miner settings written in miner dir
            $TestConfigPath = Join-Path $MinerDir "config.sh"

            ##Actual Config - config.sh has already +x chmod from git.
            $Daemon | Set-Content ".\build\bash\config.sh" -Force

            ##Classic Logo For Linux
            Write-Log "
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
            Start-Process ".\build\bash\killall.sh" -ArgumentList "$($MinerCurrent.Type)" -Wait

            ##Remove Old Logs
            $MinerLogs = Get-ChildItem "logs" | Where-Object Name -like "*$($MinerCurrent.Type)*"
            $MinerLogs | ForEach-Object { if (Test-Path "$($_)") { Remove-Item "$($_)" -Force } }
            Start-Sleep -S 1

            ##Ensure bestminers.txt has been written (for slower storage drives)
            $FileTimer = New-Object -TypeName System.Diagnostics.Stopwatch
            $FileTimer.Restart()
            $FileChecked = $false
            do {
                $FileCheck = ".\build\txt\bestminers.txt"
                if (Test-Path $FileCheck) { $FileChecked = $true }
                Start-Sleep -s 1
            }until($FileChecked -eq $true -or $FileTimer.Elapsed.TotalSeconds -gt 9)
            $FileTimer.Stop()
            if ($FileChecked -eq $false) { Write-Warning "Failed To Write Miner Details To File" }

            ##Bash Script to free Port
            Start-Process ".\build\bash\killcx.sh" -ArgumentList $MinerCurrent.Port

            ##Notification To User That Miner Is Attempting To start
            Write-Log "Starting $($MinerCurrent.Name) Mining $($MinerCurrent.Symbol) on $($MinerCurrent.Type)" -ForegroundColor Cyan

            ##FilePaths
            $Export = Join-Path $($global:Dir) "build\export"

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
            $Script += "screen -S $($MinerCurrent.Type) -X stuff $`"`$(< $($global:Dir)/build/bash/config.sh)\n`""
            $TestScript += $Daemon

            ##Write Both Scripts
            $Script | Set-Content ".\build\bash\startup.sh"
            $TestScript | Set-Content "$MinerDir\startup.sh"
    
            ## 2 Second Delay After Read/Write Of Config Files. For Slower Drives.
            Start-Sleep -S 2

            ##chmod again, to be safe.
            Start-Process "chmod" -ArgumentList "+x build/bash/startup.sh" -Wait
            Start-Process "chmod" -ArgumentList "+x $MinerDir/startup.sh" -Wait

            ##Launch The Config
            Start-Process ".\build\bash\startup.sh" -Wait

            ##Miner Should have started, PID will be written to specified file.
            ##For up to 10 seconds, we want to check for the specified PID, and
            ##Confirm the miner is running
            $MinerTimer.Restart()
            Do {
                #Sleep for 1 every second
                Start-Sleep -S 1
                #Write We Are getting ID
                Write-Log "Getting Process ID for $($MinerCurrent.MinerName)"
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
        $clear = Remove-ASICPools $AIP $MinerCurrent.Port $MinerCurrent.API
        $Commands = "addpool|$($MinerCurrent.Arguments)"
        Write-Log "Adding New Pool"
        $response = Get-TCP -Server $AIP -Port $MinerCurrent.Port -Timeout 10 -Message $Commands
        $response = $null
        Write-Log "Switching To New Pool"
        $Commands = "switchpool|1"
        $response = Get-TCP -Server $AIP -Port $MinerCurrent.Port -Timeout 10 -Message $Commands
        if ($response) { $MinerProcess = @{StartTime = (Get-Date); HasExited = $false }
        }
        $MinerProcess
    }
}
