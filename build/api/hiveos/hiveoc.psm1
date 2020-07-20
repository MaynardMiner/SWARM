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
    $OCCount = Get-Content ".\debug\oclist.txt" | ConvertFrom-JSon
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
                    $PillProc = Get-Process | Where Name -eq "OhGodAnETHlargementPill-r2"
                    if ($PillProc) { $PillProc | % { Stop-Process -Id $_.ID } }
                    if ($HiveNVOC.OHGODAPILL_START_TIMEOUT -gt 0) { $Sleep = "timeout $($HiveNVOC.OHGODAPILL_START_TIMEOUT) > NUL" }
                    $Script = @()
                    $Script += "$Sleep"
                    $Script += "start /min `"`" `"$($(vars).dir)\build\apps\ohgodatool\OhGodAnETHlargementPill-r2.exe`" $PillArg"
                    $Script | Set-Content ".\build\apps\pill.bat"
                    $Process = Start-Process ".\build\apps\pill.bat" -WindowStyle Minimized
                }
                else {
                    $PillProc = Get-Process | Where Name -eq "OhGodAnETHlargementPill-r2"
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
                            [Double]$Limit = [math]::Round(($Value / $Max) * 120, 0)
                            $OCArgs += "-setPowerTarget:$($OCCount.NVIDIA.$i),$($Limit) "
                            $ocmessage += "Setting GPU $($OCCount.NVIDIA.$i) Power Limit To $($Limit)%"
                        }
                    }
                    else {
                        for ($i = 0; $i -lt $NVOCPL.Count; $i++) {
                            [Double]$Max = $Max_Power[$i]
                            [Double]$Value = $NVOCPL[$i] | % { iex $_ } ## String to double/int issue.
                            [Double]$Limit = [math]::Round(($Value / $Max) * 120, 0)
                            $OCArgs += "-setPowerTarget:$($i),$($Limit) "
                            $ocmessage += "Setting GPU $i Power Limit To $($Limit)%"
                        }
                    }
                }
            }
        }
    }

    for ($i = 0; $i -lt $OCCount.NVIDIA.PSObject.Properties.Value.Count; $i++) {
        $OCArgs += "-forcepstate:$($i),0 "
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
        $Proc = Get-Process | Where id -eq $start_oc.dwProcessId
        $Proc | Wait-Process
        $ocmessage
        $ocmessage | Set-Content ".\debug\ocnvidia.txt"
    }
}


