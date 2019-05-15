function Start-LinuxConfig {

    ## Start SWARM watchdog (for automatic shutdown)
    start-watchdog

    ## Kill Previous Screens
    start-killscript

    ## Check if this is a hive-os image
    ## If HiveOS "Yes" Connect To Hive (Not Ready Yet)
    $HiveBin = "/hive/bin"
    $Rig_File = "/hive-config/rig.conf"
    $Hive = $false
    $NotHiveOS = $false
    if (Test-Path $HiveBin) { $Hive = $true }
    if ($Hive -eq $false -and $global:Config.Params.Farm_Hash -ne "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx") {
        if (-not (Test-Path $Rig_File) ) {
            $NotHiveOS = $True
            New-Item -ItemType Directory -Name "/hive-config" -Force
        }
        ##Connect To Hive
    }

    if (Test-Path $Rig_File) {

        ## Get Hive Config
        $RigConf = Get-Content $Rig_File
        $RigConf = $RigConf | ConvertFrom-StringData                
        $global:Config.Hive_Params.HiveWorker = $RigConf.WORKER_NAME -replace "`"", ""
        $global:Config.Hive_Params.HivePassword = $RigConf.RIG_PASSWD -replace "`"", ""
        $global:Config.Hive_Params.HiveMirror = $RigConf.HIVE_HOST_URL -replace "`"", ""
        $global:Config.Hive_Params.FarmID = $RigConf.FARM_ID -replace "`"", ""
        $global:Config.Hive_Params.HiveID = $RigConf.RIG_ID -replace "`"", ""
        $global:Config.Hive_Params.Wd_enabled = $RigConf.WD_ENABLED -replace "`"", ""
        $global:Config.Hive_Params.Wd_Miner = $RigConf.WD_MINER -replace "`"", ""
        $global:Config.Hive_Params.Wd_reboot = $RigConf.WD_REBOOT -replace "`"", ""
        $global:Config.Hive_Params.Wd_minhashes = $RigConf.WD_MINHASHES -replace "`"", ""
        $global:Config.Hive_Params.Miner = $RigConf.MINER -replace "`"", ""
        $global:Config.Hive_Params.Miner2 = $RigConf.MINER2 -replace "`"", ""
        $global:Config.Hive_Params.Timezone = $RigConf.TIMEZONE -replace "`"", ""

        ## HiveOS Specific Stuff
        if ($NotHiveOS -eq $false) {
            if ($global:Config.Params.Type -like "*NVIDIA*" -or $global:Config.Params.Type -like "*AMD*") {
                Invoke-Expression ".\build\bash\libc.sh" | Tee-Object -Variable libc | Out-Null
                Invoke-Expression ".\build\bash\libv.sh" | Tee-Object -Variable libv | Out-Null
                $libc | % { write-log $_ }
                Start-Sleep -S 1
                $libv | % { write-log $_ }
                Start-Sleep -S 1
            }

            write-log "Clearing Trash Folder"
            Invoke-Expression "rm -rf .local/share/Trash/files/*" | Tee-Object -Variable trash | Out-Null
            $Trash | % { Write-Log $_ }
        }

        ## Set Cuda for commands
        if ($global:Config.Params.Type -like "*NVIDIA*") { $global:Config.Params.Cuda | Set-Content ".\build\txt\cuda.txt" }

        ## Get Total GPU Count
        $Global:GPU_Count = Get-GPUCount
    
        ## Let User Know What Platform commands will work for- Will always be Group 1.
        $global:Config.Params.Type | ForEach-Object {
            if ($_ -eq "NVIDIA1") {
                "NVIDIA1" | Out-File ".\build\txt\minertype.txt" -Force
                write-Log "Group 1 is NVIDIA- Commands and Stats will work for NVIDIA1" -foreground yellow
                Start-Sleep -S 3
            }
            if ($_ -eq "AMD1") {
                "AMD1" | Out-File ".\build\txt\minertype.txt" -Force
                write-Log "Group 1 is AMD- Commands and Stats will work for AMD1" -foreground yellow
                Start-Sleep -S 3
            }
            if ($_ -eq "CPU") {
                if ($Global:GPU_Count -eq 0) {
                    "CPU" | Out-File ".\build\txt\minertype.txt" -Force
                    write-Log "Group 1 is CPU- Commands and Stats will work for CPU" -foreground yellow
                    Start-Sleep -S 3
                }
            }
            if ($_ -eq "ASIC") {
                if ($global:GPU_Count -eq 0) {
                    "ASIC" | Out-File ".\build\txt\minertype.txt" -Force
                    write-Log "Group 1 is ASIC- Commands and Stats will work for ASIC" -foreground yellow
                }
            }
        }
    }
    
        ## Aaaaannnd...Que that sexy loading screen
        Get-SexyUnixLogo
        Start-Process ".\build\bash\screentitle.sh" -Wait    

        ##Data and Hive Configs
        write-Log "Getting Data" -ForegroundColor Yellow
        Get-Data -CmdDir $Global:Dir

        ## Set Arguments/New Parameters
        if($global:Config.Hive_Params.HiveID) {
        $global:Config.Hive_Params | ConvertTo-Json | Set-Content ".\build\txt\hivekeys.txt"
        }
}

