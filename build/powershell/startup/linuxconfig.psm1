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

function Global:Get-Data {

    if (Test-Path ".\build\bash\stats") {
        Copy-Item ".\build\bash\stats" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x stats"
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }

    if (Test-Path ".\build\bash\swarm_batch") {
        Copy-Item ".\build\bash\swarm_batch" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x swarm_batch"
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }    

    if (Test-Path ".\build\bash\nview") {
        Copy-Item ".\build\bash\nview" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x nview"
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }

    if (Test-Path ".\build\bash\bans") {
        Copy-Item ".\build\bash\bans" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x bans"
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }

    if (Test-Path ".\build\bash\modules") {
        Copy-Item ".\build\bash\modules" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x modules"
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }

    if (Test-Path ".\build\bash\get") {
        Copy-Item ".\build\bash\get" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x get"
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }

    ## Extract export folder.
    if (-not (test-path ".\build\export")) {
        log "export folder not found. Exracting export.tar.gz" -ForegroundColor Yellow;
        New-Item -ItemType Directory -Name "export" -path ".\build" | Out-Null;
        $Proc = Start-Process "tar" -ArgumentList "-xzvf build/export.tar.gz -C build" -PassThru; 
        $Proc | Wait-Process;
    }


    if (Test-Path ".\build\libcurl\libcurl.so.4.4.0") {
        $Proc = Start-Process ln -ArgumentList "-s $($(vars).dir)/build/export/libcurl.so.4.4.0 $($(vars).dir)/build/export/libcurl.so.4" -PassThru
        $Proc | Wait-Process
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }
    
    if (Test-Path ".\build\libcurl\libcurl.so.4") {
        $Proc = Start-Process ln -ArgumentList "-s $($(vars).dir)/build/export/libcurl.so.4 $($(vars).dir)/build/export/libcurl.so.3" -PassThru
        $Proc | Wait-Process
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }
    
    if (-not (Test-Path ".\build\export\libnvrtc-builtins.so.10.1")) {
        $Proc = Start-Process ln -ArgumentList "-s $($(vars).dir)/build/export/libnvrtc-builtins.so.10.1.105 $($(vars).dir)/build/export/libnvrtc-builtins.so.10.1" -PassThru
        $Proc | Wait-Process
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }

    if (-not (Test-Path ".\build\export\libnvrtc-builtins.so.10.2")) {
        $Proc = Start-Process ln -ArgumentList "-s $($(vars).dir)/build/export/libnvrtc-builtins.so.10.2.89 $($(vars).dir)/build/export/libnvrtc-builtins.so.10.2" -PassThru
        $Proc | Wait-Process
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }

    if (-not (Test-Path ".\build\export\libcudart.so.10.1")) {
        $Proc = Start-Process ln -ArgumentList "-s $($(vars).dir)/build/export/libcudart.so.10.1.105 $($(vars).dir)/build/export/libcudart.so.10.1" -PassThru
        $Proc | Wait-Process
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }

    if (-not (Test-Path ".\build\export\libcudart.so.10.0")) {
        $Proc = Start-Process ln -ArgumentList "-s $($(vars).dir)/build/export/libcudart.so.10.0.130 $($(vars).dir)/build/export/libcudart.so.10.0" -PassThru
        $Proc | Wait-Process
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }
    
    if (-not (Test-Path ".\build\export\libcudart.so.9.2")) {
        $Proc = Start-Process ln -ArgumentList "-s $($(vars).dir)/build/export/libcudart.so.9.2.148 $($(vars).dir)/build/export/libcudart.so.9.2" -PassThru
        $Proc | Wait-Process
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }

    if (-not (Test-Path ".\build\export\libmicrohttpd.so.10")) {
        $proc = Start-Process ln -ArgumentList "-s $($(vars).dir)/build/export/libmicrohttpd.so.10.34.0 $($(vars).dir)/build/export/libmicrohttpd.so.10" -PassThru
        $Proc | Wait-Process
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }

    if (-not (Test-Path ".\build\export\libcudart.so.10.1")) {
        $Proc = Start-Process ln -ArgumentList "-s $($(vars).dir)/build/export/libcudart.so.10.0.130 $($(vars).dir)/build/export/libcudart.so.10.0" -PassThru
        $Proc | Wait-Process
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }

    if (-not (Test-Path ".\build\export\libcudart.so.10.2")) {
        $Proc = Start-Process ln -ArgumentList "-s $($(vars).dir)/build/export/libcudart.so.10.2.89 $($(vars).dir)/build/export/libcudart.so.10.2" -PassThru
        $Proc | Wait-Process
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }
    
    if (-not (Test-Path ".\build\export\libhwloc.so.5")) {
        $Proc = Start-Process ln -ArgumentList "-s $($(vars).dir)/build/export/libhwloc.so.5.5.0 $($(vars).dir)/build/export/libhwloc.so.5" -PassThru
        $Proc | Wait-Process
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }

    if (-not (Test-Path ".\build\export\libstdc++.so.6")) {
        $Proc = Start-Process ln -ArgumentList "-s $($(vars).dir)/build/export/libstdc++.so.6.0.25 $($(vars).dir)/build/export/libstdc++.so.6" -PassThru
        $Proc | Wait-Process
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }

    if (-not (Test-Path ".\build\export\libnvrtc.so.9.2")) {
        $Proc = Start-Process ln -ArgumentList "-s $($(vars).dir)/build/export/libnvrtc.so.9.2.148 $($(vars).dir)/build/export/libnvrtc.so.9.2" -PassThru
        $Proc | Wait-Process
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }

    if (-not (Test-Path ".\build\export\libnvrtc.so.10.0")) {
        $Proc = Start-Process ln -ArgumentList "-s $($(vars).dir)/build/export/libnvrtc.so.10.0.130 $($(vars).dir)/build/export/libnvrtc.so.10.0" -PassThru
        $Proc | Wait-Process
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }

    if (-not (Test-Path ".\build\export\libnvrtc.so.10.1")) {
        $Proc = Start-Process ln -ArgumentList "-s $($(vars).dir)/build/export/libnvrtc.so.10.1.105 $($(vars).dir)/build/export/libnvrtc.so.10.1" -PassThru
        $Proc | Wait-Process
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }

    if (-not (Test-Path ".\build\export\libnvrtc.so.10.2")) {
        $Proc = Start-Process ln -ArgumentList "-s $($(vars).dir)/build/export/libnvrtc.so.10.2.89 $($(vars).dir)/build/export/libnvrtc.so.10.2" -PassThru
        $Proc | Wait-Process
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }

    if (Test-Path ".\build\bash\get-oc") {
        Copy-Item ".\build\bash\get-oc" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x get-oc"
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }
   
    if (Test-Path ".\build\bash\active") {
        Copy-Item ".\build\bash\active" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x active"
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }

    if (Test-Path ".\build\bash\version") {
        Copy-Item ".\build\bash\version" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x version"
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }
    
    if (Test-Path ".\build\bash\get-screen") {
        Copy-Item ".\build\bash\get-screen" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x get-screen"
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }
   
    if (Test-Path ".\build\bash\mine") {
        Copy-Item ".\build\bash\mine" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x mine"
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }
   
    if (Test-Path ".\build\bash\background") {
        Copy-Item ".\build\bash\background" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x background"
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }
   
    if (Test-Path ".\build\bash\pidinfo") {
        Copy-Item ".\build\bash\pidinfo" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x pidinfo"
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }

    if (Test-Path ".\build\bash\dir.sh") {
        Copy-Item ".\build\bash\dir.sh" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x dir.sh"
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }

    if (Test-Path ".\build\bash\bench") {
        Copy-Item ".\build\bash\bench" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x bench"
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }

    if (Test-Path ".\build\bash\clear_profits") {
        Copy-Item ".\build\bash\clear_profits" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x clear_profits"
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }  

    if (Test-Path ".\build\bash\clear_watts") {
        Copy-Item ".\build\bash\clear_watts" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x clear_watts"
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }  

    if (Test-Path ".\build\bash\get-lambo") {
        Copy-Item ".\build\bash\get-lambo" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x get-lambo"
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }

    if (Test-Path ".\build\bash\swarm_help") {
        Copy-Item ".\build\bash\swarm_help" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x swarm_help"
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }

    if (Test-Path ".\build\bash\send-config") {
        Copy-Item ".\build\bash\send-config" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x send-config"
        Set-Location "/"
        Set-Location $($(vars).dir)     
    }
   
    Set-Location $($(vars).dir)
    
}

