
function Global:Get-Data {

    if (Test-Path ".\build\bash\stats") {
        Copy-Item ".\build\bash\stats" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x stats"
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

    if (-not (Test-Path ".\build\export\libcurl.so.3")) {
        $Proc = Start-Process ln -ArgumentList "-s $($(vars).dir)/build/export/libcurl.so.3.0.0 $($(vars).dir)/build/export/libcurl.so.3" -PassThru
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

    if (-not (Test-Path ".\build\export\libnvrtc-builtins.so")) {
        $Proc = Start-Process ln -ArgumentList "-s $($(vars).dir)/build/export/libnvrtc-builtins.so.10.1 $($(vars).dir)/build/export/libnvrtc-builtins.so" -PassThru
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

    if (Test-Path ".\build\bash\benchmark") {
        Copy-Item ".\build\bash\benchmark" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x benchmark"
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
    $lspci | Set-Content ".\build\txt\gpucount.txt"
    $GetBus = $lspci | Select-String "VGA", "3D"
    $AMDCount = 0
    $NVIDIACount = 0
    $CardCount = 0
    $(vars).BusData = @()

    ## GPU Bus Hash Table
    $DoBus = $true
    if ($(arg).Type -like "*CPU*" -or $(arg).Type -like "*ASIC*") {
        if("AMD1" -notin $(arg).type -and "NVIDIA1" -notin $(arg).type -and "NVIDIA2" -notin $(arg).type -and "NVIDIA3" -notin $(arg).type) {
        $Dobus = $false
    }
}

    
    if ($DoBus -eq $true) {
        if ($GetBus -like "*NVIDIA*" -and $GetBus -notlike "*nForce*") {
            invoke-expression "nvidia-smi --query-gpu=gpu_bus_id,gpu_name,memory.total,power.min_limit,power.default_limit,power.max_limit,vbios_version --format=csv" | Tee-Object -Variable NVSMI | Out-Null
            $NVSMI = $NVSMI | ConvertFrom-Csv
            $NVSMI | % { $_."pci.bus_id" = $_."pci.bus_id" -replace "00000000:", "" }
            $GN = $true
        }
        if ($GetBus -like "*Advanced Micro Devices*" -and $GetBus -notlike "*RS880*" -and $GetBus -notlike "*Stoney*") {
            $ROCM = invoke-expression "dmesg" | Select-String "amdgpu"
            $AMDMem = invoke-expression "./build/apps/amdmeminfo/amdmeminfo"
            $PCIArray = @()
            $PCICount = 0
            $PCI = $AMDMem | Select-String "Found Card: ", "PCI: ", "BIOS Version", "Memory Model"
            $PCI | % { 
                if ($_ -like "*Memory Model*") {
                    $PCIArray += @{ 
                        $($PCI[$PCICount - 1] -split "PCI: " | Select -Last 1) = @{ 
                            name   = $(
                                $PCI[$PCICount - 3] -split "Found Card: " | Select -Last 1 | % {
                                    $Get = [String]$_; $Get1 = $Get.Substring($Get.IndexOf("(")) -replace "\(", ""; 
                                    $Get2 = $Get1 -replace "\)", ""; $Get2
                                }
                            ); 
                            bios   = $($PCI[$PCICount - 2] -split "Bios Version: " | Select -Last 1); 
                            memory = $($PCI[$PCICount] -split "Memory Model: " | Select -Last 1);
                        }
                    }
                }; 
                $PCIcount++ 
            }
            $GA = $true
        }

        $TypeArray = @("NVIDIA1", "NVIDIA2", "NVIDIA3", "AMD1")
        $TypeArray | ForEach-Object { if ($_ -in $(arg).Type) { $NoType = $false } }
        if ($NoType -eq $true) {
            log "Searching GPU Types" -ForegroundColor Yellow
            $(arg).Type = @()
            if ($GN -and $GA) {
                log "AMD and NVIDIA Detected" -ForegroundColor Magenta
                $(arg).Type += "AMD1,NVIDIA2" 
            }
            elseif ($GN) { 
                log "NVIDIA Detected: Adding NVIDIA" -ForegroundColor Magenta
                $(arg).Type += "NVIDIA1" 
            }
            elseif ($GA) {
                log "AMD Detected: Adding AMD" -ForegroundColor Magenta
                $(arg).Type += "AMD1" 
            }
            elseif ("ASIC" -notin $(arg).Type) {
                log "No GPU's Detected- Using CPU"
                $(arg).Type += "CPU"
                ## Get Threads:
                $(arg).CPUThreads = grep -c ^processor /proc/cpuinfo;
            }
        }

        $GetBus | Foreach {
            if ($_ -like "*Advanced Micro Devices*" -or $_ -like "*NVIDIA*") {
                ##AMD
                if ($_ -like "*Advanced Micro Devices*" -and $_ -notlike "*RS880*" -and $_ -notlike "*Stoney*") {
                    if ($(arg).Type -like "*AMD*") {
                        $Sel = $_
                        $busid = $Sel -split " " | Select -First 1            
                        $DeviceList.AMD.Add("$AMDCount", "$CardCount")
                        $AMDCount++
                        $CardCount++
                        $subvendor = invoke-expression "lspci -vmms $busid" | Tee-Object -Variable subvendor | % { $_ | Select-String "SVendor" | % { $_ -split "SVendor:\s" | Select -Last 1 } }
                        $mem = "$($ROCM | Select-String "amdgpu 0000`:$busid`: VRAM`: " | %{ $_ -split "amdgpu 0000`:$busid`: VRAM`: " | Select -Last 1} | % {$_ -split "M" | Select -First 1})M"
                        $(vars).BusData += [PSCustomObject]@{
                            busid     = $busid
                            name      = $PCIArray.$busid.name
                            brand     = "amd"
                            subvendor = $subvendor
                            mem       = $mem
                            vbios     = $PCIArray.$busid.bios
                            mem_type  = $PCIArray.$busid.memory
                        }
                    }
                }
                if ($_ -like "*NVIDIA*" -and $_ -notlike "*nForce*") {
                    $Sel = $_
                    $busid = $Sel -split " " | Select -First 1
                    $subvendor = invoke-expression "lspci -vmms $busid" | Tee-Object -Variable subvendor | % { $_ | Select-String "SVendor" | % { $_ -split "SVendor:\s" | Select -Last 1 } }
                    $NVSMI | Where "pci.bus_id" -eq $busid | % {

                        $(vars).BusData += [PSCustomObject]@{
                            busid     = $busid
                            name      = $_.name
                            brand     = "nvidia"
                            subvendor = $subvendor
                            mem       = $_."memory.total [MiB]"
                            vbios     = $_.vbios_version
                            plim_min  = $_."power.min_limit [W]"
                            plim_def  = $_."power.default_limit [W]"
                            plim_max  = $_."power.max_limit [W]"
                        }
                    }
                    $DeviceList.NVIDIA.Add("$NVIDIACount", "$CardCount")
                    $NVIDIACount++
                    $CardCount++
                }
            }
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

    $DeviceList | ConvertTo-Json | Set-Content ".\build\txt\devicelist.txt"
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
                Invoke-Expression ".\build\bash\libc.sh" | Tee-Object -Variable libc | Out-Null
                Invoke-Expression ".\build\bash\libv.sh" | Tee-Object -Variable libv | Out-Null
                $libc | % { log $_ }
                Start-Sleep -S 1
                $libv | % { log $_ }
                Start-Sleep -S 1
            }

            log "Clearing Trash Folder"
            Invoke-Expression "rm -rf .local/share/Trash/files/*" | Tee-Object -Variable trash | Out-Null
            $Trash | % { log $_ }
        }
    }

    ## Set Cuda for commands
    if ($(arg).Type -like "*NVIDIA*") { $(arg).Cuda | Set-Content ".\build\txt\cuda.txt" }
    
    ## Let User Know What Platform commands will work for- Will always be Group 1.
    if ($(arg).Type -like "*NVIDIA1*") {
        "NVIDIA1" | Out-File ".\build\txt\minertype.txt" -Force
        log "Group 1 is NVIDIA- Commands and Stats will work for NVIDIA1" -foreground yellow
        Start-Sleep -S 3
    }
    elseif ($(arg).Type -like "*AMD1*") {
        "AMD1" | Out-File ".\build\txt\minertype.txt" -Force
        log "Group 1 is AMD- Commands and Stats will work for AMD1" -foreground yellow
        Start-Sleep -S 3
    }
    elseif ($(arg).Type -like "*CPU*") {
        if ($(vars).GPU_Count -eq 0) {
            "CPU" | Out-File ".\build\txt\minertype.txt" -Force
            log "Group 1 is CPU- Commands and Stats will work for CPU" -foreground yellow
            Start-Sleep -S 3
        }
    }
    elseif ($(arg).Type -like "*ASIC*") {
        if ($(vars).GPU_Count -eq 0) {
            "ASIC" | Out-File ".\build\txt\minertype.txt" -Force
            log "Group 1 is ASIC- Commands and Stats will work for ASIC" -foreground yellow
        }
    }
    
    ## Aaaaannnd...Que that sexy loading screen
    Global:Get-SexyUnixLogo
    $Proc = Start-Process ".\build\bash\screentitle.sh" -PassThru
    $Proc | Wait-Process

    ##Data and Hive Configs
    log "Getting Data" -ForegroundColor Yellow
    Global:Get-Data

    ## Set Arguments/New Parameters
    if ($global:Config.hive_params.Id) {
        $global:Config.hive_params | ConvertTo-Json | Set-Content ".\build\txt\hive_params_keys.txt"
    }
}