function Start-AgentCheck {
    $Global:dir | Set-Content ".\build\cmd\dir.txt"

    ##Get current path envrionments
    $oldpath = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).path

    ##First remove old Paths, in case this is an update / new dir
    $oldpathlist = "$oldpath" -split ";"
    $oldpathlist | ForEach-Object { if ($_ -like "*SWARM*" -and $_ -notlike "*$($global:dir)\build\cmd*" ) { Set-NewPath "remove" "$($_)" } }

    if ($oldpath -notlike "*;$($global:dir)\build\cmd*") {
        write-Log "
Setting Path Variable For Commands: May require reboot to use.
" -ForegroundColor Yellow
        $newpath = "$global:dir\build\cmd"
        Set-NewPath "add" $newpath
    }
    $newpath = "$oldpath;$($global:dir)\build\cmd"
    write-Log "Stopping Previous Agent"
    $ID = ".\build\pid\background_pid.txt"
    if (Test-Path $ID) { $Agent = Get-Content $ID }
    if ($Agent) { $BackGroundID = Get-Process -id $Agent -ErrorAction SilentlyContinue }
    if ($BackGroundID.name -eq "pwsh") { Stop-Process $BackGroundID | Out-Null }
    $ID = ".\build\pid\pill_pid.txt"
    if (Test-Path $ID) { $Agent = Get-Content $ID }
    if ($Agent) { $BackGroundID = Get-Process -id $Agent -ErrorAction SilentlyContinue }
    if ($BackGroundID.name -eq "pwsh") { Stop-Process $BackGroundID | Out-Null }    
}

