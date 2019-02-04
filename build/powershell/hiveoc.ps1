
function Start-NVIDIAOC {
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$InputObject
    )

    $script = @()
    $script += "`$host.ui.RawUI.WindowTitle = `'OC-Start`';"
    $OcArgs = @()
    $Decompress = $NewOC | ConvertFrom-Json
    $HiveNVOC = $Decompress | ConvertFrom-StringData
    $ocmessage = @()
    $OCCount = Get-Content ".\build\txt\devicelist.txt" | ConvertFrom-JSon

    $HiveNVOC.Keys | % {
        $key = $_
        Switch ($key) {
            "FAN" {
                $NVOCFan = $HiveNVOC.FAN -replace "`"", ""
                $NVOCFAN = $NVOCFan -split " "
                if ($NVOCFAN.Count -eq 1) {
                    for ($i = 0; $i -lt $OCCount.NVIDIA.PSObject.Properties.Value.Count; $i++) {
                        $OCArgs += "-setFanSpeed:$($OCCount.NVIDIA.$i),$($NVOCFan) "
                        $ocmessage += "Setting GPU $($OCCount.NVIDIA.$i) Fan Speed To $($NVOCFan)`%"
                    }
                }
                else {
                    for ($i = 0; $i -lt $NVOCFAN.Count; $i++) {
                        $OCArgs += "-setFanSpeed:$i,$($NVOCFAN[$i]) "
                        $ocmessage += "Setting GPU $i Fan Speed To $($NVOCFan[$i])`%"
                    }
                }
            }
            "MEM" {
                $NVOCMem = $HiveNVOC.MEM -replace "`"", ""
                $NVOCMem = $NVOCMem -split " "
                if ($NVOCMem.Count -eq 1) {
                    for ($i = 0; $i -lt $OCCount.NVIDIA.PSObject.Properties.Value.Count; $i++) {
                        $OCArgs += "-setMemoryClockOffset:$($OCCount.NVIDIA.$i),0,$($NVOCMem) "
                        $ocmessage += "Setting GPU $($OCCount.NVIDIA.$i) Memory Offset To $($NVOCMem)"
                    }
                }
                else {
                    for ($i = 0; $i -lt $NVOCMem.Count; $i++) {
                        $OCArgs += "-setMemoryClockOffset:$($i),0,$($NVOCMem[$i]) "
                        $ocmessage += "Setting GPU $i Memory Offset To $($NVOCMem[$i])"
                    }
                }
            }
            "CLOCK" {
                $NVOCCore = $HiveNVOC.CLOCK -replace "`"", ""
                $NVOCCore = $NVOCCore -split " "
                if ($NVOCMem.Count -eq 1) {
                    for ($i = 0; $i -lt $OCCount.NVIDIA.PSObject.Properties.Value.Count; $i++) {
                        $OCArgs += "-setBaseClockOffset:$($OCCount.NVIDIA.$i),0,$($NVOCCore) "
                        $ocmessage += "Setting GPU $($OCCount.NVIDIA.$i) Clock Offset To $($NVOCCore)"
                    }
                }
                else {
                    for ($i = 0; $i -lt $NVOCCore.Count; $i++) {
                        $OCArgs += "-setBaseClockOffset:$($i),0,$($NVOCCore[$i]) "
                        $ocmessage += "Setting GPU $i Clock Offset To $($NVOCCore[$i])"
                    }
                }
            }
            "PLIMIT" {
                $NVOCPL = $HiveNVOC.PLIMIT -replace "`"", ""
                $NVOCPL = $NVOCPL -split " "
                if ($NVOCMem.Count -eq 1) {
                    for ($i = 0; $i -lt $OCCount.NVIDIA.PSObject.Properties.Value.Count; $i++) {
                        $OCArgs += "-setPowerTarget:$($OCCount.NVIDIA.$i),$($NVOCPL) "
                        $ocmessage += "Setting GPU $($OCCount.NVIDIA.$i) Power Limit To $($NVOCPL)"
                    }
                }
                else {
                    for ($i = 0; $i -lt $NVOCPL.Count; $i++) {
                        $OCArgs += "-setPowerTarget:$($i),$($NVOCPL[$i]) "
                        $ocmessage += "Setting GPU $i Power Limit To $($NVOCPL[$i])"
                    }
                }
            }
        }
    }

    $script += "Invoke-Expression `'.\nvidiaInspector.exe $OCArgs`'"
    Set-Location ".\build\apps"
    $script | Out-File "nvoc-start.ps1"
    $Command = start-process "powershell.exe" -ArgumentList "-executionpolicy bypass -windowstyle minimized -command "".\nvoc-start.ps1""" -PassThru -WindowStyle Minimized -Wait
    Set-Location $WorkingDir
    Start-Sleep -s .5
    $ocmessage | Set-Content ".\build\txt\ocnvidia.txt"
    Start-Sleep -S .5
    $ocmessage
}


