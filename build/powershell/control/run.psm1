function Global:Stop-ActiveMiners {
    $(vars).ActiveMinerPrograms | ForEach-Object {
           
        ##Miners Not Set To Run
        if ($_.BestMiner -eq $false) {
        
            if ($(arg).Platform -eq "windows") {
                if ($_.XProcess -eq $Null) { $_.Status = "Failed" }
                elseif ($_.XProcess.HasExited -eq $false) {
                    $_.Active += (Get-Date) - $_.XProcess.StartTime
                    $N = 0
                    if ($_.Type -notlike "*ASIC*") {
                        do {
                            $N++
                            $_.XProcess.CloseMainWindow() | Out-Null 
                            Start-Sleep -S .5
                            if ($_.XProcess.HasExited -eq $False) {
                                Stop-Process -Id $_.XProcess.Id | Out-Null
                            }
                            if($N -gt 5) {
                                Write-Log "SWARM is trying to close program. It will not close." -ForegroundColor Darkred
                            }
                        }while ($_.XProcess.HasExited -eq $False)
                    }
                    else { $_.Xprocess.HasExited = $true; $_.XProcess.StartTime = $null }
                    $_.Status = "Idle"
                }
            }

            if ($(arg).Platform -eq "linux") {
                if ($_.XProcess -eq $Null) { $_.Status = "Failed" }
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
                            Start-Process "start-stop-daemon" -ArgumentList "--stop --name $Exec --pidfile $($MI.pid_path) --retry 5" -Wait
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

    $ClearedOC = $false
    $WebSiteOC = $False
    $OC_Success = $false

    $(vars).BestActiveMIners | ForEach-Object {
        $Miner = $_

        if ($null -eq $Miner.XProcess -or $Miner.XProcess.HasExited -and $(arg).Lite -eq "No") {
            Global:Add-Module "$($(vars).control)\launchcode.psm1"
            Global:Add-Module "$($(vars).control)\config.psm1"
            Global:Add-Module "$($(vars).global)\gpu.psm1"

            $global:Restart = $true
            if ($Miner.Type -notlike "*ASIC*") { Start-Sleep -S $Miner.Delay }
            $Miner.InstanceName = "$($Miner.Type)-$($(vars).Instance)"
            $Miner.Instance = $(vars).Instance
            $Miner.Activated++
            $(vars).Instance++
            $Current = $Miner | ConvertTo-Json -Compress

            ##First Do OC
            if ($Reason -eq "Launch") {
                if ($(vars).WebSites) {
                    $GetNetMods = @($(vars).NetModules | Foreach { Get-ChildItem $_ })
                    $GetNetMods | ForEach-Object { Import-Module -Name "$($_.FullName)" }
                    $(vars).WebSites | ForEach-Object {
                        switch ($_) {
                            "HiveOS" {
                                if ($(arg).API_Key -and $(arg).API_Key -ne "") {
                                    if ($WebSiteOC -eq $false) {
                                        if ($Miner.Type -notlike "*ASIC*" -and $Miner.Type -like "*1*") {
                                            $OC_Success = Global:Start-HiveTune $Miner.Algo
                                            $WebSiteOC = $true
                                        }
                                    }
                                }
                            }
                            "SWARM" {
                                $WebSiteOC = $true
                            }
                        }
                    }
                    $GetNetMods | ForEach-Object { Remove-Module -Name "$($_.BaseName)" }
                }
                if ($OC_Success -eq $false -and $WebSiteOC -eq $true) {
                    if ($ClearedOC -eq $False) {
                        $OCFile = ".\build\txt\oc-settings.txt"
                        if (Test-Path $OCFile) { Clear-Content $OcFile -Force; "Current OC Settings:" | Set-Content $OCFile }
                        $ClearedOC = $true
                    }
                    if ($Miner.Type -notlike "*ASIC*") {
                        Global:Write-Log "Starting SWARM OC" -ForegroundColor Cyan
                        Global:Add-Module "$($(vars).control)\octune.psm1"
                        Global:Start-OC -NewMiner $Current -Website $Website
                    }
                }
            }


            ##Launch Miners
            Global:Write-Log "Starting $($Miner.InstanceName)"
            if ($Miner.Type -notlike "*ASIC*") {
                $PreviousPorts = $global:PreviousMinerPorts | ConvertTo-Json -Compress
                $Miner.Xprocess = Global:Start-LaunchCode -PP $PreviousPorts -NewMiner $Current
            }
            else {
                if ($global:ASICS.$($Miner.Type).IP) { $AIP = $global:ASICS.$($Miner.Type).IP }
                else { $AIP = "localhost" }
                $Miner.Xprocess = Global:Start-LaunchCode -NewMiner $Current -AIP $AIP
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

    }
}