function Global:Get-GPUCount {

    $nvidiacounted = $false
    $amdcounted = $false
    $GN = $false
    $GA = $false
    $NoType = $true
    $DeviceList = @{ AMD = @{ }; NVIDIA = @{ }; CPU = @{ }; }
    Invoke-Expression "lspci" | Tee-Object -Variable lspci | Out-null
    $lspci | Set-Content ".\debug\gpucount.txt"
    $GetBus = $lspci | Select-String "VGA", "3D"
    $AMDCount = 0
    $NVIDIACount = 0
    $CardCount = 0
    $(vars).BusData = @()

    ## NVIDIA Cards
    if ($GetBus -like "*NVIDIA*" -and $GetBus -notlike "*nForce*") {
        invoke-expression "nvidia-smi --query-gpu=gpu_bus_id,gpu_name,memory.total,power.min_limit,power.default_limit,power.max_limit,vbios_version --format=csv" | Tee-Object -Variable NVSMI | Out-Null
        $NVSMI = $NVSMI | ConvertFrom-Csv
        $NVSMI | % { $_."pci.bus_id" = $_."pci.bus_id" -replace "00000000:", "" }
    }

    ## AMD Cards
    if ($GetBus -like "*Advanced Micro Devices*" -and $GetBus -notlike "*RS880*" -and $GetBus -notlike "*Stoney*") {
        invoke-expression ".\build\apps\rocm\rocm-smi --showproductname --showid --showvbios --showbus --json" | Tee-Object -Variable ROCMSMI | Out-Null
        $ROCMSMI = $ROCMSMI | ConvertFrom-Json
        $GETSMI = @()
        $ROCMSMI.PSObject.Properties.Name | % { $ROCMSMI.$_."PCI Bus" = $ROCMSMI.$_."PCI Bus".replace("0000:", ""); $GETSMI += [PSCustomObject]@{ "VBIOS version" = $ROCMSMI.$_."VBIOS version"; "PCI Bus" = $ROCMSMI.$_."PCI Bus"; "Card vendor" = $ROCMSMI.$_."Card vendor" } }
        $ROCMSMI = $GETSMI
        invoke-expression ".\build\apps\amdmeminfo\amdmeminfo" | Tee-Object  -Variable amdmeminfo | Out-Null
        $amdmeminfo = $amdmeminfo | where { $_ -notlike "*AMDMemInfo by Zuikkis `<zuikkis`@gmail.com`>*" } | where { $_ -notlike "*Updated by Yann St.Arnaud `<ystarnaud@gmail.com`>*" }
        $amdmeminfo = $amdmeminfo | Select -skip 1
        $amdmeminfo = $amdmeminfo.replace("Found Card: ", "Found Card=")
        $amdmeminfo = $amdmeminfo.replace("Chip Type: ", "Chip Type=")
        $amdmeminfo = $amdmeminfo.replace("BIOS Version: ", "BIOS Version=")
        $amdmeminfo = $amdmeminfo.replace("PCI: ", "PCI=")
        $amdmeminfo = $amdmeminfo.replace("OpenCL Platform: ", "OpenCL Platform=")
        $amdmeminfo = $amdmeminfo.replace("OpenCL ID: ", "OpenCL ID=")
        $amdmeminfo = $amdmeminfo.replace("Subvendor: ", "Subvendor=")
        $amdmeminfo = $amdmeminfo.replace("Subdevice: ", "Subdevice=")
        $amdmeminfo = $amdmeminfo.replace("Sysfs Path: ", "Sysfs Path=")
        $amdmeminfo = $amdmeminfo.replace("Memory Type: ", "Memory Type=")
        $amdmeminfo = $amdmeminfo.replace("Memory Model: ", "Memory Model=")
        for ($i = 0; $i -lt $amdmeminfo.count; $i++) { $amdmeminfo[$i] = "$($amdmeminfo[$i]);" }
        $amdmeminfo | % { $_ = $_ + ";" }
        $amdmeminfo = [string]$amdmeminfo
        $amdmeminfo = $amdmeminfo.split("-----------------------------------;")
        $memarray = @()
        for ($i = 0; $i -lt $amdmeminfo.count; $i++) { $item = $amdmeminfo[$i].split(";"); $data = $item | ConvertFrom-StringData; $memarray += [PSCustomObject]@{"busid" = $data."PCI"; "mem_type" = $data."Memory Type"; "mem_model" = $data."Memory Model"; } }
        $amdmeminfo = $memarray
    }

    ## Add cards based on bus order
    $GetBus | % {
        if ($_ -like "*Advanced Micro Devices*" -or 
            $_ -like "*NVIDIA*" -and
            $_ -notlike "*RS880*" -and 
            $_ -notlike "*Stoney*" -and
            $_ -notlike "nForce"
        ) {
            $busid = $_.line.split(" VGA")[0]
            $busid = $busid.split(" 3D")[0]
            if ($_ -like "*Advanced Micro Devices*") {
                $name = ($_.line.Split("[AMD/ATI] ")[1]).split(" (")[0]
                $SMI = $ROCMSMI | Where { $_."PCI Bus" -eq $busid }
                $meminfo = $amdmeminfo | Where busid -eq $busid
                $(vars).BusData += [PSCustomObject]@{
                    busid     = $busid
                    name      = $name
                    brand     = "amd"
                    subvendor = $SMI."Card vendor"
                    mem       = $meminfo."mem_model"
                    vbios     = $SMI."VBIOS version"
                    mem_type  = $meminfo."mem_type"
                }
            }
            elseif ($_ -like "*NVIDIA*") {
                $Regex = '\[(.*)\]';
                $match = ([Regex]::Matches($card, $Regex).Value)
                if ([string]$match -ne "") {
                    $name = ($match.replace('[', '')).replace(']', '')
                }
                else {
                    $name = $_.line.split('controller: ')[1]
                    $name = $name.split(' (')[0]
                }
                $subvendor = invoke-expression "lspci -vmms $busid" | Tee-Object -Variable subvendor | % { $_ | Select-String "SVendor" | % { $_ -split "SVendor:\s" | Select -Last 1 } }
                $smi = $NVSMI | Where "pci.bus_id" -eq $busid
                $(vars).BusData += [PSCustomObject]@{
                    busid     = $busid
                    name      = $name
                    brand     = "nvidia"
                    subvendor = $subvendor
                    mem       = $smi."memory.total [MiB]"
                    vbios     = $smi.vbios_version
                    plim_min  = $smi."power.min_limit [W]"
                    plim_def  = $smi."power.default_limit [W]"
                    plim_max  = $smi."power.max_limit [W]"
                }
            }
        }
        else {
            $busid = $_.line.split(" VGA")[0]
            $busid = $busid.split(" 3D")[0]
            $name = $_.line.split('controller: ')[1]
            $name = "$name".split(' (')[0]
            $(vars).BusData += [PSCustomObject]@{
                busid = $busid
                name  = $name
                brand = "cpu"
            }   
        }
    }

    if ([string]$(arg).type -eq "") {
        log "Searching For Mining Types" -ForegroundColor Yellow
        log "Adding CPU"
        $(arg).type = @()
        $(vars).Type = @()
        $global:Config.user_params.type = @()
        $global:Config.params.type = @()
        $(arg).type += "CPU"
        $(vars).Type += "CPU"
        $global:Config.user_params.type += "CPU"
        $global:Config.params.type += "CPU"
        $threads = Invoke-Expression "nproc";
        $(vars).threads = $threads
        $(vars).CPUThreads = $threads
        $(arg).CPUThreads = $Threads
        $global:config.user_params.CPUThreads = $threads
        $global:config.params.CPUThreads = $threads    
        if ($(vars).BusData | Where brand -eq "amd") {
            log "AMD Detected: Adding AMD" -ForegroundColor Magenta
            $(arg).type += "AMD1"
            $(vars).Type += "AMD1"
            $global:Config.user_params.type += "AMD1"
            $global:Config.params.type += "AMD1"
        }
        if ($(vars).BusData | Where brand -eq "NVIDIA") {
            if ("AMD1" -in $(arg).type) {
                log "NVIDIA Detected: Adding NVIDIA" -ForegroundColor Magenta
                $(arg).type += "NVIDIA2"
                $(vars).Type += "NVIDIA2"
                $global:Config.user_params.type += "NVIDIA2"
                $global:Config.params.type += "NVIDIA2"
            }
            else {
                log "NVIDIA Detected: Adding NVIDIA" -ForegroundColor Magenta
                $(arg).type += "NVIDIA1"
                $(vars).Type += "NVIDIA1"
                $global:Config.user_params.type += "NVIDIA1"
                $global:Config.params.type += "NVIDIA1"
            }
        }
    }

    $(vars).BusData = $(vars).BusData | Sort-Object busid

    $(vars).BusData | ForEach-Object {
        if ($_.brand -eq "amd") {
            $DeviceList.AMD.Add("$AMDCount", "$CardCount")
            $AMDCount++
            $CardCount++
        }
        elseif ($_.brand -eq "nvidia") {
            $DeviceList.NVIDIA.Add("$NVIDIACount", "$CardCount")
            $NVIDIACount++
            $CardCount++
        }
    }

    $(arg).Type | Foreach {
        if ($_ -like "*CPU*") {
            log "Getting CPU Count"
            for ($i = 0; $i -lt $(arg).CPUThreads; $i++) { 
                $DeviceList.CPU.Add("$($i)", $i)
            }
        }
    }

    $DeviceList | ConvertTo-Json | Set-Content ".\debug\devicelist.txt"
    $GPUCount = 0
    $GPUCount += $DeviceList.Nvidia.Count
    $GPUCount += $DeviceList.AMD.Count
    $GPUCount
}

