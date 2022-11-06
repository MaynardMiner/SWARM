function Global:Stop-ActiveMiners {
    $(vars).ActiveMinerPrograms | ForEach-Object {
           
        ##Miners Not Set To Run
        if ($_.BestMiner -eq $false) {
        
            if ($(arg).Platform -eq "windows") {
                if ($Null -eq $_.XProcess -and $_.Status -ne "Idle") { $_.Status = "Failed" }
                elseif ($_.XProcess.HasExited -eq $false) {
                    $_.Active += (Get-Date) - $_.XProcess.StartTime
                    if ($_.Type -notlike "*ASIC*") {
                        $Num = 0
                        $Sel = $_
                        if ($Sel.XProcess.Id) {
                            $Childs = Get-Process | Where-Object { $_.Parent.Id -eq $Sel.XProcess.Id }
                            Write-Log "Closing all Previous Child Processes For $($Sel.Type)" -ForeGroundColor Cyan
                            $Child = $Childs | ForEach-Object {
                                $Proc = $_; 
                                Get-Process | Where-Object { $_.Parent.Id -eq $Proc.Id } 
                            }
                        }
                        do {
                            $Sel.XProcess.CloseMainWindow() | Out-Null
                            Start-Sleep -S 1
                            $Num++
                            if ($Num -gt 5) {
                                Write-Log "SWARM IS WAITING FOR MINER TO CLOSE. IT WILL NOT CLOSE" -ForegroundColor Red
                            }
                            if ($Num -gt 180) {
                                if ($(arg).Startup -eq "Yes") {
                                    $HiveMessage = "2 minutes $($Sel.MinerName) will not close on $($Sel.Type) - Restarting Computer"
                                    $HiveWarning = @{result = @{command = "timeout" } }
                                    if ($(vars).WebSites) {
                                        $(vars).WebSites | ForEach-Object {
                                            $Sel = $_
                                            try {
                                                Global:Add-Module "$($(vars).web)\methods.psm1"
                                                Global:Get-WebModules $Sel
                                                $SendToHive = Global:Start-webcommand -command $HiveWarning -swarm_message $HiveMessage -Website "$($Sel)"
                                            }
                                            catch { log "WARNING: Failed To Notify $($Sel)" -ForeGroundColor Yellow } 
                                            Global:Remove-WebModules $sel
                                        }
                                    }
                                    log "$HiveMessage" -ForegroundColor Red
                                }
                                Restart-Computer
                            }
                        }Until($false -notin $Child.HasExited)
                        if ($Sel.SubProcesses -and $false -in $Sel.SubProcesses.HasExited) { 
                            $Sel.SubProcesses | ForEach-Object { $Check = $_.CloseMainWindow(); if ($Check -eq $False) { Stop-Process -Id $_.Id } }
                        }
                    }
                    else { $_.Xprocess.HasExited = $true; $_.XProcess.StartTime = $null }
                    $_.Status = "Idle"
                }
            }

            ## Linux
            elseif ($(arg).Platform -eq "linux") {
                $Sel = $_
                ## Miner never started to begin with. Nothing to do here.
                if ($Null -eq $_.XProcess) { $_.Status = "Failed" }
                ## Miner is running, needs to close, but is not ASIC.
                elseif ($_.XProcess.HasExited -eq $false) {
                    ## Update Time and Status
                    $_.Status = "Idle"
                    $PIDTime = $_.Xprocess.StartTime
                    $_.Active += (Get-Date) - $PIDTime     

                    if ($_.Type -notlike "*ASIC*") {

                        ## Update ports that need to be checked later.
                        $(vars).PreviousMinerPorts.$($_.Type) = "($_.Port)"

                        ## First we need to identify all processes related
                        ## to miner. We need to make sure they are all killed
                        ## Or notate a warning to user there is an issue here.
                        $To_Kill = @()
                        $To_Kill += $_.XProcess

                        ## Get the bash process miner is launched in.
                        $Get_Screen = @()
                        $info = [System.Diagnostics.ProcessStartInfo]::new()
                        $info.FileName = "screen"
                        $info.Arguments = "-ls $($_.Type)"
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
            
                        if ($Get_Screen -like "*$($_.Type)*") {
                            [int]$Screen_ID = $($Get_Screen | Select-String $_.Type).ToString().Split('.')[0].Replace("`t", "")
                        }
                        else {
                            log "Warning- There was no screen that matches $($_.Type)" -Foreground Red
                        }
                        $Bash_ID = Get-Process | Where-Object { $_.Parent.Id -eq $Screen_Id }

                        ## Get all sub-processes
                        ## In this instance I define sub-process as processes
                        ## with the same name spawned from original process.
                        $To_KIll += Get-Process | 
                        Where-Object { $_.Parent.Id -eq $_.Xprocess.ID } | 
                        Where-Object { $_.Name -eq $_.XProcess.Name }

                        ## Get the bash process miner is launch in.
                        
                        ## Wait up to 2 minutes for process to end
                        ## Hacky-Lazy Timer style.
                        log "waiting on miner for $($_.Type) to end..." -ForegroundColor Cyan
                        $Timer = 0;
                    
                        ## Send kill signal.
                        $Proc = Start-Process "screen" -ArgumentList "-S $($_.Type) -X stuff `^C" -PassThru
                        $Proc | Wait-Process

                        ## Now wait with actions in between.
                        do {
                            Start-Sleep -S 1
                            $Timer++

                            ## ~ 10 second action
                            ## Spam there is an issue.
                            if ($Timer -gt 10) {
                                Write-Log "SWARM IS WAITING FOR MINER TO CLOSE. IT WILL NOT CLOSE" -ForegroundColor Red
                            }

                            ## ~ 2 minute action
                            if ($Timer -gt 180) {
                                ## Houston we have a problem.
                                ## Something isn't closing.
                                ## We need to let user know there is an issue.
                                ## This can break SWARM.
                                if ($(arg).Startup -eq "Yes") {
                                    $HiveMessage = "2 minutes $($Sel.MinerName) will not close on $($Sel.Type) - Restarting Computer"
                                    $HiveWarning = @{result = @{command = "timeout" } }
                                    if ($(vars).WebSites) {
                                        $(vars).WebSites | ForEach-Object {
                                            $Sel = $_
                                            try {
                                                Global:Add-Module "$($(vars).web)\methods.psm1"
                                                Global:Get-WebModules $Sel
                                                $SendToHive = Global:Start-webcommand -command $HiveWarning -swarm_message $HiveMessage -Website "$($Sel)"
                                            }
                                            catch { log "WARNING: Failed To Notify $($Sel)" -ForeGroundColor Yellow } 
                                            Global:Remove-WebModules $sel
                                        }
                                    }
                                    log "$HiveMessage" -ForegroundColor Red
                                    Invoke-Expression "reboot"
                                }
                            }
                        }until($false -notin $To_Kill.HasExited)
                    }
                    else { $_.Xprocess.HasExited = $true; $_.XProcess.StartTime = $null; $_.Status = "Idle" }
                }
            }

        }
    }
}
function Global:Start-NewMiners {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Reason
    )
    
    $OC_Success = $false
    $New_OC_File = $false

    $(vars).BestActiveMiners | ForEach-Object {
        $Miner = $_

        if ($null -eq $Miner.XProcess -or $Miner.XProcess.HasExited -and $(arg).Lite -eq "No") {

            if ($New_OC_File -eq $false -and $Miner.Type -notlike "*ASIC*" -and $Miner.Type -ne "CPU") {
                "Current OC Settings:" | Set-Content ".\debug\oc-settings.txt"; $New_OC_File = $true
            }

            Global:Add-Module "$($(vars).control)\launchcode.psm1"
            Global:Add-Module "$($(vars).control)\config.psm1"

            $(vars).Restart = $true
            if ($Miner.Type -notlike "*ASIC*") { Start-Sleep -S $Miner.Delay }
            $Miner.InstanceName = "$($Miner.Type)-$($(vars).Instance)"
            $Miner.Instance = $(vars).Instance
            $Miner.Activated++
            $(vars).Instance++

            ##First Do OC
            if ($Reason -eq "Launch") {
                ## Check for Websites, Load Modules
                if ($(vars).WebSites -and $(vars).WebSites -ne "") {
                    $GetNetMods = @($(vars).NetModules | ForEach-Object { Get-ChildItem $_ })
                    $GetNetMods | ForEach-Object { Import-Module -Name "$($_.FullName)" }
                    $(vars).WebSites | ForEach-Object {
                        switch ($_) {
                            "HiveOS" {
                                ## Do oc if they have API key
                                if ([string]$(arg).API_Key -ne "") {

                                    ## New method for OC profiles for HiveOS-
                                    ## Step 1: Grab OC profiles for all algorithms.
                                    ## Step 2: Generate an OC profile for devices based on algorithms
                                    ## Step 3: Apply custom OC Profile use HiveAPI
                                    ## This allows all device groups to have proper OC based on algorithm.

                                    ## If group 1 (NVIDIA1/AMD1) has changed, SWARM will run oc for that group
                                    ## This will applay it for all other groups.

                                    if ($Miner.Type -notlike "*ASIC*" -and $Miner.Type -ne "CPU" -and $Miner.Type -like "*1*") {
                                        $Hive_Miner_Name = $Miner.Name.replace("-1","");
                                        $OC_Success = Global:Start-HiveTune $Miner.Algo

                                        ## If it succeeded- SWARM will add to the oc_groups, which
                                        ## is a list of what OC has been done. If not, then it will
                                        ## omit, so it can attempt to run locally.
                                        if ($OC_Success -eq $true) { $(vars).oc_groups += $Miner.Type }
                                    }
                                }
                                ## However, if this isn't group one, and user has local oc settings-
                                ## It will set to false, and continue on, omitting from oc_groups.
                                else { $OC_Success = $false }
                            }
                            "SWARM" {
                                if ([string]$(arg).API_Key -ne "") {
                                    if ($Miner.Type -notlike "*ASIC*" -and $Miner.Type -ne "CPU" -and $Miner.Type -like "*1*") {
                                        ## Not implemented yet
                                        ## Code will be added here
                                        if ($OC_Success -eq $true) { $(vars).oc_groups += $Miner.Type }
                                    }
                                }
                            } else { $OC_Success = $false }
                        }
                    }
                    $GetNetMods | ForEach-Object { Remove-Module -Name "$($_.BaseName)" }
                }
                
                ## SWARM does each device group individually.
                ## However, the device group could have been done already through website.
                ## So it references the oc_groups, and if its not in it- It runs oc for that group.
                if ($Miner.Type -notlike "*ASIC*" -and $Miner.Type -ne "CPU" -and $Miner.Type -notin $(vars).oc_groups -and $(Get-Content ".\config\oc\oc-defaults.json" | ConvertFrom-Json).cards -ne "") {
                    log "Starting SWARM OC" -ForegroundColor Cyan
                    Global:Add-Module "$($(vars).control)\octune.psm1"
                    Global:Start-OC($Miner)
                    Remove-Module -name octune
                    ## OC_Success is a debug test flag at this point.
                    $OC_Success = $true
                }
            }

            ##Kill Open Miner Windows That May Still Be Open
            if ($IsWindows) {
                if ($_.Type -notlike "*ASIC*") {
                    $Num = 0
                    $Sel = $_
                    if ($null -ne $Sel.XProcess.Id) {
                        $Childs = Get-Process | Where-Object { $_.Parent.Id -eq $Sel.XProcess.Id }
                        Write-Log "Closing all Previous Child Processes For $($Sel.Type)" -ForeGroundColor Cyan
                    }
                    if ($Sel.HasExited -eq $false) {
                        do {
                            $Sel.XProcess.CloseMainWindow() | Out-Null
                            Start-Sleep -S 1
                            $Num++
                            if ($Num -gt 5) {
                                Write-Log "SWARM IS WAITING FOR MINER TO CLOSE. IT WILL NOT CLOSE" -ForegroundColor Red
                            }
                            if ($Num -gt 180) {
                                if ($(arg).Startup -eq "Yes") {
                                    $HiveMessage = "2 minutes $($Sel.MinerName) will not close on $($Sel.Type) - Restarting Computer"
                                    $HiveWarning = @{result = @{command = "timeout" } }
                                    if ($(vars).WebSites) {
                                        $(vars).WebSites | ForEach-Object {
                                            $Sel = $_
                                            try {
                                                Global:Add-Module "$($(vars).web)\methods.psm1"
                                                Global:Get-WebModules $Sel
                                                $SendToHive = Global:Start-webcommand -command $HiveWarning -swarm_message $HiveMessage -Website "$($Sel)"
                                            }
                                            catch { log "WARNING: Failed To Notify $($Sel)" -ForeGroundColor Yellow } 
                                            Global:Remove-WebModules $sel
                                        }
                                    }
                                    log "$HiveMessage" -ForegroundColor Red
                                }
                                Restart-Computer
                            }
                        }Until($false -notin $Childs.HasExited)
                    }
                    if ($Sel.SubProcesses -and $false -in $Sel.SubProcesses.HasExited) { 
                        $Sel.SubProcesses | ForEach-Object { $Check = $_.CloseMainWindow(); if ($Check -eq $False) { Stop-Process -Id $_.Id -ErrorAction Ignore } }
                    }
                }
            }

            ## Append the log of the miner if it exists to keep data low:
            $IsLog = Test-Path ".\logs\$($Miner.Name).log"
            if($IsLog) {
                $Miner_Log = Get-Content ".\logs\$($Miner.Name).log"
                if($Miner_Log.Count -ge 10000) {
                    $Split = [Math]::Round($Miner_Log.Count / 2);
                    $Miner_Log | Select-Object -last $Split | Set-Content ".\logs\$($Miner.Name).log"
                }
            }

            ##Launch Miners
            log "Starting $($Miner.InstanceName)"
            if ($Miner.Type -notlike "*ASIC*") {
                $Miner.Xprocess = Global:Start-LaunchCode $Miner
                if ($IsWindows) {
                    $(vars).QuickTimer.restart()
                    do {
                        $Miner.SubProcesses = if ($Miner.Xprocess.Id) {
                            Get-Process | 
                            Where-Object { $_.Parent.ID -eq $Miner.Xprocess.Id} |
                            Where-Object ProcessName -eq $Miner.MinerName.Replace(".exe", "")
                        } else { $Null }
                        Write-Log "Getting Process Id For $($Miner.Name)"
                        Start-Sleep -S 1
                    } Until($Null -ne $Miner.SubProcesses -or $(vars).QuickTimer.Elapsed.TotalSeconds -ge 5)
                }
            }
            else {
                if ($(vars).ASICS.$($Miner.Type).IP) { $AIP = $(vars).ASICS.$($Miner.Type).IP }
                else { $AIP = "localhost" }
                $Miner.Xprocess = Global:Start-LaunchCode $Miner $AIP
            }

            ##Confirm They are Running
            if ($null -eq $Miner.XProcess -or $Miner.Xprocess.HasExited -eq $true) {
                $Miner.Status = "Failed"
                $(vars).NoMiners = $true
                log "$($Miner.MinerName) Failed To Launch" -ForegroundColor Darkred
            }
            else {
                $Miner.Status = "Running"
                if ($Miner.Type -notlike "*ASIC*") { log "Process is $(Split-Path $Miner.Path -Leaf)[$($Miner.XProcess.ID)]" }
                if ($Miner.Type -notlike "*ASIC*") { 
                    log "$($Miner.MinerName) Is Running!" -ForegroundColor Green 
                    ## Change Process priority
                    ## It has been found that lowering priority may
                    ## Help with performance
                    ## Some miners (like cdredge) will set their
                    ## Priority to above normal- Crashing any rig with
                    ## A not-so-great CPU in Windows.
                    if ($IsWindows) {
                        if (
                            $Miner.Type -eq "NVIDIA1" -or
                            $Miner.Type -eq "NVIDIA2" -or
                            $Miner.Type -eq "NVIDIA3" -or
                            $Miner.Type -eq "AMD1"
                        ) {
                            log "Setting process priority" -ForegroundColor Cyan
                            do{
                                for ($i = 0; $i -lt $Miner.SubProcesses.Count; $i++) {
                                    $Proc = $Miner.SubProcesses[$i]
                                    if (
                                        !$Proc.HasExited -and 
                                        $Proc.PriorityClass -ne "BelowNormal"
                                    ) {
                                        $Proc.PriorityClass = "BelowNormal"
                                    }
                                    elseif ($Proc.HasExited) {
                                        $bool_array[$i] = $false
                                    }
                                    elseif ($Proc.PriorityClass -eq "BelowNormal") {
                                        $bool_array[$i] = $false
                                    }
                                }
                            } until ($Miner.SubProcesses.HasExited -notcontains $false -or $Miner.SubProcesses.PriorityClass -eq "BelowNormal")
                        }
                    }
                }
                else { log "$($Miner.Name) has successfully switched pools!" -ForeGroundColor Green }
                $(vars).current_procs += $Miner.Xprocess.ID
            }
        }
    }

    if ($Reason -eq "Restart" -and $(vars).Restart -eq $true) {
        log "

    //\\  _______
   //  \\//~//.--|
   Y   /\\~~//_  |
  _L  |_((_|___L_|
 (/\)(____(_______)        

Waiting 20 Seconds For Miners To Fully Load

" 
        Start-Sleep -s 20
        $(vars).Restart = $false
    }
}