function Start-AMDOC {
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$InputObject
    )
  
    $Decompress = $NewOC | ConvertFrom-Json
    $AMDOC = $Decompress | ConvertFrom-StringData
    $OCCount = Get-Content ".\build\txt\devicelist.txt" | ConvertFrom-JSon
    $ocmessage = @()
    $script = @()
    $script += "`$host.ui.RawUI.WindowTitle = `'OC-Start`';"

    ##Get BrandName
    Invoke-Expression ".\build\apps\odvii.exe s" | Tee-Object -Variable Model | OUt-Null
    $Model = $Model | ConvertFrom-StringData
    $Model = $Model.keys | % {if ($_ -like "*Model*") {$Model.$_}}
    $AMDCount = $OCCount.AMD.PSObject.Properties.Name.Count

    $AMDOCFan = $AMDOC.FAN -replace "`"", ""
    $AMDOCFAN = $AMDOCFan -split " "
    $AMDOCMem = $AMDOC.MEM_CLOCK -replace "`"", ""
    $AMDOCMem = $AMDOCMem -split " "
    $AMDOCCore = $AMDOC.CORE_CLOCK -replace "`"", ""
    $AMDOCCore = $AMDOCCore -split " "
    $AMDOCCV = $AMDOC.CORE_STATE -replace "`"", ""
    $AMDOCCV = $AMDOCCV -split " "
    $AMDOCCV = $AMDOC.CORE_STATE -replace "`"", ""
    $AMDOCCV = $AMDOCCV -split " "
    $AMDOCMV = $AMDOC.MEM_STATE -replace "`"", ""
    $AMDOCMV = $AMDOCMV -split " "
    $AMDOCV = $AMDOC.CORE_VDDC -replace "`"", ""
    $AMDOCV = $AMDOCV -split " "
  
    for ($i = 0; $i -lt $AMDCount; $i++) {
        $Select = $OCCount.AMD.PSOBject.Properties.Name
        $Select = $Select | Sort-Object
        $Select = $Select[$i]
        $OcArgs = $null
        $OcArgs = "-ac$($OCCount.AMD.$i) "

        $AMDOC.Keys | % {
            $key = $_
            Switch ($key) {
                "FAN" {
                    if ($AMDOCFAN.Count -eq 1) {
                        $OCArgs += "Fan_P0=80;$($AMDOCFan) Fan_P1=80;$($AMDOCFan) Fan_P2=80;$($AMDOCFan) Fan_P3=80;$($AMDOCFan) Fan_P4=80;$($AMDOCFan) "
                        $ocmessage += "Setting GPU $($OCCount.AMD.$i) Fan Speed To $($AMDOCFan)`%"
                    }
                    else {
                        $OCArgs += "Fan_P0=80;$($AMDOCFan[$Select]) Fan_P1=80;$($AMDOCFan[$Select]) Fan_P2=80;$($AMDOCFan[$Select]) Fan_P3=80;$($AMDOCFan[$Select]) Fan_P4=80;$($AMDOCFan[$Select]) "
                        $ocmessage += "Setting GPU $($OCCount.AMD.$i) Fan Speed To $($AMDOCFan[$i])`%"
                    }
                }
                "MEM_CLOCK" {
                    if ($AMDOCMem.Count -eq 1) {
                        if ($Model[$i] -like "*Vega*") {
                            $OCArgs += "Mem_P3=$AMDOCMem;$AMDOCMV "
                            $ocmessage += "Setting GPU $($OCCount.AMD.$i) Memory Offset To $($AMDOCMem), Voltage To $AMDOCMV"
                        }
                        else {
                            $OCArgs += "Mem_P2=$AMDOCMem;$AMDOCMV "
                            $ocmessage += "Setting GPU $($OCCount.AMD.$i) Memory Offset To $($AMDOCMem), Voltage To $AMDOCMV"
                        }
                    }
                    else {
                        if ($Model[$i] -like "*Vega*") {
                            $OCArgs += "Mem_P3=$($AMDOCMem[$Select]);$($AMDOCMV[$Select]) "
                            $ocmessage += "Setting GPU $($OCCount.AMD.$i) Memory Offset To $($AMDOCMem[$i]), Voltage To $($AMDOCMV[$i])"
                        }
                        else {
                            $OCArgs += "Mem_P2=$($AMDOCMem[$Select]);$($AMDOCMV[$Select]) "
                            $ocmessage += "Setting GPU $($OCCount.AMD.$i) Memory Offset To $($AMDOCMem[$i]), Voltage To $($AMDOCMV[$i])"
                        }
                    }
                }
                "CORE_CLOCK" {
                    if ($AMDOCMem.Count -eq 1) {
                        $OCArgs += "GPU_P7=$AMDOCCore;$AMDOCCV "
                        $ocmessage += "Setting GPU $($OCCount.AMD.$i) Clock Offset To $($AMDOCCore), Voltage to $AMDOCCV"
                    }
                    else {
                        $OCArgs += "GPU_P7=$($AMDOCCore[$Select]);$($AMDOCCV[$Select]) "
                        $ocmessage += "Setting GPU $($OCCount.AMD.$i) Clock Offset To $($AMDOCCore[$i]), Voltage to $($AMDOCCV[$i])"
                    }
                }
                "CORE_VDDC" {
                    if ($AMDOCV.Count -eq 1) {$Volt = "$AMDOCV"}
                    else {$Volt = "$AMDOCV[$Select]"}
                    $Value = $Volt.Substring(1)
                    if ($Volt[0] -eq "1") {$Mod = ""}
                    if ($Volt[0] -eq "2") {$Mod = "-"}
                    if ($AMDOCV.Count -eq 1) {
                    $OCArgs += "Power_Target=$Mod$Value "
                    $ocmessage += "Setting GPU $($OCCount.AMD.$i) Power Target to $Mod$Value"
                    }
                    else {
                        $OCArgs += "Power_Target=$Mod$Value "
                        $ocmessage += "Setting GPU $($OCCount.AMD.$i) Power Target to $Mod$Value"
                    }
                }
            }
        }
   
        $Script += "Start-Process `".\OverdriveNTool.exe`" -ArgumentList `"$OCArgs`" -WindowStyle Minimized -Wait"
        
    }
    Set-Location ".\build\apps"
    $Script | OUt-File "AMDOC-start.ps1"
    $Command = start-process "powershell.exe" -ArgumentList "-executionpolicy bypass -windowstyle minimized -command "".\AMDOC-start.ps1""" -PassThru -WindowStyle Minimized -Wait
    Start-Sleep -S .5
    $ocmessage
    Set-Location $WorkingDir
    $ocmessage | Set-Content ".\build\txt\ocamd.txt"
    Start-Sleep -s .5
}  

function start-fans {
    $FanFile = Get-Content ".\config\oc\oc-settings.json" | ConvertFrom-Json
    $FanArgs = @()
  
    if ($FanFile.'windows fan start') {
        $Card = $FanFile.'windows fan start' -split ' '
        for ($i = 0; $i -lt $Card.count; $i++) {$FanArgs += "-setFanSpeed:$i,$($Card[$i]) "}
        Write-Host "Starting Fans" 
        $script = @()
        $script += "`$host.ui.RawUI.WindowTitle = `'OC-Start`';"
        $script += "Invoke-Expression `'.\nvidiaInspector.exe $FanArgs`'"
        Set-Location ".\build\apps"
        $script | Out-File "fan-start.ps1"
        $Command = start-process "powershell.exe" -ArgumentList "-executionpolicy bypass -windowstyle minimized -command "".\fan-start.ps1""" -PassThru -WindowStyle Minimized
        Set-Location $Dir
    }
}