function Global:Start-AMDOC($NewOC) {
  
    $AMDOC = $NewOC | ConvertFrom-StringData
    $OCCount = Get-Content ".\debug\oclist.txt" | ConvertFrom-JSon
    $ocmessage = @()
    $script = @()
    $script += "`$host.ui.RawUI.WindowTitle = `'OC-Start`';"
    
    try {
        $stats = @()
        if ([Environment]::Is64BitOperatingSystem) {
            $odvii = ".\build\apps\odvii\odvii_x64.exe"
        } 
        else {
            $odvii = ".\build\apps\odvii\odvii_x86.exe"
        }
        $info = [System.Diagnostics.ProcessStartInfo]::new()
        $info.FileName = $odvii
        $info.UseShellExecute = $false
        $info.RedirectStandardOutput = $true
        $info.Verb = "runas"
        $Proc = [System.Diagnostics.Process]::New()
        $proc.StartInfo = $Info
        $timer = [System.Diagnostics.Stopwatch]::New()
        $timer.Restart();
        $proc.Start() | Out-Null
        while (-not $Proc.StandardOutput.EndOfStream) {
            $stats += $Proc.StandardOutput.ReadLine();
            if ($timer.Elapsed.Seconds -gt 15) {
                $proc.kill() | Out-Null;
                break;
            }
        }
        $Proc.Dispose();            
    }
    catch { Write-Host "WARNING: Failed to get amd stats" -ForegroundColor DarkRed }
    if ($stats) {
        $stats = $stats | ConvertFrom-Json
    }
    else {
        log "Failed To Get Gpu Data From OverdriveN API! Cannot Do OC For AMD!" -ForegroundColor Red;
        break;
    }
    $AMDCount = $OCCount.AMD.PSObject.Properties.Name.Count
    $AMDOCFAN = ($AMDOC.FAN.replace("`"", "")).split(" ")
    $AMDOCCore = ($AMDOC.CORE_CLOCK.replace("`"", "")).split(" ")
    $AMD_Core_State = ($AMDOC.CORE_STATE.replace("`"", "")).split(" ")
    $AMDOCCV = ($AMDOC.CORE_VDDC.replace("`"", "")).split(" ")
    $AMDOCMem = ($AMDOC.MEM_CLOCK.replace("`"", "")).split(" ")
    $AMD_Mem_State = ($AMDOC.MEM_STATE.replace("`"", "")).split(" ")
    $AMDAgg = $AMDOC.AGGRESSIVE
    $AMDREF = ($AMDOC.REF.replace("`"", "")).split(" ")
  
    for ($i = 0; $i -lt $AMDCount; $i++) {

        $Select = $OCCount.AMD.PSOBject.Properties.Name
        $Select = $Select | Sort-Object
        $Select = $Select[$i]
        $OcArgs += "-ac$($OCCount.AMD.$i) "
        $CoreSpeed = $null
        $CoreState = $null
        $CoreVoltage = $null
        $MemSpeed = $null
        $MemState = $null
        $Ref_setting = $null
        

        if ([string]$AMDOCFAN -ne "") {
            if ($AMDOCFAN.Count -eq 1 -and $AMDOCFAN -ne "") { $FanSpeed = $AMDOCFAN }
            else { $FanSpeed = $AMDOCFAN[$Select] }
        }

        if ([string]$AMDOCCore -ne "") {
            if ($AMDOCCore.Count -eq 1 -and $AMDOCCore -ne "") { $CoreSpeed = $AMDOCCore }
            else { $CoreSpeed = $AMDOCCore[$Select] }
        }

        if ([string]$AMD_Core_State -ne "") {
            if ($AMD_Core_State.Count -eq 1 -and $AMD_Core_State -ne "") { $CoreState = $AMD_Core_State }
            else { $CoreState = $AMD_Core_State[$Select] }
        }

        if ([string]$AMDOCCV -ne "") {
            if ($AMDOCCV.Count -eq 1 -and $AMDOCCV -ne "") { $CoreVoltage = $AMDOCCV }
            else { $CoreVoltage = $AMDOCCV[$Select] }
        }

        if ([string]$AMDOCMem -ne "") {
            if ($AMDOCMem.Count -eq 1 -and $AMDOCMem -ne "") { $MemSpeed = $AMDOCMem }
            else { $MemSpeed = $AMDOCMem[$Select] }
        }

        if ([string]$AMD_Mem_State -ne "") {
            if ($AMD_Mem_State.Count -eq 1 -and $AMD_Mem_State -ne "") { $MemState = $AMD_Mem_State }
            else { $MemState = $AMD_Mem_State[$Select] }
        }

        if ([string]$AMDREF -ne "") {
            if ($AMDREF.Count -eq 1 -and $AMDREF -ne "") { $Ref_setting = $AMDREF }
            else { $Ref_setting = $AMDREF[$Select] }
        }

        ## Core Settings            
        
        $Version = $stats[$select].Version;

        $ClockVoltage = $stats[$select].'Clock Defaults'."Vddc P_State 0"
        $ClockSpeed = $stats[$select].'Clock Defaults'."Clock P_State 0"
        $Core_States = $stats[$select].'Core P_States';
        $Min = $ClockSpeed
        
        if ($version -eq "8") {
            $OCArgs += "GPU_P0=$ClockSpeed;$ClockVoltage "
        }
        else {
            $OCArgs += "GPU_P0=$ClockSpeed;$ClockVoltage;0 "
        }
        $ocmessage += "Setting GPU $($OCCount.AMD.$i) P0 Core Clock To $($ClockSpeed), Voltage to $ClockVoltage"     

        if ($Version -ne "8") {
            for ($j = 1; $j -lt $Core_States; $j++) {
                $ClockVoltage = $stats[$select].'Clock Defaults'."Vddc P_State $j"
                $ClockSpeed = $stats[$select].'Clock Defaults'."Clock P_State $j"
                if ($CoreSpeed) { 
                    if ($AMDAgg -eq 1) {
                        $ClockSpeed = $CoreSpeed 
                    } 
                    elseif ($CoreState -eq $j) {
                        $ClockSpeed = $CoreSpeed
                    }
                    elseif ($j -eq ($Core_States - 1)) {
                        $ClockSpeed = $CoreSpeed
                    }
                }
                if ($CoreVoltage) { 
                    if ($AMDAgg -eq 1) {
                        $ClockVoltage = $CoreVoltage 
                    } 
                    elseif ($CoreState -eq $j) {
                        $ClockVoltage = $CoreVoltage
                    }
                    elseif ($j -eq ($Core_States - 1)) {
                        $ClockVoltage = $CoreVoltage
                    }
                }

                if ($CoreState) {
                    if ($j -eq $CoreState) {
                        $OCArgs += "GPU_P$j=$ClockSpeed;$ClockVoltage "
                        $ocmessage += "Setting GPU DPM To P$J"
                        $ocmessage += "Setting GPU $($OCCount.AMD.$i) P$J Core Clock To $($ClockSpeed), Voltage to $ClockVoltage"
                    }
                    else {
                        $OCArgs += "GPU_P$j=$ClockSpeed;$ClockVoltage;0 "
                        $ocmessage += "Setting GPU $($OCCount.AMD.$i) P$J Core Clock To $($ClockSpeed), Voltage to $ClockVoltage"
                    }
                }
                else {
                    $OCArgs += "GPU_P$j=$ClockSpeed;$ClockVoltage "
                    $ocmessage += "Setting GPU $($OCCount.AMD.$i) P$J Core Clock To $($ClockSpeed), Voltage to $ClockVoltage"
                }
            }
        }
        else {
            $ClockVoltage = $stats[$select].'Clock Defaults'."Vddc P_State 2"
            $ClockSpeed = $stats[$select].'Clock Defaults'."Clock P_State 2"
            if ($CoreSpeed) { 
                $ClockSpeed = $CoreSpeed
            }
            if ($CoreVoltage) {
                $ClockVoltage = $CoreVoltage
            }
            $OCArgs += "GPU_Min=$Min "
            $OCArgs += "GPU_Max=$ClockSpeed "
            $OCArgs += "GPU_P2=$ClockSpeed;$ClockVoltage "
            $ocmessage += "Setting GPU $($OCCount.AMD.$i) P2 Core Clock To $($ClockSpeed), Voltage to $ClockVoltage"
            $ocmessage += "Setting GPU $($OCCount.AMD.$i) Min Core Clock To $($Min)"
            $ocmessage += "Setting GPU $($OCCount.AMD.$i) Max Core Clock To $($ClockSpeed)"
        }

        ## Mem Settings
        if ($MemState -and $version -ne "8") {
            $ClockVoltage = $stats[$select].'Memory Defaults'."Vddc P_State 0"
            $ClockSpeed = $stats[$select].'Memory Defaults'."Clock P_State 0"
            $OCArgs += "Mem_P0=$ClockSpeed;$ClockVoltage;0 "
            $ocmessage += "Setting GPU $($OCCount.AMD.$i) P0 Memory Clock To $($ClockSpeed)"
        }

        $Mem_States = $stats[$select].'Memory P_States'
        $states = 0;
        if ($version -ne "8") {
            $states = 1
        }
        for ($j = $states; $j -lt $Mem_States; $j++) {

            $ClockVoltage = $stats[$select].'Memory Defaults'."Vddc P_State $j"
            $ClockSpeed = $stats[$select].'Memory Defaults'."Clock P_State $j"

            if ($MemSpeed) { 
                if ($MemState -eq $j) {
                    $ClockSpeed = $MemSpeed
                }
                elseif ($j -eq ($Mem_States - 1)) {
                    $ClockSpeed = $MemSpeed
                }
            }

            if ($version -ne "8") {
                if ($MemState) {
                    if ($j -eq $MemState) {
                        $OCArgs += "Mem_P$j=$ClockSpeed;$ClockVoltage "
                        $ocmessage += "Setting GPU MDPM To P$J "
                        $ocmessage += "Setting GPU $($OCCount.AMD.$i) P$J Memory Clock To $($ClockSpeed)"
                    }
                    else {
                        $OCArgs += "Mem_P$j=$ClockSpeed;$ClockVoltage;0 "
                        $ocmessage += "Setting GPU $($OCCount.AMD.$i) P$J Memory Clock To $($ClockSpeed)"
                    }
                }
                else {
                    $OCArgs += "Mem_P$j=$ClockSpeed;$ClockVoltage "
                    $ocmessage += "Setting GPU $($OCCount.AMD.$i) P$J Memory Clock To $($ClockSpeed)"
                }
            }
            else {
                $OCArgs += "Mem_Max=$MemSpeed "
                $ocmessage += "Setting GPU $($OCCount.AMD.$i) Memory Max Speed to $($MemSpeed)"
            }

        }

        ## Fan Settings
        if ($FanSpeed) {
            $OCArgs += "Fan_ZeroRPM=0 Fan_P0=25;$($FanSpeed) Fan_P1=25;$($FanSpeed) Fan_P2=25;$($FanSpeed) Fan_P3=25;$($FanSpeed) Fan_P4=25;$($FanSpeed) "
            $ocmessage += "Setting GPU $($OCCount.AMD.$i) Fan Speed To $($FanSpeed)`%"
        }
        
        ## Ref Settings
        if ($Ref_setting) {
            $REF = Invoke-Expression ".\build\apps\amdtweak\WinAMDTweak.exe --gpu $i --REF $Ref_setting"
            $OCmessage += "Setting GPU $($OCCount.AMD.$i) memory REF to $AMDREF"
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
        $Proc = Get-Process | Where id -eq $start_oc.dwProcessId
        $Proc | Wait-Process
        $ocmessage
        $ocmessage | Set-Content ".\debug\ocamd.txt"
    }
}