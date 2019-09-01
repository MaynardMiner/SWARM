#settings (for autofan.conf without DEF_), default values
##DEF_TARGET_TEMP=
#minimal fan speed
##DEF_MIN_FAN=30
#maximum fan speed
##DEF_MAX_FAN=100
#temperature to stop miner
##DEF_CRITICAL_TEMP=90
#action on reaching critical temp. "" to stop mining, reboot, shutdown
##DEF_CRITICAL_TEMP_ACTION=
#AMD fan control (AMD control enable-0/AMD control disable-1)
##DEF_NO_AMD=0
#Reboot rig if GPU error (enable-1/disable-0)
##DEF_REBOOT_ON_ERROR=0

Set-Alias -Name "jq" -Value ConvertFrom-Json
Set-Alias -Name "jc" -Value Convertto-Json
Set-Alias -Name "sd" -Value ConvertFrom-StringData

class variables {
    [string]$Dir = (Split-Path(Split-Path(Split-Path(Split-Path($script:MyInvocation.MyCommand.Path)))))
    [string[]]$Websites
    [PSCustomObject]$AutoFan_Conf
    $Timer

    Set_Dir() { Set-Location $this.Dir }

    Set_Configs([string]$Path1) {
        if (test-path $Path1) {
            $this.AutoFan_Conf = cat $Path1 | jq
            try { $this.AutoFan_Conf = $this.AutoFan_Conf | sd }catch { }
        }
        if ($null -eq $this.AutoFan_Conf) { Write-Host "No configs found"; exit }
    }
    
    Log() {
        $this.Timer = New-Object -Type System.Diagnostics.Stopwatch
        Start-Transcript -Path "$($this.Dir)\logs\autofan.log" 
        $This.Timer.Restart()
    }

    Log_Reset(){
        if($This.Timer.Elapsed.TotalSeconds -ge 3600){
            Write-Host ""
            Write-Host "Clearing AutoFan Log"
            Write-Host ""
            Stop-Transcript
            Start-Sleep -S 3
            Clear-Content "$($this.Dir)\logs\autofan.log" -Force
            Start-Sleep -S 3
            Start-Transcript -Path "$($this.Dir)\logs\autofan.log" 
            $This.Timer.Restart()
        }
    }

    Set_Websites() {
        if (test-path ".\config\parameters\newarguments.json") {
            $Params = cat ".\config\parameters\newarguments.json" | jq
            if ([string]$Params.Hive_Hash -ne "" -or [string]$Params.Hive_Hash -ne "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx") {
                $this.Websites += "HiveOS"
            }
            if ([string]$Params.SWARM_Hash -ne "" -or [string]$Params.SWARM_Hash -ne "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx") {
                $this.Websites += "SWARM"
            }
        }
    }
}

