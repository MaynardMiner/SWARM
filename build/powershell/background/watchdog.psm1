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
                    $reason = 0
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
                    $Reason = 3
                }
            }
        }
    }
    else {
        $(vars).watchdog_triggered = $false; 
        $(vars).watchdog_start = Get-Date
        $reason = 1
        $Trigger = "OKAY"
    }
    if ($trigger -eq "restart") {
        Get-Date | Set-Content ".\build\txt\watchdog.txt"
        $MinerFile = Get-Content ".\build\pid\miner_pid.txt"
        if ($MinerFile) { $MinerId = Get-Process Where Id -eq  $MinerFile }
        if ($MinerId) {
            Stop-Process $MinerId
            Start-Sleep -S 3
        }
        Start-Process ".\SWARM.bat"
        Start-Sleep -S 3
        Exit
    }

    $BadGPU = $false

    if ($Global:Config.hive_params.WD_CHECK_GPU -eq 1) {
        if ($global:GetMiners.Count -gt 0 -and $global:GETSWARM.HasExited -eq $false) {
            for ($i = 0; $i -lt $Global:GPUHashTable.Count; $i++) {
                if ([Double]$global:GPUTempTable[$i] -le 0 -or [Double]$global:GPUPowerTable[$i] -le 0) { 
                    $BadGPU = $true
                    $This_GPU = $i
                    $reason = 2
                }
            }
        }
        if($BadGPU -eq $true){ $(vars).GPU_Bad++ }else{ $(vars).GPU_Bad = 0 }
        if ( $(vars).GPU_Bad -ge 5 ) {
            $Message = "GPU are lost, Rebooting."
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

    Switch ($Reason) {
        0 {
            Write-Host "
Watchdog: WARNING Watchdog Will Restart Computer In $( [math]::Round($Global:Config.hive_params.Wd_reboot - $No_Hash,2) ) Minutes." -ForeGroundColor Cyan        
        }
        1 {
            Write-Host "
Watchdog: OK" -ForegroundColor Cyan
        }
        2 {
            Write-Host "
GPU Watchdog: WARNING GPU $This_GPU Showing No Temps or Power." -ForeGroundColor Cyan       
        }
        3 {
            Write-Host "
Watchdog: WARNING Watchdog Will Restart SWARM In $( [math]::Round($Global:Config.hive_params.Wd_Miner - $No_Hash,2) ) Minutes." -ForeGroundColor Cyan    
        }
    }
}