function Start-WindowsConfig {
    ## Add Swarm to Startup
    if ($global:Config.Params.Startup) {
        $CurrentUser = $env:UserName
        $Startup_Path = "C:\Users\$CurrentUser\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
        $Bat_Startup = Join-Path $Startup_Path "SWARM.bat"
        switch ($global:Config.Params.Startup) {
            "Yes" {
                write-Log "Attempting to add current SWARM.bat to startup" -ForegroundColor Magenta
                write-Log "If you do not wish SWARM to start on startup, use -Startup No argument"
                write-Log "Startup FilePath: $Startup_Path"
                $bat = "CMD /r pwsh -ExecutionPolicy Bypass -command `"Set-Location $global:dir; Start-Process `"SWARM.bat`"`""
                $Bat_Startup = Join-Path $Startup_Path "SWARM.bat"
                $bat | Set-Content $Bat_Startup
            }
            "No" {
                write-Log "Startup No Was Specified. Removing From Startup" -ForegroundColor Magenta
                if (Test-Path $Bat_Startup) { Remove-Item $Bat_Startup -Force }
            }    
        }
    }
    
    ##Create a CMD.exe shortcut for SWARM on desktop
    $CurrentUser = $env:UserName
    $Desk_Term = "C:\Users\$CurrentUser\desktop\SWARM-TERMINAL.bat"
    if (-Not (Test-Path $Desk_Term)) {
        write-Log "
            
    Making a terminal on desktop. This can be used for commands.
    
    " -ForegroundColor Yellow
        $Term_Script = @()
        $Term_Script += "`@`Echo Off"
        $Term_Script += "ECHO You can run terminal commands here."
        $Term_Script += "ECHO Commands such as:"
        $Term_Script += "echo.       "
        $Term_Script += "echo.       "
        $Term_Script += "ECHO       get stats"
        $Term_Script += "ECHO       get active"
        $Term_Script += "ECHO       get help"
        $Term_Script += "ECHO       benchmark timeout"
        $Term_Script += "ECHO       version query"
        $Term_Script += "echo.       "
        $Term_Script += "echo.       "
        $Term_Script += "echo.       "
        $Term_Script += "ECHO For full command list, see: https://github.com/MaynardMiner/SWARM/wiki"
        $Term_Script += "echo.       "
        $Term_Script += "echo.       "
        $Term_Script += "echo.       "
        $Term_Script += "ECHO Starting CMD.exe"
        $Term_Script += "echo.       "
        $Term_Script += "echo.       "
        $Term_Script += "echo.       "
        $Term_Script += "cmd.exe"
        $Term_Script | Set-Content $Desk_Term
    }
    
    ## Windows Bug- Set Cudas to match PCI Bus Order
    if ($global:Config.Params.Type -like "*NVIDIA*") { [Environment]::SetEnvironmentVariable("CUDA_DEVICE_ORDER", "PCI_BUS_ID", "User") }
    
    ##Set Cuda For Commands
    if ($global:Config.Params.Type -like "*NVIDIA*") { $global:Config.Params.Cuda = "10"; $global:Config.Params.Cuda | Set-Content ".\build\txt\cuda.txt" }
    
    ##Detect if drivers are installed, not generic- Close if not. Print message on screen
    if ($global:Config.Params.Type -like "*NVIDIA*" -and -not (Test-Path "C:\Program Files\NVIDIA Corporation\NVSMI\nvml.dll")) {
        write-Log "nvml.dll is missing" -ForegroundColor Red
        Start-Sleep -S 3
        write-Log "To Fix:" -ForegroundColor Blue
        write-Log "Update Windows, Purge Old NVIDIA Drivers, And Install Latest Drivers" -ForegroundColor Blue
        Start-Sleep -S 3
        write-Log "Closing Miner"
        Start-Sleep -S 1
        exit
    }
    
    ## Fetch Ram Size, Write It To File (For Commands)
    $TotalMemory = [math]::Round((Get-CimInstance -ClassName CIM_ComputerSystem).TotalPhysicalMemory / 1mb, 2) 
    $TotalMemory | Set-Content ".\build\txt\ram.txt"
    
    ## GPU Bus Hash Table
    $global:BusData = Get-BusFunctionID
    
    ## Get Total GPU HashTable
    $Global:GPU_Count = Get-GPUCount
    
    ## Say Hello To Hive
    if ($global:Config.Params.HiveOS -eq "Yes") {
        ##Note For AMD Users:
        if ($global:Config.Params.Type -like "*AMD*") {
            write-Log "
    AMD USERS: PLEASE READ .\config\oc\new_sample.json FOR INSTRUCTIONS ON OVERCLOCKING IN HIVE OS!
    " -ForegroundColor Cyan
            Start-Sleep -S 1
        }
        ## Initiate Contact
        $hiveresponse = Start-Peekaboo -Version $Version
    
        if ($hiveresponse.result) {
            $RigConf = $hiveresponse
        }
        elseif (Test-Path ".\build\txt\get-hello.txt") {
            Write-Log "WARNGING: Failed To Contact HiveOS. Using Last Known Configuration"
            Start-Sleep -S 2
            $RigConf = Get-Content ".\build\txt\get-hello.txt" | ConvertFrom-Json
        }
    
        if ($RigConf) {
            $RigConf.result | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                $Action = $_
    
                Switch ($Action) {
                    "config" {
                        $Rig = [string]$RigConf.result.config | ConvertFrom-StringData                
                        $global:Config.Hive_Params.HiveWorker = $Rig.WORKER_NAME -replace "`"", ""
                        $global:Config.Hive_Params.HivePassword = $Rig.RIG_PASSWD -replace "`"", ""
                        $global:Config.Hive_Params.HiveMirror = $Rig.HIVE_HOST_URL -replace "`"", ""
                        $global:Config.Hive_Params.FarmID = $Rig.FARM_ID -replace "`"", ""
                        $global:Config.Hive_Params.HiveID = $Rig.RIG_ID -replace "`"", ""
                        $global:Config.Hive_Params.Wd_enabled = $Rig.WD_ENABLED -replace "`"", ""
                        $global:Config.Hive_Params.Wd_Miner = $Rig.WD_MINER -replace "`"", ""
                        $global:Config.Hive_Params.Wd_reboot = $Rig.WD_REBOOT -replace "`"", ""
                        $global:Config.Hive_Params.Wd_minhashes = $Rig.WD_MINHASHES -replace "`"", ""
                        $global:Config.Hive_Params.Miner = $Rig.MINER -replace "`"", ""
                        $global:Config.Hive_Params.Miner2 = $Rig.MINER2 -replace "`"", ""
                        $global:Config.Hive_Params.Timezone = $Rig.TIMEZONE -replace "`"", ""
    
                        if (Test-Path ".\build\txt\hivekeys.txt") { $OldHiveKeys = Get-Content ".\build\txt\hivekeys.txt" | ConvertFrom-Json }
    
                        ## If password was changed- Let Hive know message was recieved
    
                        if ($OldHiveKeys) {
                            if ("$($global:Config.Hive_Params.HivePassword)" -ne "$($OldHiveKeys.HivePassword)") {
                                $method = "message"
                                $messagetype = "warning"
                                $data = "Password change received, wait for next message..."
                                $DoResponse = Add-HiveResponse -Method $method -MessageType $messagetype -Data $data -CommandID $command.result.id
                                $DoResponse = $DoResponse | ConvertTo-Json -Depth 1 -Compress
                                $SendResponse = Invoke-RestMethod "$($global:Config.Hive_Params.HiveMirror)/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
                                $SendResponse
                                $DoResponse = @{method = "password_change_received"; params = @{rig_id = $global:Config.Hive_Params.HiveID; passwd = $global:Config.Hive_Params.HivePassword }; jsonrpc = "2.0"; id = "0" }
                                $DoResponse = $DoResponse | ConvertTo-Json -Depth 1 -Compress
                                $Send2Response = Invoke-RestMethod "$mirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
                            }
                        }
    
                        ## Set Arguments/New Parameters
                        $global:Config.Hive_Params | ConvertTo-Json | Set-Content ".\build\txt\hivekeys.txt"
                    }
    
                    ##If Hive Sent OC Start SWARM OC
                    "nvidia_oc" {
                        $NewOC = $RigConf.result.nvidia_oc | ConvertTo-Json -Compress
                        $NewOC | Start-NVIDIAOC 
                    }
                    "amd_oc" {
                        $NewOC = $RigConf.result.amd_oc | ConvertTo-Json -Compress
                        $NewOC | Start-AMDOC 
                    }
                }
            }
            ## Print Data to output, so it can be recorded in transcript
            $RigConf.result.config
        }
        else {
            write-Log "No HiveOS Rig.conf- Do you have an account? Did you use your farm hash?"
            Start-Sleep -S 2
        }
    }
    ## Aaaaannnnd...Que that sexy logo. Go Time.
    Get-SexyWinLogo    

}

