function Global:Stop-ActiveMiners {
    $(vars).ActiveMinerPrograms | ForEach-Object {
           
        ##Miners Not Set To Run
        if ($_.BestMiner -eq $false) {
        
            if ($(arg).Platform -eq "windows") {
                if ($_.XProcess -eq $Null -and $_.Status -ne "Idle") { $_.Status = "Failed" }
                elseif ($_.XProcess.HasExited -eq $false) {
                    $_.Active += (Get-Date) - $_.XProcess.StartTime
                    if ($_.Type -notlike "*ASIC*") {
                        $Num = 0
                        $Sel = $_
                        if ($Sel.XProcess.Id) {
                            $Childs = Get-Process | Where { $_.Parent.Id -eq $Sel.XProcess.Id }
                            Write-Log "Closing all Previous Child Processes For $($Sel.Type)" -ForeGroundColor Cyan
                            $Child = $Childs | % {
                                $Proc = $_; 
                                Get-Process | Where { $_.Parent.Id -eq $Proc.Id } 
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
                                    $HiveMessage = "2 minutes miner will not close - Restarting Computer"
                                    $HiveWarning = @{result = @{command = "timeout" } }
                                    if ($(vars).WebSites) {
                                        $(vars).WebSites | ForEach-Object {
                                            $Sel = $_
                                            try {
                                                Global:Add-Module "$($(vars).web)\methods.psm1"
                                                Global:Get-WebModules $Sel
                                                $SendToHive = Global:Start-webcommand -command $HiveWarning -swarm_message $HiveMessage -Website "$($Sel)"
                                            }
                                            catch { Global:Write-Log "WARNING: Failed To Notify $($Sel)" -ForeGroundColor Yellow } 
                                            Global:Remove-WebModules $sel
                                        }
                                    }
                                    Global:Write-Log "$HiveMessage" -ForegroundColor Red
                                }
                                Restart-Computer
                            }
                        }Until($false -notin $Child.HasExited)
                        if ($Sel.SubProcesses -and $false -in $Sel.SubProcesses.HasExited) { 
                            $Sel.SubProcesses | % { $Check = $_.CloseMainWindow(); if ($Check -eq $False) { Stop-Process -Id $_.Id } }
                        }
                    }
                    else { $_.Xprocess.HasExited = $true; $_.XProcess.StartTime = $null }
                    $_.Status = "Idle"
                }
            }

            if ($(arg).Platform -eq "linux") {
                if ($_.XProcess -eq $Null -and $_.Status -ne "Idle") { $_.Status = "Failed" }
                else {
                    if ($_.Type -notlike "*ASIC*") {
                        $MinerInfo = ".\build\pid\$($_.InstanceName)_info.txt"
                        if (Test-Path $MinerInfo) {
                            $_.Status = "Idle"
                            $global:PreviousMinerPorts.$($_.Type) = "($_.Port)"
                            $MI = Get-Content $MinerInfo | ConvertFrom-Json
                            $PIDTime = [DateTime]$MI.start_date
                            $Exec = Split-Path $MI.miner_exec -Leaf
                            $_.Active += (Get-Date) - $PIDTime
                            $Proc = Start-Process "start-stop-daemon" -ArgumentList "--stop --name $Exec --pidfile $($MI.pid_path) --retry 5" -PassThru
                            $Proc | Wait-Process
                        }
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

    $(vars).BestActiveMIners | ForEach-Object {
        $Miner = $_

        if ($null -eq $Miner.XProcess -or $Miner.XProcess.HasExited -and $(arg).Lite -eq "No") {

            if($New_OC_File -eq $false -and $Miner.Type -notlike "*ASIC*" -and $Miner.Type -ne "CPU"){
                "Current OC Settings:" | Set-Content ".\build\txt\oc-settings.txt"; $New_OC_File = $true
            }

            Global:Add-Module "$($(vars).control)\launchcode.psm1"
            Global:Add-Module "$($(vars).control)\config.psm1"

            $global:Restart = $true
            if ($Miner.Type -notlike "*ASIC*") { Start-Sleep -S $Miner.Delay }
            $Miner.InstanceName = "$($Miner.Type)-$($(vars).Instance)"
            $Miner.Instance = $(vars).Instance
            $Miner.Activated++
            $(vars).Instance++

            ##First Do OC
            if ($Reason -eq "Launch") {
                ## Check for Websites, Load Modules
                if ($(vars).WebSites -and $(vars).WebSites -ne "") {
                    $GetNetMods = @($(vars).NetModules | Foreach { Get-ChildItem $_ })
                    $GetNetMods | ForEach-Object { Import-Module -Name "$($_.FullName)" }
                    $(vars).WebSites | ForEach-Object {
                        switch ($_) {
                            "HiveOS" {
                                ## Do oc if they have API key
                                if ([string]$(arg).API_Key -ne "") {

                                    ## HiveOS Can only do Group 1, while SWARM can do all three.
                                    ## If group 1 has changed, SWARM will run oc for that group. 
                                    ## If this is a different group- User is screwed for other groups.

                                    if ($Miner.Type -notlike "*ASIC*" -and $Miner.Type -ne "CPU" -and $Miner.Type -like "*1*") {
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
                    Global:Write-Log "Starting SWARM OC" -ForegroundColor Cyan
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
                    if ($Sel.XProcess.Id -ne $null) {
                        $Childs = Get-Process | Where { $_.Parent.Id -eq $Sel.XProcess.Id }
                        Write-Log "Closing all Previous Child Processes For $($Sel.Type)" -ForeGroundColor Cyan
                        $Child = $Childs | % {
                            $Proc = $_; 
                            Get-Process | Where { $_.Parent.Id -eq $Proc.Id } 
                        }
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
                                    $HiveMessage = "2 minutes miner will not close - Restarting Computer"
                                    $HiveWarning = @{result = @{command = "timeout" } }
                                    if ($(vars).WebSites) {
                                        $(vars).WebSites | ForEach-Object {
                                            $Sel = $_
                                            try {
                                                Global:Add-Module "$($(vars).web)\methods.psm1"
                                                Global:Get-WebModules $Sel
                                                $SendToHive = Global:Start-webcommand -command $HiveWarning -swarm_message $HiveMessage -Website "$($Sel)"
                                            }
                                            catch { Global:Write-Log "WARNING: Failed To Notify $($Sel)" -ForeGroundColor Yellow } 
                                            Global:Remove-WebModules $sel
                                        }
                                    }
                                    Global:Write-Log "$HiveMessage" -ForegroundColor Red
                                }
                                Restart-Computer
                            }
                        }Until($false -notin $Child.HasExited)
                    }
                    if ($Sel.SubProcesses -and $false -in $Sel.SubProcesses.HasExited) { 
                        $Sel.SubProcesses | % { $Check = $_.CloseMainWindow(); if ($Check -eq $False) { Stop-Process -Id $_.Id } }
                    }
                }
            }

            ##Launch Miners
            Global:Write-Log "Starting $($Miner.InstanceName)"
            if ($Miner.Type -notlike "*ASIC*") {
                $Miner.Xprocess = Global:Start-LaunchCode $Miner
                if ($IsWindows) {
                    $(vars).QuickTimer.restart()
                    do {
                        $Miner.SubProcesses = if ($Miner.Xprocess.Id) { Get-Process | Where { $_.Parent.ID -eq $Miner.Xprocess.Id } } else { $Null }
                        if ($Miner.Subprocesses) {
                            $Miner.SubProcesses = $Miner.SubProcesses | % { $Cur = $_.id; Get-Process | Where $_.Parent.ID -eq $Child | Where ProcessName -eq $Miner.MinerName.Replace(".exe", "") }
                        }
                        Write-Log "Getting Process Id For $($Miner.Name)"
                        Start-Sleep -S 1
                    }Until($Null -ne $Miner.SubProcesses -or $(vars).QuickTimer.Elapsed.TotalSeconds -ge 5)
                }
            }
            else {
                if ($(vars).ASICS.$($Miner.Type).IP) { $AIP = $(vars).ASICS.$($Miner.Type).IP }
                else { $AIP = "localhost" }
                $Miner.Xprocess = Global:Start-LaunchCode $Miner $AIP
            }

            ##Confirm They are Running
            if ($Miner.XProcess -eq $null -or $Miner.Xprocess.HasExited -eq $true) {
                $Miner.Status = "Failed"
                $global:NoMiners = $true
                Global:Write-Log "$($Miner.MinerName) Failed To Launch" -ForegroundColor Darkred
            }
            else {
                $Miner.Status = "Running"
                if ($Miner.Type -notlike "*ASIC*") { Global:Write-Log "Process Id is $($Miner.XProcess.ID)" }
                Global:Write-Log "$($Miner.MinerName) Is Running!" -ForegroundColor Green
                $(vars).current_procs += $Miner.Xprocess.ID
            }
        }
    }
    if ($Reason -eq "Restart" -and $global:Restart -eq $true) {
        Global:Write-Log "

    //\\  _______
   //  \\//~//.--|
   Y   /\\~~//_  |
  _L  |_((_|___L_|
 (/\)(____(_______)        

Waiting 20 Seconds For Miners To Fully Load

" 
        Start-Sleep -s 20
        $global:Restart = $false
    }
}