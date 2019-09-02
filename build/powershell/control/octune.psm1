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

function Global:Start-OC($Miner) {
    Switch ($(arg).Platform) {
        "linux" { $(vars).GCount = Get-Content ".\build\txt\devicelist.txt" | ConvertFrom-Json }
        "windows" { $(vars).GCount = Get-Content ".\build\txt\oclist.txt" | ConvertFrom-Json }
    }
    
    $nvidiaOC = $false; $DoNVIDIAOC = $false; $DoAMDOC = $false
    $AMDOC = $false; $ETHPill = $false; $SettingsArgs = $false
    
    if ($Miner.Type -like "*NVIDIA*") { $nvidiaOC = $true }
    if ($Miner.Type -like "*AMD*") { $AMDOC = $true }
    
    if ($nvidiaOC -or $AMDOC) { log "Setting $($Miner.Type) Overclocking" -ForegroundColor Cyan }

    $OC_Algo = $(vars).oc_algos.$($Miner.Algo).$($Miner.Type)
    $Default = $(vars).oc_default."default_$($Miner.Type)"
    
    ##Check For Pill
    if ($OC_Algo.ETHPill) { $ETHPill = $true }
    
    ## Stop previous Pill
    ## Will Restart It If it Required
    if ($(arg).Platform -eq "linux") { $Proc = Start-Process "./build/bash/killall.sh" -ArgumentList "pill-$($Miner.Type)" -PassThru; $Proc | Wait-Process }
    if ($(arg).Platform -eq "windows") {
        if (Test-Path (".\build\pid\pill_pid.txt")) {
            $PillPID = Get-Content ".\build\pid\pill_pid.txt"
            if ($PillPID) {
                $PillProcess = Get-Process -ID $PillPID
                if ($PillProcess.HasExited -eq $false) {
                    Stop-Process -Id $PillPID
                }
            }
        }
    }
    
    ##Start New Pill
    if ($ETHPill -eq $true) {

        log "Activating ETHPill" -ForegroundColor Cyan

        ##Devices
        if ($Miner.Devices -eq "none") { $OCPillDevices = Global:Get-DeviceString -TypeCount $(vars).GCount.NVIDIA.PSObject.Properties.Value.Count }
        else { $OCPillDevices = Global:Get-DeviceString -TypeDevices $Miner.Devices }

        ##Build Arguments
        $OCPillDevices | foreach { $PillDevices += "$($_)," }
        $PillDevices = $PillDevices.Substring(0, $PillDevices.Length - 1)
        $PillDevices = "--RevA $PillDevices"

        ##Start Pill Linux
        if ($(arg).Platform -eq "linux") {
            if ($OC_Algo.PillDelay) { $PillDelay = $OC_Algo.PillDelay }
            else { $PillDelay = 1 }
            $PillScript = @()
            $PillScript += "`#`!/usr/bin/env bash"
            if ($(arg).HiveOS -eq "Yes") { $PillScript += "export DISPLAY=`":0`"" }
            $PillScript += "./build/apps/ohgodatool/OhGodAnETHlargementPill-r2 $PillDevices"
            $Proc = Start-Process "screen" -ArgumentList "-S pill-$($Miner.Type) -d -m" -PassThru
            $Proc | Wait-Process
            Start-Sleep -S $PillDelay
            $PillScript | Out-File ".\build\bash\pill.sh"
            Start-Sleep -S .25
            if (Test-Path ".\build\bash\pill.sh") { $Proc = Start-Process "chmod" -ArgumentList "+x build/bash/pill.sh" -PassThru; $Proc | Wait-Process }
            if (Test-Path ".\build\bash\pill.sh") { $Proc = Start-Process "screen" -ArgumentList "-S pill-$($Miner.Type) -X stuff ./build/bash/pill.sh`n" -PassThru; $Proc | Wait-Process }
        }

        ##Start Pill Windows
        if ($(arg).Platform -eq "windows") {
            if ($OC_Algo.PillDelay) { $PillSleep = $OC_Algo.PillDelay }
            else { $PillSleep = 1 }
            $PillTimer = New-Object -TypeName System.Diagnostics.Stopwatch
            $PL = Join-Path "$($(vars).dir)" ".\build\apps"
            $command = Start-Process "pwsh" -ArgumentList "-executionpolicy bypass -windowstyle minimized -noexit -command `"&{`$host.ui.RawUI.WindowTitle = `'ETH-Pill`'; Set-Location $PL; Start-Sleep $PillSleep; Invoke-Expression `'.\ohgodatool\OhGodAnETHlargementPill-r2.exe $PillDevices`'}`"" -WindowStyle Minimized -PassThru -Verb Runas
            $command.ID | Set-Content ".\build\pid\pill_pid.txt"
            $PillTimer.Restart()
            do {
                Start-Sleep -S 1
                $ProcessId = if (Test-Path ".\build\pid\pill_pid.txt") { Get-Content ".\build\pid\pill_pid.txt" }
                if ($ProcessID -ne $null) { $Process = Get-Process $ProcessId -ErrorAction SilentlyContinue }
            }until($ProcessId -ne $null -or ($PillTimer.Elapsed.TotalSeconds) -ge 10)  
            $PillTimer.Stop()
        }

    }
    
    $Card = $(vars).oc_default.Cards -split ' '
    $Card = $Card -split ","
    
    #OC For Devices
    $NVIDIAOCArgs = @(); $NVIDIAPowerArgs = @(); $NScript = @(); $AScript = @(); $NFanArgs = @();
    if ($OC_Algo.Memory -or $OC_Algo.Core -or $OC_Algo.Fans) { $SettingsArgs = $true }
    elseif ($Default.Memory -or $Default.Core -or $Default.Fans) { $SettingsArgs = $true }
    
    if ($Miner.Type -like "*NVIDIA*") {
        if ($Miner.Devices -eq "none") { $OCDevices = Global:Get-DeviceString -TypeCount $(vars).GCount.NVIDIA.PSObject.Properties.Value.Count }
        else { $OCDevices = Global:Get-DeviceString -TypeDevices $Miner.Devices }

        if ($OC_Algo.core) {
            $Core = $OC_Algo.core -split ' '    
            $Core = $Core -split ","
        }
        else {
            $Core = $Default.core -split ' '
            $Core = $Core -split ","
        }

        if ($OC_Algo.memory) {
            $Mem = $OC_Algo.memory -split ' '    
            $Mem = $Mem -split ","
        }
        else {
            $Mem = $Default.memory -split ' '
            $Mem = $Mem -split ","
        }

        if ($OC_Algo.power) {
            $Power = $OC_Algo.power -split ' '    
            $Power = $Power -split ","
        }
        else {
            $Power = $Default.power -split ' '
            $Power = $Power -split ","
        }

        if ($OC_Algo.fans) {
            $Fan = $OC_Algo.fans -split ' '    
            $Fan = $Fan -split ","
        }
        else {
            $Fan = $Default.fans -split ' '
            $Fan = $Fan -split ","
        }

        $NScreenMiners = "$($Miner.MinerName) "

        
        if ($Card) {

            if ($SettingsArgs -eq $true) {
                for ($i = 0; $i -lt $OCDevices.Count; $i++) {
                    $GPU = $OCDevices[$i]
                    $NSettings += " -a [gpu:$GPU]/GPUPowerMizerMode=1"
                }
            }    
        
            if ($Core) {
                $DONVIDIAOC = $true
                for ($i = 0; $i -lt $OCDevices.Count; $i++) {
                    if ($Core.Count -gt 1) {
                        $Cores = $Core[$i]
                    }
                    else { $Cores = $Core | Select -First 1 }
                    $GPU = $OCDevices[$i]
                    $X = 3
                    Switch ($Card[$GPU]) {
                        "1050" { $X = 2 }
                        "1050ti" { $X = 2 }
                        "P106-100" { $X = 2 }
                        "P106-090" { $X = 1 }
                        "P104-100" { $X = 1 }
                        "P102-100" { $X = 1 }
                    }
                    if ($(arg).Platform -eq "linux") { $NSettings += " -a [gpu:$GPU]/GPUGraphicsClockOffset[$X]=$($Cores)" }
                    if ($(arg).Platform -eq "windows") { $NVIDIAOCArgs += "-setBaseClockOffset:$GPU,0,$($Cores) " }
                }
                $NScreenCore += "$($Miner.Type) Core is $Core "
            }

            if ($Fan) {
                $DONVIDIAOC = $true
                for ($i = 0; $i -lt $OCDevices.Count; $i++) {
                    if ($Fan.Count -gt 1) {
                        $Fans = $Fan[$i]
                    }
                    else { $Fans = $Fan | Select -First 1 }
                    $GPU = $OCDevices[$i]
                    if ($(arg).Platform -eq "linux") { $NSettings += " -a [gpu:$GPU]/GPUFanControlState=1 -a [fan:$($(vars).GCount.NVIDIA.$GPU)]/GPUTargetFanSpeed=$($Fans)" }
                    if ($(arg).Platform -eq "windows") { $NFanArgs += "--index $GPU --speed $($Fans)" }
                }
                $NScreenFan += "$($Miner.Type) Fan is $Fan "
            }

            if ($Mem) {
                $DONVIDIAOC = $true
                for ($i = 0; $i -lt $OCDevices.Count; $i++) {
                    if ($Mem.Count -gt 1) {
                        $Mems = $Mem[$i]
                    }
                    else { $Mems = $Mem | Select -First 1 }
                    $GPU = $OCDevices[$i]
                    $X = 3
                    Switch ($Card[$GPU]) {
                        "1050" { $X = 2 }
                        "1050ti" { $X = 2 }
                        "P106-100" { $X = 2 }
                        "P106-090" { $X = 1 }
                        "P104-100" { $X = 1 }
                        "P102-100" { $X = 1 }
                        "1660" { $X = 4 }
                        "1660ti" { $X = 4 }
                    }
                    if ($(arg).Platform -eq "linux") { $NSettings += " -a [gpu:$GPU]/GPUMemoryTransferRateOffset[$X]=$($Mems)" }
                    if ($(arg).Platform -eq "windows") { $NVIDIAOCArgs += "-setMemoryClockOffset:$GPU,0,$($Mems) " } 
                }
                $NScreenMem += "$($Miner.Type) Memory is $Mem "
            }
    
            $NPL = @()
            if ($Power) {
                if ($IsWindows) {
                    $Max_Power = invoke-expression "nvidia-smi --query-gpu=power.max_limit --format=csv" | ConvertFrom-CSV
                    $Max_Power = $Max_Power.'power.max_limit [W]' | % { $_ = $_ -replace " W", ""; $_ }            
                }
                $DONVIDIAOC = $true
                for ($i = 0; $i -lt $OCDevices.Count; $i++) {
                    if ($Power.Count -gt 1) {
                        [Double]$Max = $Max_Power[$i]
                        [Double]$Value = $Power[$i] | % { iex $_ } ## String to double/int issue.
                        [Double]$Limit = [math]::Round(($Value / $Max) * 100, 0)
                        $Powers = $Power[$i]
                    }
                    else {
                        [Double]$Max = $Max_Power[$i]
                        [Double]$Value = $Power | Select -First 1 | % { iex $_ } ## String to double/int issue.
                        [Double]$Limit = [math]::Round(($Value / $Max) * 100, 0)
                        $Powers = $Power | Select -First 1 
                    }
                    $GPU = $OCDevices[$i]
                    if ($(arg).Platform -eq "linux") { $NPL += "nvidia-smi -i $GPU -pl $($Powers)"; }
                    elseif ($(arg).Platform -eq "windows") { $NVIDIAOCArgs += "-setPowerTarget:$GPU,$($Limit) " }
                }

                if ($(arg).Platform -eq "linux") {
                    for ($i = 0; $i -lt $OCDevices.Count; $i++) {
                        $GPU = $OCDevices[$i]
                        $NPL += "nvidia-smi -i $GPU -pm ENABLED"; 
                    }
                }
    
                $NScreenPower += "$($Miner.Type) Power is $Power "
            }
        }
    }
    
    if ($Miner.Type -like "*AMD*") {
        if ($Miner.Devices -eq "none") { $OCDevices = Global:Get-DeviceString -TypeCount $(vars).GCount.AMD.PSObject.Properties.Value.Count }
        else { $OCDevices = Global:Get-DeviceString -TypeDevices $Miner.Devices }


        if ($OC_Algo.core) {
            $Core = $OC_Algo.core -split ' '    
            $CoreClock = $Core -split ","
        }
        else {
            $Core = $Default.core -split ' '
            $CoreClock = $Core -split ","
        }

        if ($OC_Algo.mem) {
            $Mem = $OC_Algo.mem -split ' '    
            $MemClock = $Mem -split ","
        }
        else {
            $Mem = $Default.mem -split ' '
            $MemClock = $Mem -split ","
        }

        if ($OC_Algo.v) {
            $V = $OC_Algo.v -split ' '    
            $Voltage = $V -split ","
        }
        else {
            $V = $Default.v -split ' '
            $Voltage = $V -split ","
        }

        if ($OC_Algo.dpm) {
            $DPM = $OC_Algo.dpm -split ' '    
            $CoreState = $DPM -split ","
        }
        else {
            $DPM = $Default.dpm -split ' '
            $CoreState = $DPM -split ","
        }

        if ($OC_Algo.mdpm) {
            $MDPM = $OC_Algo.mdpm -split ' '    
            $MemState = $MDPM -split ","
        }
        else {
            $MDPM = $Default.mdpm -split ' '
            $MemState = $MDPM -split ","
        }

        if ($OC_Algo.fans) {
            $Fan = $OC_Algo.fans -split ' '    
            $Fans = $Fan -split ","
        }
        else {
            $Fan = $Default.fans -split ' '
            $Fans = $Fan -split ","
        }

        $AScreenMiners = "$($Miner.MinerName) ";
    
        if ($Card) {

            if ($(arg).Platform -eq "linux") {
                $AScript += "`#`!/usr/bin/env bash" 
            }
        
            if ($(arg).Platform -eq "linux") {

                if ($MemClock -or $MemState) {
                    $DOAmdOC = $true
                    for ($i = 0; $i -lt $OCDevices.Count; $i++) {
                        if ($MemClock.Count -gt 1) {
                            $MemClocks = $MemClock[$i]
                        }
                        else { $MemClocks = $MemClock | Select -First 1 }
                        if ($MemState.Count -gt 1) {
                            $MemStates = $MemState[$i]
                        }
                        else { $MemStates = $MemState | Select -First 1 }
                        $GPU = $OCDevices[$i]
                        $MEMArgs = $null
                        if ($MemClock[$GPU]) { $MEMArgs += " --mem-clock $($MemClocks)" }
                        if ($MemState[$GPU]) { $MEMArgs += " --mem-state $($MemStates)" }
                        $WolfArgs = "wolfamdctrl -i $($(vars).GCount.AMD.$GPU)$MEMArgs"
                        $AScript += "$WolfArgs"
                    }
                    $AScreenMem += "$($Miner.Type) MEM is $MemClock "
                    $AScreenMDPM += "$($Miner.Type) MDPM is $MemState "
                }

                if ($CoreClock) {
                    $DOAmdOC = $true
                    for ($i = 0; $i -lt $OCDevices.Count; $i++) {
                        if ($CoreClock.Count -gt 1) {
                            $CoreClocks = $CoreClock[$i]
                        }
                        else { $CoreClocks = $CoreClock | Select -First 1 }
                        $GPU = $OCDevices[$i]
                        $PStates = 8
                        for ($j = 1; $j -lt $PStates; $j++) {
                            $CoreArgs = $null
                            if ($CoreClock[$GPU]) { $CoreArgs += " --core-clock $($CoreClocks)" }
                            $CoreArgs += " --core-state $j"
                            $WolfArgs = "wolfamdctrl -i $($(vars).GCount.AMD.$GPU)$CoreArgs"
                            $AScript += $WolfArgs
                        }
                    }
                    $AScreenCore += "$($Miner.Type) CORE is $CoreClock) "
                    $AScreenDPM += "$($Miner.Type) DPM is $CoreState) "
                }

                if ($Voltage) {
                    $VoltArgs = @()
                    $DOAmdOC = $true
                    for ($i = 0; $i -lt $OCDevices.Count; $i++) {
                        if ($Voltage.Count -gt 1) {
                            $Voltages = $Voltage[$i]
                        }
                        else { $Voltages = $Voltage | Select -First 1 }
                        $GPU = $OCDevices[$i]
                        for ($ia = 0; $ia -lt 16; $ia++) {
                            if ($Voltages) { $VoltArgs += "wolfamdctrl -i $($(vars).GCount.AMD.$GPU) --vddc-table-set $($Voltages) --volt-state $ia" }
                        }
                    }
                    $AScript += $VoltArgs
                    $AScreenPower += "$($Miner.Type) V is $Voltage "
                }

                if ($Fans) {
                    for ($i = 0; $i -lt $OCDevices.Count; $i++) {
                        if ($Fans.Count -gt 1) {
                            $Fanss = $Fans[$i]
                        }
                        else { $Fanss = $Fans | Select -First 1 }
                        $DOAmdOC = $true
                        $GPU = $OCDevices[$i]
                        $FanArgs = $null
                        if ($Fans[$GPU]) { $Fanargs += " --set-fanspeed $($Fanss)" }
                        $WolfArgs = "wolfamdctrl -i $($(vars).GCount.AMD.$GPU)$FanArgs"
                        $AScript += $WolfArgs
                    }
                    $AScreenFans += "$($_.Type) Fans is $Fans "
                }
            }

            if ($(arg).Platform -eq "windows") {
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
                                    
                $Ascript += "`$host.ui.RawUI.WindowTitle = `'OC-Start`';"
                Invoke-Expression ".\build\apps\odvii\odvii.exe s" | Tee-Object -Variable Model | OUt-Null
                $Model = $Model | ConvertFrom-StringData
                $Model = $Model.keys | % { if ($_ -like "*Model*") { $Model.$_ } }
    
                for ($i = 0; $i -lt $(vars).GCount.AMD.PSObject.Properties.Name.Count; $i++) {
                    $OCArgs += "-ac$($(vars).GCount.AMD.$i) "
                    $Select = $(vars).GCount.AMD.PSOBject.Properties.Name
                    $Select = $Select | Sort-Object
                    $Select = $Select[$i]

                    if ($MemClock -or $MDPM) {
                        $DOAmdOC = $true
                        $MPStates = 3
                        if ($Model[$Select] -like "*Vega*") { $MPStates = 4 }
                        if ($MemClock.Count -eq 1) { $Memory_Clock = $MemClock }else { $Memory_Clock = $MemClock[$Select] }
                        if ($MDPM.Count -eq 1) { $Mem_State = $MDPM }else { $Mem_State = $MDPM[$Select] }
                        $DefaultMemClock = $Default_Mem_Clock."Gpu $Select P$($PStates-1) Mem Clock"
                        $DefaultMemVolt = $Default_Mem_Voltage."Gpu $Select P$($PStates-1) Mem Voltage"
                        if ($Memory_Clock) { $Mem = $Memory_Clock }else { $Mem = $DefaultMemClock }
                        if ($Mem -like '*;*') {
                            $OCArgs += "Mem_P$($MPStates-1)=$($Mem) "
                        }
                        else {
                            if ($Mem_State) { $MV = $Default_Mem_Voltage."Gpu $Select P$($Mem_State) Mem Voltage" }else { $MV = $DefaultMemVolt }
                            $OCArgs += "Mem_P$($MPStates-1)=$($Mem);$MV "
                        }
                        $AScreenMem = "$($Miner.Type) MEM is $($MemClock) "
                        $AScreenMDPM = "$($Miner.Type) MDPM is $($MemState) "
                    }

                    if ($CoreClock -or $Voltage) {
                        $DOAmdOC = $true
                        $PStates = 8
                        for ($j = 1; $j -lt $PStates; $j++) {
                            if ($CoreClock.Count -eq 1) { $Core_Clock = $CoreClock }else { $Core_Clock = $CoreClock[$Select] }
                            if ($Voltage.Count -eq 1) { $Core_Volt = $Voltage }else { $Core_Volt = $Voltage[$Select] }
                            $DefaultCoreClock = $Default_Core_Clock."Gpu $Select P$j Core Clock"
                            $DefaultCoreVolt = $Default_Core_Voltage."Gpu $Select P$j Core Voltage"
                            if ($Core_Clock) { $CClock = $Core_Clock }else { $CClock = $DefaultCoreClock }
                            if ($Core_Volt) { $CVolt = $Core_Volt }else { $CVolt = $DefaultCoreVolt }
                            $OCArgs += "GPU_P$j=$CClock;$CVolt "
                        }
                        $AScreenCore = "$($Miner.Type) CORE is $($CoreClock) "
                        $AScreenDPM = "$($Miner.Type) Core Voltage is $($Voltage) "
                    }

                    if ($Fans) {
                        $DOAmdOC = $true
                        $FansMap = (55, 60, 65, 68, 70)
                        if ($Fans.Count -eq 1) {
                            if ($Fans[0] -like '*;*') {
                                $_Fans = $Fans[0] -split ';'
                                for ($j = 0; $j -lt 5; $j++) {
                                    if ($j -lt $_Fans.Count) { $OCArgs += "Fan_P$($j)=$($FansMap[$j]);$($_Fans[$j]) " } 
                                    else { $OCArgs += "Fan_P$($j)=$($FansMap[$j]);$($_Fans[$_Fans.Count-1]) " }
                                }
                            }
                            else {
                                $OCArgs += "Fan_ZeroRPM=0 Fan_P0=$($FansMap[0]);$($Fans) Fan_P1=$($FansMap[1]);$($Fans) Fan_P2=$($FansMap[2]);$($Fans) Fan_P3=$($FansMap[3]);$($Fans) Fan_P4=$($FansMap[4]);$($Fans) "
                            }
                        }
                        else {
                            if ($Fans[$Select] -like '*;*') {
                                $_Fans = $Fans[$Select] -split ';'
                                for ($j = 0; $j -lt 5; $j++) {
                                    if ($j -lt $_Fans.Count) { $OCArgs += "Fan_P$($j)=$($FansMap[$j]);$($_Fans[$j]) " } 
                                    else { $OCArgs += "Fan_P$($j)=$($FansMap[$j]);$($_Fans[$_Fans.Count-1]) " }
                                }
                            }
                            else {
                                $OCArgs += "Fan_ZeroRPM=0 Fan_P0=$($FansMap[0]);$($Fans[$Select]) Fan_P1=$($FansMap[1]);$($Fans[$Select]) Fan_P2=$($FansMap[2]);$($Fans[$Select]) Fan_P3=$($FansMap[3]);$($Fans[$Select]) Fan_P4=$($FansMap[4]);$($Fans[$Select]) "
                            }
                        }
                        $AScreenFans = "$($Miner.Type) Fans is $($Fans) "
                    }
                }
                $AScript += "`$Proc = Start-Process `".\overdriventool\OverdriveNTool.exe`" -ArgumentList `"$OCArgs`" -WindowStyle hidden -PassThru; `$Proc | Wait-Process"
            }
        }
    }
    
    if ($DoNVIDIAOC -eq $true -and $(arg).Platform -eq "windows") {
        $script = @()
        $script += "`$host.ui.RawUI.WindowTitle = `'OC-Start`';"
        $script += "Invoke-Expression `'.\inspector\nvidiaInspector.exe $NVIDIAOCArgs`'"
        if ($NFanArgs) { $NFansArgs | ForEach-Object { $script += "Invoke-Expression `'.\nvfans\nvfans.exe $($_)`'" } }
        Set-Location ".\build\apps"
        $script | Out-File "NVIDIA-oc-start.ps1"
        $Proc = start-process "pwsh" -ArgumentList "-executionpolicy bypass -windowstyle hidden -command "".\NVIDIA-oc-start.ps1""" -PassThru -WindowStyle Minimized
        $Proc | Wait-Process
        Set-Location $($(vars).dir)
    }
    
    if ($DoAMDOC -eq $true -and $(arg).Platform -eq "windows") {
        Set-Location ".\build\apps"
        $Ascript | Out-File "AMD-oc-start.ps1"
        $Proc = start-process "pwsh" -ArgumentList "-executionpolicy bypass -windowstyle hidden -command "".\AMD-oc-start.ps1""" -PassThru -WindowStyle Minimized
        $Proc | Wait-Process
        Set-Location $($(vars).dir)
    }
    
    if ($DOAmdOC -eq $true -and $(arg).Platform -eq "linux") {
        $Proc = Start-Process "./build/bash/killall.sh" -ArgumentList "OC_AMD" -PassThru
        $Proc | Wait-Process
        $Proc = Start-Process "screen" -ArgumentList "-S OC_AMD -d -m" -PassThru
        $Proc | Wait-Process
        Start-Sleep -S .25
        $AScript | Out-File ".\build\bash\amdoc.sh"
        Start-Sleep -S .25
        $Proc = Start-Process "chmod" -ArgumentList "+x build/bash/amdoc.sh" -PassThru
        $Proc | Wait-Process
        if (Test-Path ".\build\bash\amdoc.sh") { Start-Process "screen" -ArgumentList "-S OC_AMD -X stuff ./build/bash/amdoc.sh`n"; Start-Sleep -S 1; }
    }
    
    if ($DoNVIDIAOC -eq $true -and $(arg).Platform -eq "linux") {
        $NScript = @()
        $NScript += "`#`!/usr/bin/env bash"
        if ($(arg).HiveOS -eq "Yes") { $NScript += "export DISPLAY=`":0`"" }
        if ($SettingsArgs -eq $true) { $NScript += "nvidia-settings $NSettings" }
        if ($NPL) { $NScript += $NPL }
        $Proc = Start-Process "./build/bash/killall.sh" -ArgumentList "OC_$($Miner.Type)" -PassThru
        $Proc | Wait-Process
        Start-Process "screen" -ArgumentList "-S OC_$($Miner.Type) -d -m"
        Start-Sleep -S 1
        $NScript | Out-File ".\build\bash\nvidiaoc.sh"
        Start-Sleep -S .25
        $Proc = Start-Process "chmod" -ArgumentList "+x build/bash/nvidiaoc.sh" -PassThru
        $Proc | Wait-Process
        if (Test-Path ".\build\bash\nvidiaoc.sh") { Start-Process "screen" -ArgumentList "-S OC_$($Miner.Type) -X stuff ./build/bash/nvidiaoc.sh`n"; Start-Sleep -S 1; }
    }
    
    $OCMessage = @()
    
    if ($DoNVIDIAOC -eq $true) {
        $OCMessage += "Group $($Miner.Type)"
        $OCMessage += "ETHPill: $ETHPill"
        $OCMessage += "$NScreenPower"
        $OCMessage += "$NScreenCore"
        $OCMessage += "$NScreenMem"
        $OCMessage += "$NScreenFan"
        $OCMessage += ""
    }

    if ($DoAMDOC -eq $true) {
        $OCMessage += "Group $($Miner.Type)"
        $OCMessage += "$AScreenCore"
        $OCMessage += "$AScreenDPM"
        $OCMessage += "$AScreenMem"
        $OCMessage += "$AScreenMDPM"
        $OCMessage += "$AScreenPower"
        $OCMessage += "$AScreenFans"
        $OCMessage += ""
    }

    $OCMessage | % {
        log "$($_)" -ForegroundColor Cyan
    }

    $OCMessage | Add-Content -Path ".\build\txt\oc-settings.txt"
    
}