Class GPU {
    [String]$Model
    [Int]$Device_Number ## Actual Number On Rig. (Including Onboard)
    [Int]$Rig_Number ## HiveOS Rig Number
    [Int]$OC_Number  ## AMD slots include other model cards. NVIDIA Only Does NVIDIA cards.
    [String]$Bus_Id
    [Int]$FanSpeed
    [Int]$Deviation
    [Int]$New_Speed
    [Int]$Temperature
    [Int]$Prev_Temp = 0
    [String[]]$Errors

    GPU([String]$Model, [Int]$Device_Number, [int]$Rig_Number, [Int]$OC_Number, [string]$Bus_Id) {
        $this.Model = $Model
        $this.Device_Number = $Device_Number
        $this.Rig_Number = $Rig_Number
        $this.OC_Number = $OC_Number
        $this.Bus_Id = $Bus_Id
    }

    Calculate_Deviation([Int]$Target) {
        if ($this.Prev_Temp -ne 0 -and $this.Temperature -gt $Target) {
            if ($this.Temperature -lt $this.Prev_Temp) {
                $this.Deviation = -1
            }
            elseif ($this.Temperature -ge $this.Prev_Temp) {
                $this.Deviation = $this.Temperature - $Target - 1
            }
        }
        elseif ($this.Prev_Temp -ne 0 -and $this.Temperature -lt $Target) {
            if ($this.Temperature -gt $this.Prev_Temp) {
                $this.Deviation = 1
                if (($this.Temperature - 2) -gt $this.Prev_Temp) {
                    $this.Deviation = $this.temperature - $this.Prev_Temp
                }
            }
            elseif ($this.Temperature -le $This.Prev_Temp) {
                $this.Deviation = $this.temperature - $Target + 1
            }
        }
    }

    Set_OldTemp() {
        $this.Prev_Temp = $this.Temperature
    }

    Stat_Fan([int]$Speed) {
        if ($Speed -lt 101 -and $Speed -gt -1) {
            $this.FanSpeed = $Speed
        }
        else { $this.Errors += "No Speed" }
    }

    Stat_Temp([int]$Temp, [int]$Critical) {
        if ($temp -lt 120 -and $temp -gt 0) {
            $this.Temperature = $temp
            if ($temp -gt $Critical) { $This.Errors += "Critical" }
        } 
        elseif ($Temp -gt 120) { $This.Errors += "Unreal" }
        else { $this.Errors += "No Temp" }
    }

    Get_Speed([Int]$MinSpeed, [Int]$MaxSpeed) {
        ## This is the final desired Speed
        $speed = $this.FanSpeed + $this.Deviation
        if ($speed -gt $MaxSpeed) { $Speed = $MaxSpeed }
        if ($speed -lt $MinSpeed) { $Speed = $MinSpeed }
        $this.New_Speed = $Speed
    }

    No_Data() { $this.Errors += "No Data" }

}

## Create a Rig of GPUs
class RIG {
    [GPU[]]$GPUS
    [String[]]$Models
    [bool]$IsMinerStopped = $false

    Add_GPUs([String]$Path1, [String]$Path2) {
        $GPU_List = $(cat $Path1 | jq).params.gpu
        $GPU_OCList = cat $Path2 | jq
        $NVIDIA_Count = 0
        $AMD_Count = 0
        $Count = 0

        $GPU_List | % {
            $Sel = $_
            Switch ($Sel.Brand) {
                "nvidia" {
                    $this.GPUS += [GPU]::New($Sel.Brand, $NVIDIA_Count, $Count, $NVIDIA_Count, $Sel.busid) ## OC is same as Device Position
                    $NVIDIA_Count++
                    $Count++
                    if ("NVIDIA" -notin $this.Models) { $this.Models += "NVIDIA" }
                }
                "amd" {
                    $this.GPUS += [GPU]::New($Sel.Brand, $AMD_Count, $Count, $GPU_OCList.AMD.$AMD_Count, $Sel.busid) ## OC Number is Bus Position
                    $AMD_Count++
                    $Count++
                    if ("AMD" -notin $this.Models) { $this.Models += "AMD" }
                }
            }
        }

    }

    Get_NVIDIAGPUData([Int]$Critical) {
        $nvidiaout = ".\build\txt\nv-autofan.txt"
        $continue = $false
        try {
            if (Test-Path $nvidiaout) { clear-content $nvidiaout -ErrorAction Stop }
            $Proc = start-process ".\build\cmd\nvidia-smi.bat" -Argumentlist "--query-gpu=gpu_bus_id,power.draw,fan.speed,temperature.gpu --format=csv" -NoNewWindow -PassThru -RedirectStandardOutput $nvidiaout -ErrorAction Stop
            $Proc | Wait-Process -Timeout 5 -ErrorAction Stop 
            $continue = $true
        }
        catch { Write-Host "WARNING: Failed to get NVIDIA fans and temps" -ForegroundColor DarkRed }
        if ((Test-Path $nvidiaout) -and $continue -eq $true ) {
            $Stats = @()

            $ninfo = cat $nvidiaout | ConvertFrom-Csv | % {
                $Stats += @{ $($_.'pci.bus_id' -replace '00000000:', '') = @{
                        fan  = $( $_.'fan.speed [%]' -replace ' \%', '')
                        temp = $($_.'temperature.gpu')
                    }
                }
            }

            $This.GPUS | Where Model -eq "NVIDIA" | % {
                $_.Set_OldTemp()
                if ($Stats.$($_.Bus_Id)) {
                    $_.Stat_Temp([int]$Stats.$($_.Bus_Id).temp, [int]$Critical)
                    $_.Stat_Fan([int]$Stats.$($_.Bus_Id).fan)
                }
                else { $_.No_Data() }
            }
        }
        else {
            $This.GPUS | Where Model -eq "NVIDIA" | % {
                $_.No_Data()
            }
        }
    }