function Start-CrashReporting {
    if ($global:Config.Params.Platform -eq "windows") { Get-CimInstance -ClassName win32_operatingsystem | Select-Object lastbootuptime | ForEach-Object { $Boot = [math]::Round(((Get-Date) - $_.LastBootUpTime).TotalSeconds) } }
    elseif ($global:Config.Params.Platform -eq "linux") { $Boot = Get-Content "/proc/uptime" | ForEach-Object { $_ -split " " | Select-Object -First 1 } };
    if ([Double]$Boot -lt 600) {
        if ((Test-Path ".\build\txt") -and (Test-Path ".\logs")) {
            Write-Warning "SWARM was started in 600 seconds of last boot. Generating a crash report to logs directory";
            $Report = "crash_report_$(Get-Date)";
            $Report = $Report | ForEach-Object { $_ -replace ":", "_" } | ForEach-Object { $_ -replace "\/", "-" } | ForEach-Object { $_ -replace " ", "_" };
            New-Item -Path ".\logs" -Name $Report -ItemType "Directory" | Out-Null;
            Get-ChildItem ".\build\txt" | Copy-Item -Destination ".\logs\$Report";
            $TypeLogs = @("NVIDIA1", "AMD1", "NVIDIA2", "NVIDIA3", "CPU", "ASIC")
            $TypeLogs | ForEach-Object { $TypeLog = ".\logs\$($_).log"; if (Test-Path $TypeLog) { Copy-Item -Path $TypeLog -Destination ".\logs\$Report" | Out-Null } }
            $ActiveLog = Get-ChildItem "logs"; $ActiveLog = $ActiveLog.Name | Select-String "active"
            if ($ActiveLog) { if (Test-Path ".\logs\$ActiveLog") { Copy-Item -Path ".\logs\$ActiveLog" -Destination ".\logs\$Report" | Out-Null } }
            Start-Sleep -S 3
        }
    }
}