function Global:Start-LinuxConfig {

    ## Kill Previous Screens
    Global:start-killscript

    ## Check if this is a hive-os image
    ## If HiveOS "Yes" Connect To Hive (Not Ready Yet)
    $HiveBin = "/hive/bin"
    $Hive_File = "/hive-config/rig.conf"
    $Hive = $false
    $NotHiveOS = $false
    if (Test-Path $HiveBin) { $Hive = $true }

    ## Get Total GPU Count
    $(vars).GPU_Count = Global:Get-GPUCount

    if ($(vars).WebSites) {
        Global:Add-Module "$($(vars).web)\methods.psm1"
        $rigdata = Global:Get-RigData

        $(vars).WebSites | ForEach-Object {
            switch ($_) {
                "HiveOS" {
                    if ($Hive -eq $false) {
                        Global:Get-WebModules "HiveOS"
                        $response = $rigdata | Global:Invoke-WebCommand -Site "HiveOS" -Action "Hello"
                        Global:Start-WebStartup $response "HiveOS"
                    }
                }
                "SWARM" {
                    Global:Get-WebModules "SWARM"
                    $response = $rigdata | Global:Invoke-WebCommand -Site "SWARM" -Action "Hello"
                    Global:Start-WebStartup $response "SWARM"
                }
            }
        }
        Remove-Module -Name "methods"
    }

    if (Test-Path $Hive_File) {

        ## Get Hive Config
        $RigConf = Get-Content $Hive_File
        $RigConf = $RigConf | ConvertFrom-StringData                
        $global:Config.hive_params.Worker = $RigConf.WORKER_NAME -replace "`"", ""
        $global:Config.hive_params.Password = $RigConf.RIG_PASSWD -replace "`"", ""
        $global:Config.hive_params.Mirror = $RigConf.HIVE_HOST_URL -replace "`"", ""
        $global:Config.hive_params.FarmID = $RigConf.FARM_ID -replace "`"", ""
        $global:Config.hive_params.Id = $RigConf.RIG_ID -replace "`"", ""
        $global:Config.hive_params.Wd_enabled = $RigConf.WD_ENABLED -replace "`"", ""
        $global:Config.hive_params.Wd_Miner = $RigConf.WD_MINER -replace "`"", ""
        $global:Config.hive_params.Wd_reboot = $RigConf.WD_REBOOT -replace "`"", ""
        $global:Config.hive_params.Wd_minhashes = $RigConf.WD_MINHASHES -replace "`"", ""
        $global:Config.hive_params.Miner = $RigConf.MINER -replace "`"", ""
        $global:Config.hive_params.Miner2 = $RigConf.MINER2 -replace "`"", ""
        $global:Config.hive_params.Timezone = $RigConf.TIMEZONE -replace "`"", ""


        ## HiveOS Specific Stuff
        if ($NotHiveOS -eq $false) {
            if ($(arg).Type -like "*NVIDIA*" -or $(arg).Type -like "*AMD*") {
                Invoke-Expression ".\build\bash\python.sh" | Tee-Object -Variable liba | Out-Null
                $liba | % { log $_ }
                Start-Sleep -S 1
                Invoke-Expression ".\build\bash\libc.sh" | Tee-Object -Variable libb | Out-Null
                $libb | % { log $_ }
                Start-Sleep -S 1
                Invoke-Expression ".\build\bash\libv.sh" | Tee-Object -Variable libc | Out-Null
                $libc | % { log $_ }
                Start-Sleep -S 1
            }

            log "Clearing Trash Folder"
            Invoke-Expression "rm -rf .local/share/Trash/files/*" | Tee-Object -Variable trash | Out-Null
            $Trash | % { log $_ }
        }
    }
    
    ## Let User Know What Platform commands will work for- Will always be Group 1.
    if ($(arg).Type -like "*NVIDIA1*") {
        "NVIDIA1" | Out-File ".\debug\minertype.txt" -Force
        log "Group 1 is NVIDIA- Commands and Stats will work for NVIDIA1" -foreground yellow
        Start-Sleep -S 3
    }
    elseif ($(arg).Type -like "*AMD1*") {
        "AMD1" | Out-File ".\debug\minertype.txt" -Force
        log "Group 1 is AMD- Commands and Stats will work for AMD1" -foreground yellow
        Start-Sleep -S 3
    }
    elseif ($(arg).Type -like "*CPU*") {
        if ($(vars).GPU_Count -eq 0) {
            "CPU" | Out-File ".\debug\minertype.txt" -Force
            log "Group 1 is CPU- Commands and Stats will work for CPU" -foreground yellow
            Start-Sleep -S 3
        }
    }
    elseif ($(arg).Type -like "*ASIC*") {
        if ($(vars).GPU_Count -eq 0) {
            "ASIC" | Out-File ".\debug\minertype.txt" -Force
            log "Group 1 is ASIC- Commands and Stats will work for ASIC" -foreground yellow
        }
    }
    
    ##Data and Hive Configs
    log "Getting Data" -ForegroundColor Yellow
    Global:Get-Data
    
    ## Aaaaannnd...Que that sexy loading screen
    Global:Get-SexyUnixLogo
    $Proc = Start-Process ".\build\bash\screentitle.sh" -PassThru
    $Proc | Wait-Process

    ## Set Arguments/New Parameters
    if ($global:Config.hive_params.Id) {
        $global:Config.hive_params | ConvertTo-Json | Set-Content ".\config\parameters\Hive_params_keys.json"
    }
}
