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

<# 

There is an issue that happens in linux. It requires
a complex solution. The beautiful challenges of .NET core
in linux...

1.) All processes MUST be spawned in a emulated terminal, which screen
    is used. Each new miner is placed in a new screen. This means SWARM
    cannot -passthrough the process to get the original process ID. However,
    it DOES mean we can track a process based on the id of the parent screen
    process it is launched in. It makes it complicated, but possible.

2.) Some processes will often spawn processes that are
    not the original process. Therefor tracking a process
    by its id may cause spawned processes to go unnoticed. Their
    is many an occassion when a spawned process will not be closed
    Or SWARM tracks the spawned process rather than the original.

3.) System.Diagnostic.Process.Path may not always be the path to the 
    executable. In some cases it is the libs they are using. This makes
    it further difficult...

5.) We do not need to track subprocess when started, but we need to identify
    them when we kill the process to ensure they have closed. This is because
    buggy miners or users experiencing 'soft crashes' may have issues with
    zobmie sub-processes. Not relevant here, but noted for those trying to
    understand the difficulties.

    The solution is a three prong attack:

    1.) Keep all processes in separate screen emulations, so that each
        can be referenced to the terminal emulator they are using.
    
    2.) Track processes indirectly through the emulator it is being
        ran in
    
    3.) Identify sub-process using the information gleaned through
        the above.

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
        $Logs = Join-Path $($(vars).dir) "logs\$($MinerCurrent.Name).log" 

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
                        "wildrig-n" { $MinerArguments = "--opencl-devices $($MinerCurrent.ArgDevices) $($MinerCurrent.Arguments)" }
                        "dstm" { $MinerArguments = "--dev $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
                        "claymore" { $MinerArguments = "-di $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
                        "trex" { $MinerArguments = "-d $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
                        "ttminer" { $MinerArguments = "-d $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
                        "bminer" { $MinerArguments = "-devices $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
                        "lolminer" { $MinerArguments = "--devices $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
                        "xmrstak" { $MinerArguments = "--cuda-devices $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
                        "progminer" { $MinerArguments = "--cuda-devices $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
                        "srbmulti-n" { $MinerArguments = "$($MinerCurrent.Arguments) --gpu-id $($MinerCurrent.Devices)" }
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
                        "nanominer" { global:set-minerconfig $MinerCurrent $Logs }
                        default { $MinerArguments = "$($MinerCurrent.Arguments)" }
                    }
                }
                else {
                    switch ($MinerCurrent.DeviceCall) {
                        "excavator" {
                            $MinerDirectory = Split-Path ($MinerCurrent.Path) -Parent
                            $CommandFilePath = Join-Path $($(vars).dir) "$($MinerDirectory)\command.json"
                            $MinerArguments = "-c command.json -p $($MinerCurrent.Port)"
                            $NHDevices = Get-Content ".\debug\devicelist.txt" | ConvertFrom-Json
                            $NiceDevices = Global:Get-DeviceString -TypeCount $NHDevices.NVIDIA.Count
                            set-nicehash $($MinerCurrent.NPool) 3200 $($MinerCurrent.NUser) $($MinerCurrent.Algo) $($MinerCurrent.CommandFile) "$NiceDevices"
                        }
                        "grin-miner" { global:set-minerconfig $NewMiner $Logs }
                        "gminer" { $MinerArguments = "-d $($MinerCurrent.ArgDevices) $($MinerCurrent.Arguments)" }
                        "wildrig-n" { $MinerArguments = "--opencl-devices $($MinerCurrent.ArgDevices) $($MinerCurrent.Arguments)" }
                        "lolminer" { $MinerArguments = "--devices NVIDIA $($MinerCurrent.Arguments)" }
                        "nanominer" { global:set-minerconfig $MinerCurrent $Logs }
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
                            for($i=0; $i -lt $NewLines.Count; $i++) {
                                if ($NewLines[$i] -like "*<Connection Url =*") { $NewLines[$i] = "<Connection Url = `"stratum+tcp://$Connection`"" }
                                if ($NewLines[$i] -like "*Username =*") { $NewLines[$i] = "            Username = `"$Username`"    " }
                                if ($NewLines[$i] -like "*Password =*" ) { $NewLines[$i] = "            Password = `"$Password`">    " }
                                if ($NewLines[$i] -notlike "*<Connection Url*" -or $NewLines[$i] -notlike "*Username*" -or $NewLines[$i] -notlike "*Password*") { $NewLines[$i] }
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
                            for($i=0; $i -lt $NewLines.Count; $i++) {
                                if ($NewLines[$i] -like "*<Connection Url =*") { $NewLines[$i] = "<Connection Url = `"stratum+tcp://$Connection`"" }
                                if ($NewLines[$i] -like "*Username =*") { $NewLines[$i] = "            Username = `"$Username`"    " }
                                if ($NewLines[$i] -like "*Password =*" ) { $NewLines[$i] = "            Password = `"$Password`">    " }
                                if ($NewLines[$i] -notlike "*<Connection Url*" -or $NewLines[$i] -notlike "*Username*" -or $NewLines[$i] -notlike "*Password*") { $NewLines[$i] }
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
                elseif ($MinerCurrent.DeviceCall -eq "srbmulti-cpu") { $MinerArguments = "--cpu-threads $($MinerCurrent.Devices) $($MinerCurrent.Arguments)" }
            }
        }

        if ($(arg).Platform -eq "windows") {
            if ($null -eq $MinerProcess -or $MinerProcess.HasExited -eq $true) {
            
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
                $file = "$WorkingDirectory\swarm_start_$($Algo).ps1"
                $exec = "$PSHOME\pwsh.exe"
                $command = "`"Start-Process `"`"$exec`"`" -Verb Runas -ArgumentList `"`"-noexit -executionpolicy bypass -file `"`"`"`"$file`"`"`"`"`"`"`""
                $minerbat += "pwsh -ExecutionPolicy Bypass -command $Command"
                $miner_bat = Join-Path $WorkingDirectory "swarm_start_$($Algo).bat"
                $minerbat | Set-Content $miner_bat

                try { 
                    $NetPath = Join-Path $(vars).dir $MinerCurrent.Path.replace(".\", "")
                    $NetName = Split-Path $MinerCurrent.Path -leaf
                    $Net = Get-NetFireWallRule | Where-Object DisplayName -like "*$NetName*"
                    ## Clear old names from older versions.
                    foreach ($name in $net) {
                        if ($name.DisplayName -ne $NetPath) {
                            try {
                                Remove-NetFirewallRule -DisplayName $name.DisplayName -ErrorAction Ignore | Out-Null 
                            }
                            catch { }
                        }
                    }
                    ## Add if miner path is not listed.
                    if (-not ($net | Where-Object DisplayName -eq $NetPath)) {
                        try {
                            New-NetFirewallRule -DisplayName "$NetPath" -Direction Inbound -Program $NetPath -Action Allow -ErrorAction Ignore | Out-Null
                        }
                        catch {

                        }
                    }
                }
                catch { }

                ##Build Start Script
                if ($MinerCurrent.Prestart) {
                    $Prestart = @()
                    $Prestart += "`#`# Environment Targets"
                    $Prestart += "`$Target = [EnvironmentVariableTarget]::Process;"
                    $Prestart += "Write-Host Setting Environment Variables..."
                    $MinerCurrent.Prestart | ForEach-Object {
                        if ($_ -like "*export*" -and $_ -notlike "*export LD_LIBRARY_PATH=*") {
                            $Total = $_.replace("export ", "");
                            $Variable = $Total.Split("=")[0];
                            $Value = $Total.Split("=")[1];
                            $Prestart += "Write-Host `"$Variable=$Value`""
                            $Prestart += "[environment]::SetEnvironmentVariable(`"$Variable`",$Value,`$Target);"
                        } 
                        elseif ($_ -notlike "*export LD_LIBRARY_PATH=*") {
                            $Prestart += $_
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
                        "xmrig" {
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
                else { 
                    $start = "Invoke-Expression "".\$($MinerCurrent.MinerName) $MinerArguments""" 
                }

                $script = @()
                $script +=
                "
`#`# Window Title
`$host.ui.RawUI.WindowTitle = `'$($MinerCurrent.Name) - $($MinerCurrent.Algo)`';

`#`# set encoding for logging
`$OutputEncoding = [System.Text.Encoding]::ASCII
`#`# Has to be powershell 5.0 to set icon
 `$proc = Start-Process `"powershell`" -ArgumentList `"Set-Location ``'$($(vars).dir)``'; .\build\powershell\scripts\icon.ps1 ``'$($(vars).dir)\build\apps\icons\miner.ico``'`" -NoNewWindow -Passthru
 `$proc | Wait-Process
 remove-variable `$proc -ErrorAction Ignore

"
                foreach ($line in $Prestart) { $script += $line }
                $script += 
                "
`#`# Start Miner - Logging if needed."
                $script += $start

                $script | Out-File "$WorkingDirectory\swarm_start_$($Algo).ps1"
                Start-Sleep -S .5

                ##Start Miner Job
                $Job = Start-Job -ArgumentList $PID, $WorkingDirectory, (Convert-Path ".\build\apps\launchcode.dll"), ".\swarm_start_$($Algo).ps1", $(arg).hidden {
                    param($ControllerProcessID, $WorkingDirectory, $dll, $ps1, $Hidden)
                    Set-Location $WorkingDirectory
                    $ControllerProcess = Get-Process | Where-Object Id -eq $ControllerProcessID
                    if ($null -eq $ControllerProcess) { return }
                    Add-Type -Path $dll
                    $start = [launchcode]::New()
                    $FilePath = "$PSHome\pwsh.exe"
                    $CommandLine = '"' + $FilePath + '"'
                    $WindowStyle = "minimized"
                    if ($Hidden -eq "yes") {
                        $WindowStyle = "hidden"
                    }
                    $arguments = "-executionpolicy bypass -Windowstyle $WindowStyle -file `"$ps1`""
                    $CommandLine += " " + $arguments
                    $New_Miner = $start.New_Miner($filepath, $CommandLine, $WorkingDirectory)
                    $Process = Get-Process | Where-Object id -eq $New_Miner.dwProcessId
                    if ($null -eq $Process) { 
                        [PSCustomObject]@{ProcessId = $null }
                        return
                    }            
                    [PSCustomObject]@{ProcessId = $Process.Id; ProcessHandle = $Process.Handle };
                    $ControllerProcess.Handle | Out-Null; $Process.Handle | Out-Null; 
                    do { 
                        if ($ControllerProcess.WaitForExit(1000)) { 
                            $Process.CloseMainWindow() | Out-Null 
                        } 
                    } while ($Process.HasExited -eq $false)
                }
      
                do { Start-Sleep 1; $JobOutput = Receive-Job $Job }
                while ($null -eq $JobOutput)
      
                if ($JobOutput.ProcessId -ne 0) {
                    $Process = Get-Process | Where-Object Id -EQ $JobOutput.ProcessId
                }
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
                    
            ##Add Logging To Arguments if needed
            if ($MinerCurrent.Log -ne "miner_generated") { $MinerArgs = "$MinerArguments 2>&1 | tee `'$($MinerCurrent.Log)`'" }
            else { $MinerArgs = "$MinerArguments" }

            ##Actual Config - config.sh has already +x chmod from git.
            $LaunchScript | Set-Content ".\build\bash\config.sh" -Force

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

            ##Ensure bestminers.txt has been written (for slower storage drives)
            $FileTimer = New-Object -TypeName System.Diagnostics.Stopwatch
            $FileTimer.Restart()
            $FileChecked = $false
            do {
                $FileCheck = ".\debug\bestminers.txt"
                if (Test-Path $FileCheck) { $FileChecked = $true }
                Start-Sleep -s .1
            }until($FileChecked -eq $true -or $FileTimer.Elapsed.TotalSeconds -gt 9)
            $FileTimer.Stop()
            if ($FileChecked -eq $false) { Write-Warning "Failed To Write Miner Details To File" }

            ##Bash Script to free Port
            if ($MinerCurrent.Port -ne 0) {
                Write-Log "Clearing Miner Port `($($MinerCurrent.Port)`).." -ForegroundColor Cyan
                $proc = Start-Process ".\build\bash\killcx.sh" -ArgumentList $MinerCurrent.Port -PassThru
                try {
                    $proc | Wait-Process -Timeout 15 -ErrorAction Stop
                    log "Miner API Port Was Cleared!" -ForegroundColor Cyan
                }
                catch {
                    log "Warning: Miner API Port still listed as TIME_WAIT after 15 seconds, but launching anyway" -ForegroundColor Yellow
                    while(!$proc.HasExited) {
                        Stop-Process $proc
                        Start-Sleep -S .5
                        log "Stopping killcx" -Foreground Yellow
                    }
                }
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
            $Script += "screen -S $($MinerCurrent.Type) -X stuff $`"$MinerEXE $MinerArgs\n`""
            $TestScript += "$MinerEXE $MinerArgs"

            ##Write Both Scripts
            $Script | Set-Content ".\build\bash\startup.sh"
            ## Test config for users.
            $Algo = ($MinerCurrent.Algo).Replace("`/", "_")
            $TestScript | Set-Content "$MinerDir/swarm_start_$($Algo).sh"
    
            ## Run HiveOS hugepages commmand if algo is randomx
            if (
                $MinerCurrent.algo -eq "randomx" -and
                $(arg).HiveOS -eq "Yes"
            ) {
                log "Setting HiveOS hugepages for RandomX" -ForegroundColor Cyan
                Invoke-Expression "hugepages -rx"
            }

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

            ## A screen should have started that is titled the name of the Type
            ## of the device. We must identify the process id. We so this with
            ## a simple parsing of screen list.
            $Get_Screen = @()
            $info = [System.Diagnostics.ProcessStartInfo]::new()
            $info.FileName = "screen"
            $info.Arguments = "-ls $($MinerCurrent.Type)"
            $info.UseShellExecute = $false
            $info.RedirectStandardOutput = $true
            $info.Verb = "runas"
            $Proc = [System.Diagnostics.Process]::New()
            $proc.StartInfo = $Info
            $timer = [System.Diagnostics.Stopwatch]::New()
            $timer.Restart();
            $proc.Start() | Out-Null
            while (-not $Proc.StandardOutput.EndOfStream) {
                $Get_Screen += $Proc.StandardOutput.ReadLine();
                if ($timer.Elapsed.Seconds -gt 15) {
                    $proc.kill() | Out-Null;
                    break;
                }
            }
            $Proc.Dispose();            

            ## User showed an error that there was no miner screen, and I don't know why.
            ## Make an error generate if there is not a screen that matches current type
            if ($Get_Screen -like "*$($MinerCurrent.Type)*") {
                [int]$Screen_ID = $($Get_Screen | Select-String $MinerCurrent.Type).ToString().Split('.')[0].Replace("`t", "")
            }
            else {
                log "Warning- There was no screen that matches $($MinerCurrent.Type)" -Foreground Red
            }
            
            ## Now that we have a list of all Process with the name of the exectuable.
            ## We used bash to launch the miner, so the parent of the core process
            ## should be 'bash'.
            ## That bash process should have a parent process of the screen ID.
            ## This means we are looking for the parent ID of the parent process should
            ## match the screen Screen_ID.
            ## Since SWARM did not launch this process, there may be a delay in launch.
            ## So we need to check for a set time.
            $MinerTimer.Restart()

            Do {

                Start-Sleep -S 1
                #Write We Are getting ID
                log "Getting Process ID for $($MinerCurrent.MinerName)"
                ## Now we get all plausible process id's based on miner name
                $Miner_IDs = Get-Process | Where-Object Name -eq  (Split-Path $MinerEXE -Leaf)
                ## We search the parent process's parent ID.
                $MinerProcess = $Miner_IDs | Where-Object { $($_.Parent).Parent.Id -eq $Screen_ID }

            }until($null -ne $MinerProcess -or ($MinerTimer.Elapsed.TotalSeconds) -ge 10)  
            ##Stop Timer
            $MinerTimer.Stop()

            ## New Ubuntu Miners may not close if the Emulation window closes.
            ## So on exit- We have to find and close these miners (background agent does that)
            if ($MinerProcess) {
                ##PID Tracking Path & Date
                $PIDInfoPath = Join-Path $($(vars).dir) "build\pid\$($MinerCurrent.InstanceName)_info.txt"
                $PIDInfo = @{miner_exec = "$MinerEXE"; start_date = "$StartDate"; pid = "$($MinerProcess.Id)"; }
            
                $PIDInfo | ConvertTo-Json | Set-Content $PIDInfoPath
            }

            $MinerProcess
        }
    }
    else {
        ## ASIC is not a process. So we create an artifical tracking system based on
        ## the data gleaned through TCP. We run switchpool api command, and confirm
        ## That the pool has changed. If it has, we change the start-date to are artifical.
        ## Tracking system, which is how we confirm that it has changed.
        ## Essentially the date-stamp is our ID.
        ## The fact that TCP responds in our nofication that the ASIC is running (HasExited)

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