function Clear-Stats {
    $FileClear = @()
    $FileClear += ".\build\txt\minerstats.txt"
    $FileClear += ".\build\txt\mineractive.txt"
    $FileClear += ".\build\bash\hivecpu.sh"
    $FileClear += ".\build\txt\profittable.txt"
    $FileClear += ".\build\txt\bestminers.txt"
    $FileClear | ForEach-Object { if (Test-Path $_) { Remove-Item $_ -Force } }
}

function Get-Parameters {
    $Global:config.add("params", @{ })
    $Global:Config.add("user_params",@{ })
    $Global:Config.add("Hive_Params",@{})
    if (Test-Path ".\config\parameters\newarguments.json") {
        $arguments = Get-Content ".\config\parameters\newarguments.json" | ConvertFrom-Json
        $arguments.PSObject.Properties.Name | % { $global:Config.Params.Add("$($_)", $arguments.$_) }
        $arguments.PSObject.Properties.Name | % { $Global:Config.user_params.Add("$($_)", $arguments.$_) }
    }
    else {
        $arguments = Get-Content ".\config\parameters\arguments.json" | ConvertFrom-Json
        $arguments.PSObject.Properties.Name | % { $global:Config.Params.Add("$($_)", $arguments.$_) }
        $arguments.PSObject.Properties.Name | % { $Global:Config.user_params.Add("$($_)", $arguments.$_) }
        $arguments = $Null
    }
    if (Test-Path ".\build\txt\hivekeys.txt") {
        $HiveStuff = Get-Content ".\build\txt\hivekeys.txt" | ConvertFrom-Json
        $HiveStuff.PSObject.Properties.Name | % { $global:Config.Hive_Params.Add("$($_)", $HiveStuff.$_) }
    }
    if (-not $global:Config.Hive_Params.HiveID) {
        $global:Config.Hive_Params.Add("HiveID", $Null)
        $global:Config.Hive_Params.Add("HivePassword", $Null)
        $global:Config.Hive_Params.Add("HiveWorker", $Null)
        $global:Config.Hive_Params.Add("HiveMirror", "https://api.hiveos.farm")
        $global:Config.Hive_Params.Add("FarmID", $Null)
        $global:Config.Hive_Params.Add("Wd_Enabled", $null)
        $Global:config.Hive_Params.Add("Wd_miner", $Null)
        $Global:config.Hive_Params.Add("Wd_reboot", $Null)
        $Global:config.Hive_Params.Add("Wd_minhashes", $Null)
        $Global:config.Hive_Params.Add("Miner", $Null)
        $global:Config.Hive_Params.Add("Miner2", $Null)
        $global:Config.Hive_Params.Add("Timezone", $Null)
    }
}