    Get_AMDGPUData([int]$Critical) {
        $amdout = ".\build\txt\amd-autofan.txt"
        $continue = $false
        try {
            if (Test-Path $amdout) { clear-content $amdout -ErrorAction Stop }
            $Proc = start-process ".\build\apps\odvii\odvii.exe" -Argumentlist "s" -NoNewWindow -PassThru -RedirectStandardOutput $amdout -ErrorAction Stop
            $Proc | Wait-Process -Timeout 5 -ErrorAction Stop 
            $continue = $true
        }
        catch { Write-Host "WARNING: Failed to get AMD fans and temps" -ForegroundColor DarkRed }
        if ((Test-Path $amdout) -and $continue -eq $true) {
            $ainfo = cat $amdout | sd
            $Cards = $This.GPUS | Where Model -eq "AMD"

            ## First Check To Make Sure All Values Are There:
            $Temps = $ainfo | Where { $_.keys -like "*Temp*" } | % { $_.Values }
            $Fans = $ainfo | Where { $_.keys -like "*Fan*" } | % { $_.Values }

            ## Add New Temperature Readings
            for ($i = 0; $i -lt $Temps.Count; $i++) {
                $this.GPUS | Where model -eq "AMD" | Where Device_Number -eq $i | % {
                    $_.Set_OldTemp(); 
                    $_.Stat_Temp($Temps[$i], $Critical) 
                } 
            }
            ## Add New Fan Readings
            for ($i = 0; $i -lt $Fans.Count; $i++) {
                $this.GPUS | Where model -eq "AMD" | Where Device_Number -eq $i | % { 
                    $_.Stat_Fan($Fans[$i]) 
                } 
            }
        }
        else {
            $This.GPUS | Where Model -eq "AMD" | % {
                $_.No_Data()
            }
        }
    }

    Get_NVIDIADeviations([Int]$Target) {
        $this.GPUS | Where model -eq "nvidia" | % {
            $_.Calculate_Deviation($Target)
        }
    }

    Get_AMDDeviations([Int]$Target) {
        $this.GPUS | Where model -eq "amd" | % {
            $_.Calculate_Deviation($Target)
        }
    }

    Get_NVIDIA_New_Speed([int]$MinSpeed, [Int]$MaxSpeed) {
        $this.GPUS | Where Model -eq "nvidia" | % {
            $_.Get_Speed($MinSpeed, $MaxSpeed)
        }
    }

    Get_AMD_New_Speed([int]$MinSpeed, [Int]$MaxSpeed) {
        $this.GPUS | Where Model -eq "amd" | % {
            $_.Get_Speed($MinSpeed, $MaxSpeed)
        }
    }

    Set_NVIDIAFanSpeed() {
        $this.GPUS | Where Model -eq "NVIDIA" | ForEach-Object {
            if ($_.New_Speed -ne $_.FanSpeed) {
                $SetFan = $null
                Invoke-Expression ".\build\apps\nvfans\nvfans.exe --index $($_.OC_Number) --speed $($_.New_Speed)" | Tee-Object -Variable SetFan
            }
        }
    }

