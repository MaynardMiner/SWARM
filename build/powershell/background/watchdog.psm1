function Global:Watch-Hashrate {
    $Warning = $true
    [double]$Minhashes = $Global:Config.hive_params.Wd_minhashes | Select-String "custom" | % { $_ -split "`'`{custom:" | Select -Last 1 } | % { $_ -replace "`}`'", "" }
    if ([double]$global:GPUKHS -gt $Minhashes) { $Warning = $false }
    if ($Warning -eq $true) {
        $No_Hash = [math]::Round(((Get-Date) - [datetime]$(vars).watchdog_start).TotalMinutes, 2)
        Switch ($(vars).watchdog_triggered) {
            $true {
                if ($Global:Config.hive_params.Wd_Reboot -ne "" -and $No_Hash -gt $Global:Config.hive_params.Wd_reboot) {
                    $Message = "Hashrate Watchdog: Rebooting Rig."
                    $Warning = @{result = @{command = "timeout" } }
                    if ($(vars).WebSites) {
                        $(vars).WebSites | ForEach-Object {
                            $Sel = $_
                            try {
                                Global:Add-Module "$($(vars).web)\methods.psm1"
                                Global:Get-WebModules $Sel
                                $SendToHive = Global:Start-webcommand -command $Warning -swarm_message $Message -Website "$($Sel)"
                            }
                            catch {
                                log "
WARNING: Failed To Notify $($Sel)" -ForeGroundColor Yellow 
                            } 
                            Global:Remove-WebModules $sel
                        }
                    }
                    Write-Host "
$Message" -ForegroundColor Red
                    Start-Sleep -S 3
                    $trigger = "reboot"
                    Restart-Computer -Force
                }
                elseif ($Global:Config.hive_params.WD_Reboot -ne "") {
                    Write-Host "
Watchdog: WARNING Watchdog Will Restart Computer In $( [math]::Round($Global:Config.hive_params.Wd_reboot - $No_Hash,2) ) Minutes." -ForeGroundColor Cyan
                }
            }
            $false {
                if ($Global:Config.hive_params.Wd_Miner -ne "" -and $No_Hash -gt $Global:Config.hive_params.Wd_Miner) {
                    $Message = "Hashrate Watchdog: Rebooting Miner."
                    $Warning = @{result = @{command = "timeout" } }
                    if ($(vars).WebSites) {
                        $(vars).WebSites | ForEach-Object {
                            $Sel = $_
                            try {
                                Global:Add-Module "$($(vars).web)\methods.psm1"
                                Global:Get-WebModules $Sel
                                $SendToHive = Global:Start-webcommand -command $Warning -swarm_message $Message -Website "$($Sel)"
                            }
                            catch {
                                log "
WARNING: Failed To Notify $($Sel)" -ForeGroundColor Yellow 
                            } 
                            Global:Remove-WebModules $sel
                        }
                    }
                    Write-Host "
$Message" -ForegroundColor Red
                    Start-Sleep -S 3
                    $trigger = "restart"
                }
                elseif ($Global:Config.hive_params.Wd_Miner -ne "") {
                    Write-Host "
Watchdog: WARNING Watchdog Will Restart SWARM In $( [math]::Round($Global:Config.hive_params.Wd_Miner - $No_Hash,2) ) Minutes." -ForeGroundColor Cyan
                }
            }
        }
    }
    else {
        $(vars).watchdog_triggered = $false; 
        $(vars).watchdog_start = Get-Date
        Write-Host "
Watchdog: OK" -ForegroundColor Cyan
        $Trigger = "OKAY"
    }
    if ($trigger -eq "restart") {
        Get-Date | Set-Content ".\build\txt\watchdog.txt"
        $MinerFile = ".\build\pid\miner_pid.txt"
        if (Test-Path $MinerFile) { $MinerId = Get-Process -Id (Get-Content $MinerFile) -ErrorAction SilentlyContinue }
        if ($MinerId) {
            Stop-Process $MinerId
            Start-Sleep -S 3
        }
        Start-Process ".\SWARM.bat"
        Start-Sleep -S 3
        Exit
    }

    if ($Global:Config.hive_params.WD_CHECK_GPU -eq 1) {
        if ($global:GetMiners.Count -gt 0 -and $global:GETSWARM.HasExited -eq $false) {
            for ($i = 0; $i -lt $Global:GPUHashTable.Count; $i++) {
                $NoTemp = $false
                if ([Double]$global:GPUTempTable[$i] -eq 0) { $NoTemp = $true }
                if ($NoTemp -eq $true) {
                    $Message = "GPU Watchdog: GPU $i Showing No Temps, Rebooting."
                    $Warning = @{result = @{command = "timeout" } }
                    if ($(vars).WebSites) {
                        $(vars).WebSites | ForEach-Object {
                            $Sel = $_
                            try {
                                Global:Add-Module "$($(vars).web)\methods.psm1"
                                Global:Get-WebModules $Sel
                                $SendToHive = Global:Start-webcommand -command $Warning -swarm_message $Message -Website "$($Sel)"
                            }
                            catch {
                                log "
WARNING: Failed To Notify $($Sel)" -ForeGroundColor Yellow 
                            } 
                            Global:Remove-WebModules $sel
                        }
                    }
                    Write-Host "
$Message" -ForegroundColor Red
                    Start-Sleep -S 3
                    Restart-Computer -Force
                }
            }
        }
    }
}