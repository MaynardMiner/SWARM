<#
SWARM is open-source software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
SWARM is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>
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
    $Command = start-process "pwsh" -ArgumentList "-executionpolicy bypass -windowstyle minimized -command "".\nvoc-start.ps1""" -PassThru -WindowStyle Minimized -Wait
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
    Invoke-Expression ".\build\apps\odvii.exe s" | Tee-Object -Variable stats | OUt-Null
    $stats = $stats | ConvertFrom-StringData
    $Model = $stats.keys | % {if ($_ -like "*Model*") {$stats.$_}}
    $Default_Core_Clock = @{}
    $Default_Core_Voltage = @{}
    $Default_Mem_Clock = @{}
    $Default_Mem_Voltage = @{}
    $stats.keys | % {if ($_ -like "*Core Clock*") {$Default_Core_Clock.Add($_, $stats.$_)}}
    $stats.keys | % {if ($_ -like "*Core Voltage*") {$Default_Core_Voltage.Add($_, $stats.$_)}}
    $stats.keys | % {if ($_ -like "*Mem Clock*") {$Default_Mem_Clock.Add($_, $stats.$_)}}
    $stats.keys | % {if ($_ -like "*Mem Voltage*") {$Default_Mem_Voltage.Add($_, $stats.$_)}}



    $AMDCount = $OCCount.AMD.PSObject.Properties.Name.Count

    $AMDOCFan = $AMDOC.FAN -replace "`"", ""
    $AMDOCFAN = $AMDOCFan -split " "
    $AMDOCMem = $AMDOC.MEM_CLOCK -replace "`"", ""
    $AMDOCMem = $AMDOCMem -split " "
    $AMDOCCore = $AMDOC.CORE_CLOCK -replace "`"", ""
    $AMDOCCore = $AMDOCCore -split " "
    $AMDOCCV = $AMDOC.CORE_VDDC -replace "`"", ""
    $AMDOCCV = $AMDOCCV -split " "
    $AMDOCMV = $AMDOC.MEM_STATE -replace "`"", ""
    $AMDOCMV = $AMDOCMV -split " "
    $AMDOCV = $AMDOC.CORE_VDDC -replace "`"", ""
    $AMDOCV = $AMDOCV -split " "
    $AMDAgg = $AMDOC.AGGRESSIVE
  
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
                    if ($AMDOCFan) {
                        if ($AMDOCFAN.Count -eq 1 -and $AMDOCFAN -ne "") {
                            $OCArgs += "Fan_P0=80;$($AMDOCFan) Fan_P1=80;$($AMDOCFan) Fan_P2=80;$($AMDOCFan) Fan_P3=80;$($AMDOCFan) Fan_P4=80;$($AMDOCFan) "
                            $ocmessage += "Setting GPU $($OCCount.AMD.$i) Fan Speed To $($AMDOCFan)`%"
                        }
                        else {
                            $OCArgs += "Fan_P0=80;$($AMDOCFan[$Select]) Fan_P1=80;$($AMDOCFan[$Select]) Fan_P2=80;$($AMDOCFan[$Select]) Fan_P3=80;$($AMDOCFan[$Select]) Fan_P4=80;$($AMDOCFan[$Select]) "
                            $ocmessage += "Setting GPU $($OCCount.AMD.$i) Fan Speed To $($AMDOCFan[$i])`%"
                        }
                    }
                }
                "MEM_CLOCK" {
                    if ($AMDOCMV.Count -eq 1 -and $AMDOCMem.Count -eq 1) {
                        if ($Model[$Select] -like "*Vega*") {$PStates = 4}else {$PStates = 3}
                        $DefaultMemClock = $Default_Mem_Clock."Gpu $Select P$($PStates-1) Mem Clock"
                        $DefaultMemVolt = $Default_Mem_Voltage."Gpu $Select P$($PStates-1) Mem Voltage"
                        if ($AMDOCMem) {$MemClock = $AMDOCMem}else {$MemClock = $DefaultMemClock}
                        if ($AMDOCMV) {$MemVolt = $Default_Mem_Voltage."Gpu $Select P$AMDOCMV Mem Voltage"}else {$MemVolt = $DefaultMemVolt}
                        $OCArgs += "Mem_P$($PStates-1)=$MemClock;$MemVolt "
                        $ocmessage += "Setting GPU $($OCCount.AMD.$i) P$($PStates-1) Memory To $($MemClock), Voltage To $MemVolt"
                    }
                    else {
                        if ($Model[$Select] -like "*Vega*") {$PStates = 4}else {$PStates = 3}
                        $DefaultMemClock = $Default_Mem_Clock."Gpu $Select P$($PStates-1) Mem Clock"
                        $DefaultMemVolt = $Default_Mem_Voltage."Gpu $Select P$($PStates-1) Mem Voltage"
                        if ($AMDOCMem[$Select]) {$MemClock = $AMDOCMem[$Select]}else {$MemClock = $DefaultMemClock}
                        if ($AMDOCMV[$Select]) { $MemVolt = $Default_Mem_Voltage."Gpu $Select P$($AMDOCMV[$Select]) Mem Voltage" }else {$MemVolt = $DefaultMemVolt}
                        $OCArgs += "Mem_P$($PStates-1)=$MemClock;$MemVolt "
                        $ocmessage += "Setting GPU $($OCCount.AMD.$i) P$($PStates-1) Memory To $MemClock, Voltage To $MemVolt"
                    }
                }
                "CORE_CLOCK" {
                    $PStates = 8
                    if ($AMDOCCV.Count -eq 1 -and $AMDOCCore.Count -eq 1) {
                        if ($AMDAgg -eq 1) {
                            for ($j = 1; $j -lt $PStates; $j++) {
                                $DefaultCoreClock = $Default_Core_Clock."Gpu $Select P$j Core Clock"
                                $DefaultCoreVolt = $Default_Core_Voltage."Gpu $Select P$j Core Voltage"
                                if ($AMDOCCore) {$CoreClock = $AMDOCCore} else {$CoreClock = $DefaultCoreClock}
                                if ($AMDOCCV) {$CoreVolt = $AMDOCCV} else {$CoreVolt = $DefaultCoreVolt}
                                $OCArgs += "GPU_P$j=$CoreClock;$CoreVolt "
                                $ocmessage += "Setting GPU $($OCCount.AMD.$i) P$J Core Clock To $($CoreClock), Voltage to $CoreVolt"
                            }
                        }
                        else {
                            $DefaultCoreClock = $Default_Core_Clock."Gpu $Select P$($PStates-1) Core Clock"
                            $DefaultCoreVolt = $Default_Core_Voltage."Gpu $Select P$($PStates-1) Core Voltage"
                            if ($AMDOCCore) {$CoreClock = $AMDOCCore}else {$CoreClock = $DefaultCoreClock}
                            if ($AMDOCCV) {$CoreVolt = $AMDOCCV}else {$CoreVolt = $DefaultCoreVolt}
                            $OCArgs += "GPU_P$($PStates-1)=$CoreClock;$CoreVolt "
                            $ocmessage += "Setting GPU $($OCCount.AMD.$i) P$($PStates-1) Clock To $($CoreClock), Voltage To $CoreVolt"                     
                        }
                    }
                    else {
                        if ($AMDAgg -eq 1) {
                            for ($j = 1; $j -lt $PStates; $j++) {
                                
                                $DefaultCoreClock = $Default_Core_Clock."Gpu $Select P$j Core Clock"
                                $DefaultCoreVolt = $Default_Core_Voltage."Gpu $Select P$j Core Voltage"
                                if ($AMDOCCore[$Select]) {$CoreClock = $AMDOCCore[$Select]} else {$CoreClock = $DefaultCoreClock}
                                if ($AMDOCCV[$Select]) {$CoreVolt = $AMDOCCV[$Select]} else {$CoreVolt = $DefaultCoreVolt}
                                $OCArgs += "GPU_P$j=$CoreClock;$CoreVolt "
                                $ocmessage += "Setting GPU $($OCCount.AMD.$i) P$J Core Clock To $($CoreClock), Voltage to $CoreVolt"
                            }
                        }
                        else {
                            $DefaultCoreClock = $Default_Core_Clock."Gpu $Select P$($PStates-1) Core Clock"
                            $DefaultCoreVolt = $Default_Core_Voltage."Gpu $Select P$($PStates-1) Core Voltage"
                            if ($AMDOCCore[$Select]) {$CoreClock = $AMDOCCore[$Select]}else {$CoreClock = $DefaultCoreClock}
                            if ($AMDOCCV[$Select]) {$CoreVolt = $AMDOCCV[$Select]}else {$CoreVolt = $DefaultCoreVolt}
                            $OCArgs += "GPU_P$($PStates-1)=$CoreClock;$CoreVolt "
                            $ocmessage += "Setting GPU $($OCCount.AMD.$i) P$($PStates-1) Core Clock To $($CoreClock), Voltage To $CoreVolt"                     
                        }          
                    }
                }        
            }
        }
   
        $Script += "Start-Process `".\OverdriveNTool.exe`" -ArgumentList `"$OCArgs`" -WindowStyle Minimized -Wait"
        
    }
    Set-Location ".\build\apps"
    $Script | OUt-File "AMDOC-start.ps1"
    $Command = start-process "pwsh" -ArgumentList "-executionpolicy bypass -windowstyle minimized -command "".\AMDOC-start.ps1""" -PassThru -WindowStyle Minimized -Wait
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
        Write-Log "Starting Fans" 
        $script = @()
        $script += "`$host.ui.RawUI.WindowTitle = `'OC-Start`';"
        $script += "Invoke-Expression `'.\nvidiaInspector.exe $FanArgs`'"
        Set-Location ".\build\apps"
        $script | Out-File "fan-start.ps1"
        $Command = start-process "pwsh" -ArgumentList "-executionpolicy bypass -windowstyle minimized -command "".\fan-start.ps1""" -PassThru -WindowStyle Minimized -Wait
        Set-Location $Dir
    }
}