    Set_AMDFanSpeed() {
        $this.GPUS | Where Model -eq "AMD" | ForEach-Object {
            if ($_.New_Speed -ne $_.FanSpeed) {
                $FanArgs = "-ac$($_.OC_Number) Fan_P0=80;$($_.New_Speed) Fan_P1=80;$($_.New_Speed) Fan_P2=80;$($_.New_Speed) Fan_P3=80;$($_.New_Speed) Fan_P4=80;$($_.New_Speed)"
                $Proc = Start-Process ".\build\apps\overdriventool\OverdriveNTool.exe" -ArgumentList $FanArgs -PassThru
                $Proc | Wait-Process
            }
        }
    }

    Handle_Errors([String[]]$Websites, [Int]$Reboot, [String]$Critical_Action) {
        $this.GPUS | % {
            $Errors = $_.Errors
            ## Determine Error
            if ($Errors) {
                switch ($Errors) {
                    "No Speed" {
                        switch ($Reboot) {
                            1 { $Message = "GPU driver error, no fan speed, rebooting"; $Action = 1 }
                        }
                    }
                    "No Temp" {
                        switch ($Reboot) {
                            1 { $Message = "GPU driver error, no temps, rebooting"; $Action = 1 }
                        }
                    }
                    "No Data" {
                        switch ($Reboot) {
                            1 { $Message = "GPU driver error, no data, rebooting"; $Action = 1 }
                        }
                    }
                    "Critical" {
                        switch ($Critical_Action) {
                            "shutdown" { $Message = "GPU $($_.Rig_Number) Critical- shutting down"; $Action = 2 }
                            "reboot" { $Message = "GPU $($_.Rig_Number) Critical- rebooting"; $Action = 1 }
                            default { $Message = "GPU $($_.Rig_Number) Critical- mining stopped"; $Action = 3 }
                        }
                    }
                    "Unreal" {
                        switch ($Reboot) {
                            1 { $Message = "Autofan: GPU temperature is unreal, driver error, rebooting" }
                        }
                    }
                }

                ## Notify Website:
                if ($Message -and $Websites) {
                    $Warning = @{result = @{command = "timeout" } }
                    $Message = $Message | Select -First 1
                    $Website | ForEach-Object {
                        $Sel = $_
                        try {
                            Import-Module ".\build\api\web\methods.psm1" -Global
                            Global:Get-WebModules $Sel
                            $SendToHive = Global:Start-webcommand -command $Warning -swarm_message $Message -Website "$($Sel)"
                        }
                        catch { Write-Host "WARNING: Failed To Notify $($Sel)" -ForeGroundColor Yellow }     
                    }
                }

                ## Take Action:
                if ($Action) {
                    switch ($Action) {
                        1 { Restart-Computer -Force }
                        2 { Stop-Computer -Force }
                        3 { Invoke-Expression "miner stop"; $this.IsMinerStopped = $True }
                    }
                }
                
                ## Print Errors
                Write-Host ""
                Write-Host "GPU $($_.Rig_Number): $($_.Errors)" -ForegroundColor Red
                Write-Host ""            
            }

            ## Reset Errors
            $_.Errors = $Null
        }
    }

    Restart() {
        if ($this.IsMinerStopped -eq $true) {
            $Restart = $true
            $this.GPUS.Errors | % {
                if ([string]$_ -ne "") {
                    $Restart = $false
                }
            }
            if ($Restart -eq $True) {
                Write-Host ""
                Write-Host "No Errors Found- Restarting Miner" -ForegroundColor Green
                Write-Host ""
                Invoke-Expression "miner start"
            }
        }
    }

    Print_NVIDIA_Changes(){
        if ($This.GPUS | Where Model -eq "nvidia") { Write-Host "NVIDIA GPUS:" -ForegroundColor Green }
        $This.GPUS | Where model -eq "nvidia" | % {
            Write-Host "GPU $($_.Rig_Number): " -NoNewLine
            Write-Host "Temp: $($_.Temperature), " -ForegroundColor Red -NoNewline
            Write-Host "Fan Speed: $($_.FanSpeed), " -ForegroundColor Cyan -NoNewline 
            Write-Host "Desired % Adjustment: $($_.Deviation), " -ForegroundColor Yellow -NoNewline
            Write-Host "Actual New Fan Speed %: $($_.New_Speed)" -ForegroundColor Green -NoNewline
            Write-Host ""
        }
    }

