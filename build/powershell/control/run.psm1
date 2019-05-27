function Stop-ActiveMiners {
    $global:ActiveMinerPrograms | ForEach-Object {
           
        ##Miners Not Set To Run
        if ($_.BestMiner -eq $false) {
        
            if ($global:Config.Params.Platform -eq "windows") {
                if ($_.XProcess -eq $Null) { $_.Status = "Failed" }
                elseif ($_.XProcess.HasExited -eq $false) {
                    $_.Active += (Get-Date) - $_.XProcess.StartTime
                    if ($_.Type -notlike "*ASIC*") { $_.XProcess.CloseMainWindow() | Out-Null }
                    else { $_.Xprocess.HasExited = $true; $_.XProcess.StartTime = $null }
                    $_.Status = "Idle"
                }
            }

            if ($global:Config.Params.Platform -eq "linux") {
                if ($_.XProcess -eq $Null) { $_.Status = "Failed" }
                else {
                    if ($_.Type -notlike "*ASIC*") {
                        $MinerInfo = ".\build\pid\$($_.InstanceName)_info.txt"
                        if (Test-Path $MinerInfo) {
                            $_.Status = "Idle"
                            $PreviousMinerPorts.$($_.Type) = "($_.Port)"
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

function Start-NewMiners {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Reason
    )

    $ClearedOC = $false
    $WebSiteOC = $False
    $OC_Success = $false

    $global:BestActiveMiners | ForEach-Object {
        $Miner = $_

        if ($null -eq $Miner.XProcess -or $Miner.XProcess.HasExited -and $global:Config.Params.Lite -eq "No") {
            Import-Module "$global:Control\launchcode.psm1"
            Import-Module "$global:Control\config.psm1"
            Import-Module "$global:global\gpu.psm1"

            $global:Restart = $true
            if ($Miner.Type -notlike "*ASIC*") { Start-Sleep -S $Miner.Delay }
            $Miner.InstanceName = "$($Miner.Type)-$($global:Instance)"
            $Miner.Activated++
            $global:Instance++
            $Current = $Miner | ConvertTo-Json -Compress

            ##First Do OC
            if ($Reason -eq "Launch") {
                if ($global:Websites) {
                    $GetNetMods = @($global:NetModules | Foreach { Get-ChildItem $_ })
                    $GetNetMods | ForEach-Object { Import-Module -Name "$($_.FullName)" }
                    $global:WebSites | ForEach-Object {
                        switch ($_) {
                            "HiveOS" {
                                if ($global:Config.Params.API_Key -and $global:Config.Params.API_Key -ne "") {
                                    if ($WebSiteOC -eq $false) {
                                        if ($Miner.Type -notlike "*ASIC*" -and $Miner.Type -like "*1*") {
                                            $OC_Success = Start-HiveTune $Miner.Algo
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
                        Add-Module "$Global:Control\octune.psm1"
                        Start-OC -NewMiner $Current -Website $Website
                    }
                }
            }


            ##Launch Miners
            write-Log "Starting $($Miner.InstanceName)"
            if ($Miner.Type -notlike "*ASIC*") {
                $PreviousPorts = $PreviousMinerPorts | ConvertTo-Json -Compress
                $Miner.Xprocess = Start-LaunchCode -PP $PreviousPorts -NewMiner $Current
            }
            else {
                if ($global:ASICS.$($Miner.Type).IP) { $AIP = $global:ASICS.$($Miner.Type).IP }
                else { $AIP = "localhost" }
                $Miner.Xprocess = Start-LaunchCode -NewMiner $Current -AIP $AIP
            }

            ##Confirm They are Running
            if ($Miner.XProcess -eq $null -or $Miner.Xprocess.HasExited -eq $true) {
                $Miner.Status = "Failed"
                $global:NoMiners = $true
                write-Log "$($Miner.MinerName) Failed To Launch" -ForegroundColor Darkred
            }
            else {
                $Miner.Status = "Running"
                if ($Miner.Type -notlike "*ASIC*") { write-Log "Process Id is $($Miner.XProcess.ID)" }
                write-Log "$($Miner.MinerName) Is Running!" -ForegroundColor Green
            }
            Remove-Module -Name "launchcode"
            Remove-Module -Name "config"
            Remove-Module -Name "gpu"        
            if ($Reason -eq "Restart") {
                Write-Log "
       
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
    }
}