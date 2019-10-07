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
function Global:Start-NVIDIAOC($NewOC) {

    $script = @()
    $script += "`$host.ui.RawUI.WindowTitle = `'OC-Start`';"
    $OcArgs = @()
    $HiveNVOC = $NewOC | ConvertFrom-StringData
    $ocmessage = @()
    $OCCount = Get-Content ".\build\txt\oclist.txt" | ConvertFrom-JSon
    $FansArgs = @()

    ## Get Power limits
    $Max_Power = invoke-expression "nvidia-smi --query-gpu=power.max_limit --format=csv" | ConvertFrom-CSV
    $Max_Power = $Max_Power.'power.max_limit [W]' | % { $_ = $_ -replace " W", ""; $_ }

    $HiveNVOC.Keys | % {
        $key = $_
        Switch ($key) {
            "OHGODAPILL_ENABLED" {
                if ($HiveNVOC.OHGODAPILL_ENABLED -eq 1) {
                    $PillArg = $HiveNVOC.OHGODAPILL_ARG
                    $PillDelay = $HiveNVOC.RUNNING_DELAY
                    $PillProc = Get-Process -Name "OhGodAnETHlargementPill-r2" -ErrorAction SilentlyContinue
                    if ($PillProc) { $PillProc | % { Stop-Process -Id $_.ID } }
                    if ($HiveNVOC.OHGODAPILL_START_TIMEOUT -gt 0) { $Sleep = "timeout $($HiveNVOC.OHGODAPILL_START_TIMEOUT) > NUL" }
                    $Script = @()
                    $Script += "$Sleep"
                    $Script += "start /min `"`" `"$($(vars).dir)\build\apps\ohgodatool\OhGodAnETHlargementPill-r2.exe`" $PillArg"
                    $Script | Set-Content ".\build\apps\pill.bat"
                    $Process = Start-Process ".\build\apps\pill.bat" -WindowStyle Minimized
                }
                else {
                    $PillProc = Get-Process -Name "OhGodAnETHlargementPill-r2" -ErrorAction SilentlyContinue
                    if ($PillProc) { $PillProc | % { Stop-Process -Id $_.ID } }
                }
            }
            "FAN" {
                $NVOCFan = $HiveNVOC.FAN -replace "`"", ""
                if ([string]$NVOCFan -ne "") {
                    $NVOCFAN = $NVOCFan -split " "
                    if ($NVOCFAN.Count -eq 1) {
                        for ($i = 0; $i -lt $OCCount.NVIDIA.PSObject.Properties.Value.Count; $i++) {
                            $FansArgs += "--index $i --speed $($NVOCFan)"
                            $ocmessage += "Setting GPU $($OCCount.NVIDIA.$i) Fan Speed To $($NVOCFan)`%"
                        }
                    }
                    else {
                        for ($i = 0; $i -lt $NVOCFAN.Count; $i++) {
                            $FansArgs += "--index $i --speed $($NVOCFan[$i])"
                            $ocmessage += "Setting GPU $i Fan Speed To $($NVOCFan[$i])`%"
                        }
                    }
                }
            }
            "MEM" {
                $NVOCMem = $HiveNVOC.MEM -replace "`"", ""
                if ([string]$NVOCMem -ne "") {
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
            }
            "CLOCK" {
                $NVOCCore = $HiveNVOC.CLOCK -replace "`"", ""
                if ([string]$NVOCCore -ne "") {
                    $NVOCCore = $NVOCCore -split " "
                    if ($NVOCCore.Count -eq 1) {
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
            }
            "PLIMIT" {
                $NVOCPL = $HiveNVOC.PLIMIT -replace "`"", ""
                if ([string]$NVOCPL -ne "") {
                    $NVOCPL = $NVOCPL -split " "
                    if ($NVOCPL.Count -eq 1) {
                        for ($i = 0; $i -lt $OCCount.NVIDIA.PSObject.Properties.Value.Count; $i++) {
                            [Double]$Max = $Max_Power[$i]
                            [Double]$Value = $NVOCPL | % { iex $_ }  ## String to double/int issue.
                            [Double]$Limit = [math]::Round(($Value / $Max) * 100, 0)
                            $OCArgs += "-setPowerTarget:$($OCCount.NVIDIA.$i),$($Limit) "
                            $ocmessage += "Setting GPU $($OCCount.NVIDIA.$i) Power Limit To $($Limit)%"
                        }
                    }
                    else {
                        for ($i = 0; $i -lt $NVOCPL.Count; $i++) {
                            [Double]$Max = $Max_Power[$i]
                            [Double]$Value = $NVOCPL[$i] | % { iex $_ } ## String to double/int issue.
                            [Double]$Limit = [math]::Round(($Value / $Max) * 100, 0)
                            $OCArgs += "-setPowerTarget:$($i),$($Limit) "
                            $ocmessage += "Setting GPU $i Power Limit To $($Limit)%"
                        }
                    }
                }
            }
        }
    }

    if ([string]$OcArgs -ne "") {
        $script += "Invoke-Expression `'.\inspector\nvidiaInspector.exe $OCArgs`'"
        if ($FansArgs) { $FansArgs | ForEach-Object { $script += "Invoke-Expression `'.\nvfans\nvfans.exe $($_)`'" } }
        $ScriptFile = "$($(vars).dir)\build\apps\hive_nvoc_start.ps1"
        $Script | OUt-File $ScriptFile
        $start = [launchcode]::New()
        $FilePath = "$PSHome\pwsh.exe"
        $CommandLine = '"' + $FilePath + '"'
        $arguments = "-executionpolicy bypass -command `"$ScriptFile`""
        $CommandLine += " " + $arguments
        $start_oc = $start.New_Miner($filepath, $CommandLine, (split-path $ScriptFile))
        $Proc = Get-Process -id $start_oc.dwProcessId -ErrorAction Ignore
        $Proc | Wait-Process
        $ocmessage
        $ocmessage | Set-Content ".\build\txt\ocnvidia.txt"
    }
}


function Global:Start-AMDOC($NewOC) {
  
    $AMDOC = $NewOC | ConvertFrom-StringData
    $OCCount = Get-Content ".\build\txt\oclist.txt" | ConvertFrom-JSon
    $ocmessage = @()
    $script = @()
    $script += "`$host.ui.RawUI.WindowTitle = `'OC-Start`';"

    ##Get BrandName
    Invoke-Expression ".\build\apps\odvii\odvii.exe s" | Tee-Object -Variable stats | OUt-Null
    $stats = $stats | ConvertFrom-StringData
    $Model = $stats.keys | % { if ($_ -like "*Model*") { $stats.$_ } }
    $Default_Core_Clock = @{ }
    $Default_Core_Voltage = @{ }
    $Default_Mem_Clock = @{ }
    $Default_Mem_Voltage = @{ }
    $stats.keys | % { if ($_ -like "*Core Clock*") { $Default_Core_Clock.Add($_, $stats.$_) } }
    $stats.keys | % { if ($_ -like "*Core Voltage*") { $Default_Core_Voltage.Add($_, $stats.$_) } }
    $stats.keys | % { if ($_ -like "*Mem Clock*") { $Default_Mem_Clock.Add($_, $stats.$_) } }
    $stats.keys | % { if ($_ -like "*Mem Voltage*") { $Default_Mem_Voltage.Add($_, $stats.$_) } }



    $AMDCount = $OCCount.AMD.PSObject.Properties.Name.Count

    $AMDOCFan = $AMDOC.FAN -replace "`"", ""
    $AMDOCFAN = $AMDOCFan -split " "
    $AMDOCCore = $AMDOC.CORE_CLOCK -replace "`"", ""
    $AMDOCCore = $AMDOCCore -split " "
    $AMDOCCV = $AMDOC.CORE_VDDC -replace "`"", ""
    $AMDOCCV = $AMDOCCV -split " "
    $AMDOCMem = $AMDOC.MEM_CLOCK -replace "`"", ""
    $AMDOCMem = $AMDOCMem -split " "
    $AMDOCMV = $AMDOC.MEM_STATE -replace "`"", ""
    $AMDOCMV = $AMDOCMV -split " "
    $AMDAgg = $AMDOC.AGGRESSIVE
    $AMDREF = $AMDOC.REF -replace "`"", ""
    $AMDREF = $AMDREF -split " "
  
    for ($i = 0; $i -lt $AMDCount; $i++) {
        $Select = $OCCount.AMD.PSOBject.Properties.Name
        $Select = $Select | Sort-Object
        $Select = $Select[$i]
        $OcArgs += "-ac$($OCCount.AMD.$i) "

        $AMDOC.Keys | % {
            $key = $_
            Switch ($key) {
                "FAN" {
                    if ([string]$AMDOCFan -ne "") {
                        if ($AMDOCFAN.Count -eq 1 -and $AMDOCFAN -ne "") {
                            $OCArgs += "Fan_ZeroRPM=0; Fan_P0=80;$($AMDOCFan) Fan_P1=80;$($AMDOCFan) Fan_P2=80;$($AMDOCFan) Fan_P3=80;$($AMDOCFan) Fan_P4=80;$($AMDOCFan) "
                            $ocmessage += "Setting GPU $($OCCount.AMD.$i) Fan Speed To $($AMDOCFan)`%"
                        }
                        else {
                            $OCArgs += "Fan_ZeroRPM=0 Fan_P0=80;$($AMDOCFan[$Select]) Fan_P1=80;$($AMDOCFan[$Select]) Fan_P2=80;$($AMDOCFan[$Select]) Fan_P3=80;$($AMDOCFan[$Select]) Fan_P4=80;$($AMDOCFan[$Select]) "
                            $ocmessage += "Setting GPU $($OCCount.AMD.$i) Fan Speed To $($AMDOCFan[$i])`%"
                        }
                    }
                }
                "MEM_CLOCK" {
                    if ($AMDOCMem.Count -eq 1) {
                        if ($Model[$Select] -like "*Vega*") { $PStates = 4 }else { $PStates = 3 }
                        $DefaultMemVolt = $Default_Mem_Voltage."Gpu $Select P$($PStates-1) Mem Voltage"
                        $MemClock = $AMDOCMem
                        if ($AMDOCMV) { $MemVolt = $Default_Mem_Voltage."Gpu $Select P$AMDOCMV Mem Voltage" }else { $MemVolt = $DefaultMemVolt }
                        $OCArgs += "Mem_P$($PStates-1)=$MemClock;$MemVolt "
                        $ocmessage += "Setting GPU $($OCCount.AMD.$i) P$($PStates-1) Memory To $($MemClock), Voltage To $MemVolt"
                    }
                    else {
                        if ($Model[$Select] -like "*Vega*") { $PStates = 4 }else { $PStates = 3 }
                        $DefaultMemVolt = $Default_Mem_Voltage."Gpu $Select P$($PStates-1) Mem Voltage"
                        $MemClock = $AMDOCMem[$Select]
                        if ($AMDOCMV[$Select]) { $MemVolt = $Default_Mem_Voltage."Gpu $Select P$($AMDOCMV[$Select]) Mem Voltage" }else { $MemVolt = $DefaultMemVolt }
                        $OCArgs += "Mem_P$($PStates-1)=$MemClock;$MemVolt "
                        $ocmessage += "Setting GPU $($OCCount.AMD.$i) P$($PStates-1) Memory To $MemClock, Voltage To $MemVolt"
                    }
                }
                "CORE_CLOCK" {
                    $PStates = 8
                    if ($AMDOCCore.Count -eq 1) {
                        if ($AMDAgg -eq 1) {
                            for ($j = 1; $j -lt $PStates; $j++) {
                                $DefaultCoreVolt = $Default_Core_Voltage."Gpu $Select P$j Core Voltage"
                                $CoreClock = $AMDOCCore
                                if ($AMDOCCV) { $CoreVolt = $AMDOCCV } else { $CoreVolt = $DefaultCoreVolt }
                                $OCArgs += "GPU_P$j=$CoreClock;$CoreVolt "
                                $ocmessage += "Setting GPU $($OCCount.AMD.$i) P$J Core Clock To $($CoreClock), Voltage to $CoreVolt"
                            }
                        }
                        else {
                            $DefaultCoreVolt = $Default_Core_Voltage."Gpu $Select P$($PStates-1) Core Voltage"
                            $CoreClock = $AMDOCCore
                            if ($AMDOCCV) { $CoreVolt = $AMDOCCV }else { $CoreVolt = $DefaultCoreVolt }
                            $OCArgs += "GPU_P$($PStates-1)=$CoreClock;$CoreVolt "
                            $ocmessage += "Setting GPU $($OCCount.AMD.$i) P$($PStates-1) Clock To $($CoreClock), Voltage To $CoreVolt"                     
                        }
                    }
                    else {
                        if ($AMDAgg -eq 1) {
                            for ($j = 1; $j -lt $PStates; $j++) {
                                $DefaultCoreVolt = $Default_Core_Voltage."Gpu $Select P$j Core Voltage"
                                $CoreClock = $AMDOCCore[$Select]
                                if ($AMDOCCV[$Select]) { $CoreVolt = $AMDOCCV[$Select] } else { $CoreVolt = $DefaultCoreVolt }
                                $OCArgs += "GPU_P$j=$CoreClock;$CoreVolt "
                                $ocmessage += "Setting GPU $($OCCount.AMD.$i) P$J Core Clock To $($CoreClock), Voltage to $CoreVolt"
                            }
                        }
                        else {
                            $DefaultCoreVolt = $Default_Core_Voltage."Gpu $Select P$($PStates-1) Core Voltage"
                            $CoreClock = $AMDOCCore[$Select]
                            if ($AMDOCCV[$Select]) { $CoreVolt = $AMDOCCV[$Select] }else { $CoreVolt = $DefaultCoreVolt }
                            $OCArgs += "GPU_P$($PStates-1)=$CoreClock;$CoreVolt "
                            $ocmessage += "Setting GPU $($OCCount.AMD.$i) P$($PStates-1) Core Clock To $($CoreClock), Voltage To $CoreVolt"                     
                        }          
                    }
                } 
                "CORE_VDDC" {
                    ## Only do if core wasn't set
                    if ($AMDOCCore.Count -eq 0) {
                        if ($AMDOCCV.Count -eq 1) {
                            if ($AMDAgg -eq 1) {
                                for ($j = 1; $j -lt $PStates; $j++) {
                                    $DefaultCoreClock = $Default_Core_Clock."Gpu $Select P$($PStates-1) Core Clock"
                                    $CoreVolt = $AMDOCCV
                                    $CoreClock = $DefaultCoreClock
                                    $OCArgs += "GPU_P$j=$CoreClock;$CoreVolt "
                                    $ocmessage += "Setting GPU $($OCCount.AMD.$i) P$J Core Clock To $($CoreClock), Voltage to $CoreVolt"
                                }
                            }
                            else {
                                $DefaultCoreClock = $Default_Core_Clock."Gpu $Select P$($PStates-1) Core Clock"
                                $CoreVolt = $AMDOCCV
                                $CoreClock = $DefaultCoreClock
                                $OCArgs += "GPU_P$($PStates-1)=$CoreClock;$CoreVolt "
                                $ocmessage += "Setting GPU $($OCCount.AMD.$i) P$($PStates-1) Clock To $($CoreClock), Voltage To $CoreVolt"                     
                            }
                        }
                        else {
                            if ($AMDAgg -eq 1) {
                                for ($j = 1; $j -lt $PStates; $j++) {
                                    $DefaultCoreClock = $Default_Core_Clock."Gpu $Select P$($PStates-1) Core Clock"
                                    $CoreVolt = $AMDOCCV[$Select]
                                    $CoreClock = $DefaultCoreClock
                                    $OCArgs += "GPU_P$j=$CoreClock;$CoreVolt "
                                    $ocmessage += "Setting GPU $($OCCount.AMD.$i) P$J Core Clock To $($CoreClock), Voltage to $CoreVolt"
                                }
                            }
                            else {
                                $DefaultCoreClock = $Default_Core_Clock."Gpu $Select P$($PStates-1) Core Clock"
                                $CoreVolt = $AMDOCCV[$Select]
                                $CoreClock = $DefaultCoreClock
                                $OCArgs += "GPU_P$($PStates-1)=$CoreClock;$CoreVolt "
                                $ocmessage += "Setting GPU $($OCCount.AMD.$i) P$($PStates-1) Clock To $($CoreClock), Voltage To $CoreVolt"
                            }
                        }
                    }
                }
                "REF" {
                    if ([String]$AMDREF -ne "") {
                        if ($AMDREF.Count -eq 1) {
                            $REF = Invoke-Expression ".\build\apps\amdtweak\WinAMDTweak.exe --gpu $i --REF $AMDREF"
                            $OCmessage += "Setting GPU $($OCCount.AMD.$i) memory REF to $AMDREF"
                        }
                        else {
                            $Ref = Invoke-Expression ".\build\apps\amdtweak\WinAMDTweak.exe --gpu $i --REF $($AMDREF[$i])" | Tee-Object -Variable Out
                            $OCmessage += "Setting GPU $($OCCount.AMD.$i) memory REF to $($AMDREF[$i])"
                        }
                    }
                }
            }
        }
    }
   
    if ([string]$OcArgs -ne "") {
        $Script += "`$Proc = Start-Process `".\overdriventool\OverdriveNTool.exe`" -ArgumentList `"$OCArgs`" -NoNewWindow -PassThru; `$Proc | Wait-Process" 
        $ScriptFile = "$($(vars).dir)\build\apps\hive_amdoc_start.ps1"
        $Script | OUt-File $ScriptFile
        $start = [launchcode]::New()
        $FilePath = "$PSHome\pwsh.exe"
        $CommandLine = '"' + $FilePath + '"'
        $arguments = "-executionpolicy bypass -command `"$ScriptFile`""
        $CommandLine += " " + $arguments
        $start_oc = $start.New_Miner($filepath, $CommandLine, (split-path $ScriptFile))
        $Proc = Get-Process -id $start_oc.dwProcessId -ErrorAction Ignore
        $Proc | Wait-Process
        $ocmessage
        $ocmessage | Set-Content ".\build\txt\ocamd.txt"
    }
}