    Print_AMD_Changes(){
        if ($This.GPUS | Where Model -eq "amd") { Write-Host "AMD GPUS:" -ForegroundColor Red }
        $This.GPUS | Where model -eq "amd" | % {
            Write-Host "GPU $($_.Rig_Number): " -NoNewLine
            Write-Host "Temp: $($_.Temperature), " -ForegroundColor Red -NoNewline
            Write-Host "Fan Speed: $($_.FanSpeed), " -ForegroundColor Cyan -NoNewline 
            Write-Host "Desired % Adjustment: $($_.Deviation), " -ForegroundColor Yellow -NoNewline
            Write-Host "Actual New Fan Speed %: $($_.New_Speed)" -ForegroundColor Green -NoNewline
            Write-Host ""
        }
    }
}


## Gather Script Variables
$global:Config = [variables]::New()
$Config.Set_Dir()
$Config.Set_Configs(".\build\txt\autofan.txt")
$Config.Set_Websites()
$Config.Log()

## Build RIG
$global:RIG = [RIG]::New()
$RIG.Add_GPUs(".\build\txt\hive_hello.txt", ".\build\txt\oclist.txt")

## Print RIG stats
$Rig.GPUS | % {
    Write-Host "GPU $($_.Rig_Number): $($_.Model), Slot Number $($_.Device_Number), $($_.Model) GPU Number $($_.OC_Number)"
}

While ($True) {
    
    ## Set Config If Changed
    $config.Set_Configs(".\build\txt\autofan.txt")

    ## Refresh GPU Data
    $RIG.Get_NVIDIAGPUData($Config.AutoFan_Conf.CRITICAL_TEMP)
    if ($Config.AutoFan_Conf.No_AMD -ne 1) { $RIG.Get_AMDGPUData($Config.AutoFan_Conf.CRITICAL_TEMP) }

    ## Calculate Deviation Between Temp and Target Temp For Each GPU
    $Rig.Get_NVIDIADeviations($Config.AutoFan_Conf.TARGET_TEMP)
    if ($Config.AutoFan_Conf.No_AMD -ne 1) { $Rig.Get_AMDDeviations($Config.AutoFan_Conf.TARGET_TEMP) }

    $Rig.Get_NVIDIA_New_Speed($Config.AutoFan_Conf.MIN_FAN, $Config.AutoFan_Conf.MAX_FAN)
    if ($Config.AutoFan_Conf.No_AMD -ne 1) { $Rig.Get_AMD_New_Speed($Config.AutoFan_Conf.MIN_FAN, $Config.AutoFan_Conf.MAX_FAN) }

    ## Print Changes
    Write-Host ""
    Write-Host "Target Temp is $($Config.AutoFan_Conf.TARGET_TEMP)" -ForegroundColor "Yellow"
    $Rig.Print_NVIDIA_Changes()
    if ($Config.AutoFan_Conf.No_AMD -ne 1) { $Rig.Print_AMD_Changes() }

    ## Set New Fan Speeds
    $Rig.Set_NVIDIAFanSpeed()
    if ($Config.AutoFan_Conf.No_AMD -ne 1) { $Rig.Set_AMDFanSpeed() }

    ## Check if Miner Needs To Be Restarted
    $Rig.Restart()

    ## Handle Errors
    $Rig.Handle_Errors($Config.Websites, $Config.AutoFan_Conf.REBOOT_ON_ERROR, $Config.AutoFan_Conf.CRITICAL_TEMP_ACTION)

    ## Log Reset
    $Config.Log_Reset()

    ## Sleep
    Start-Sleep -S 10
}
