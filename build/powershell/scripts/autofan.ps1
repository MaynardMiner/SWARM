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
    

    Set_Dir() { Set-Location $this.Dir }

    Set_Configs([string]$Path1) {
        if (test-path $Path1) {
            $this.AutoFan_Conf = cat $Path1 | jq
            try { $this.AutoFan_Conf = $this.AutoFan_Conf | sd }catch { }
        }
        if ($null -eq $this.AutoFan_Conf) { Write-Host "No configs found"; exit }
    }
    
    Log() { Start-Transcript -Path "$($this.Dir)\logs\autofan.log" }
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
        if($this.Prev_Temp -ne 0 -and $this.Temperature -gt $Target) {
            if($this.Temperature -lt $this.Prev_Temp){
            $this.Deviation = -1
            }
            elseif($this.Temperature -ge $this.Prev_Temp) {
                $this.Deviation = $this.Temperature - $Target - 1
            }
        }
        elseif($this.Prev_Temp -ne 0 -and $this.Temperature -lt $Target) {
            if($this.Temperature -gt $this.Prev_Temp){
                $this.Deviation = 1
                if(($this.Temperature - 2) -gt $this.Prev_Temp) {
                    $this.Deviation = $this.temperature - $this.Prev_Temp
                }
            }
            elseif($this.Temperature -le $This.Prev_Temp) {
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
        if ($temp -lt 101 -and $temp -gt 0) {
            $this.Temperature = $temp
            if ($temp -gt $Critical) { $This.Errors += "Critical" }
        }
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

    Get_GPUData([Int]$Critical) {
        $this.Models | % {
            $Model = $_
            Switch ($Model) {
                "NVIDIA" {
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
                "AMD" {
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
            }
        }
    }

    Get_Deviations([Int]$Target) {
        $This.GPUS | % { $_.Calculate_Deviation($Target) }
    }

    Get_New_Speed([int]$MinSpeed, [Int]$MaxSpeed) {
        $This.GPUS | % { $_.Get_Speed($MinSpeed, $MaxSpeed) }
    }

    Set_Fan_Speed() {
        $this.Models | % {
            Switch ($_) {
                "NVIDIA" {
                    $this.GPUS | Where Model -eq "NVIDIA" | ForEach-Object {
                        if ($_.New_Speed -ne $_.FanSpeed) {
                            $SetFan = $null
                            Invoke-Expression ".\build\apps\nvfans\nvfans.exe --index $($_.OC_Number) --speed $($_.New_Speed)" | Tee-Object -Variable SetFan
                        }
                    }
                }
                "AMD" {
                    $this.GPUS | Where Model -eq "AMD" | ForEach-Object {
                        if($_.New_Speed -ne $_.FanSpeed) {
                            $FanArgs = "-ac$($_.OC_Number) Fan_P0=80;$($_.New_Speed) Fan_P1=80;$($_.New_Speed) Fan_P2=80;$($_.New_Speed) Fan_P3=80;$($_.New_Speed) Fan_P4=80;$($_.New_Speed)"
                            $Proc = Start-Process ".\build\apps\overdriventool\OverdriveNTool.exe" -ArgumentList $FanArgs -PassThru
                            $Proc | Wait-Process
                        }
                    }
                }
            }
        }
    }
}


## Gather Script Variables
$global:Config = [variables]::New()
$Config.Set_Dir()
$Config.Set_Configs(".\build\txt\autofan.txt")
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
    $RIG.Get_GPUData($Config.AutoFan_Conf.CRITICAL_TEMP)

    ## Calculate Deviation Between Temp and Target Temp For Each GPU
    $Rig.Get_Deviations($Config.AutoFan_Conf.TARGET_TEMP)
    $Rig.Get_New_Speed($Config.AutoFan_Conf.MIN_FAN, $Config.AutoFan_Conf.MAX_FAN)

    Write-Host ""
    Write-Host "Target Temp is $($Config.AutoFan_Conf.TARGET_TEMP)" -ForegroundColor "Yellow"

    $Rig.GPUS | % {
        Write-Host "GPU $($_.Rig_Number): " -NoNewLine
        Write-Host "Temp: $($_.Temperature), " -ForegroundColor Red -NoNewline
        Write-Host "Fan Speed: $($_.FanSpeed), " -ForegroundColor Cyan -NoNewline 
        Write-Host "Desired % Adjustment: $($_.Deviation), " -ForegroundColor Yellow -NoNewline
        Write-Host "Actual New Fan Speed %: $($_.New_Speed)" -ForegroundColor Green -NoNewline
        Write-Host ""
    }

    ## Set New Fan Speeds
    $Rig.Set_Fan_Speed()


    ## Handle Errors
    #$Rig.Handle_Errors()

    ## Sleep
    Start-Sleep -S 10
}
