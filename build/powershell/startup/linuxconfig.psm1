
function Global:Get-Data {

    if (Test-Path ".\build\bash\stats") {
        Copy-Item ".\build\bash\stats" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x stats"
        Set-Location "/"
        Set-Location $($(v).dir)     
    }

    if (Test-Path ".\build\bash\nview") {
        Copy-Item ".\build\bash\nview" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x nview"
        Set-Location "/"
        Set-Location $($(v).dir)     
    }

    if (Test-Path ".\build\bash\bans") {
        Copy-Item ".\build\bash\bans" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x bans"
        Set-Location "/"
        Set-Location $($(v).dir)     
    }

    if (Test-Path ".\build\bash\modules") {
        Copy-Item ".\build\bash\modules" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x modules"
        Set-Location "/"
        Set-Location $($(v).dir)     
    }

    if (Test-Path ".\build\bash\get") {
        Copy-Item ".\build\bash\get" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x get"
        Set-Location "/"
        Set-Location $($(v).dir)     
    }

    if (-not (Test-Path ".\build\export\libnvrtc-builtins.so.10.1")) {
        Start-Process ln -ArgumentList "-s $($(v).dir)/build/export/libnvrtc-builtins.so.10.1.105 $($(v).dir)/build/export/libnvrtc-builtins.so.10.1" -Wait
        Set-Location "/"
        Set-Location $($(v).dir)     
    }

    if (-not (Test-Path ".\build\export\libnvrtc-builtins.so")) {
        Start-Process ln -ArgumentList "-s $($(v).dir)/build/export/libnvrtc-builtins.so.10.1 $($(v).dir)/build/export/libnvrtc-builtins.so" -Wait
        Set-Location "/"
        Set-Location $($(v).dir)     
    }

    if (-not (Test-Path ".\build\export\libcudart.so.10.1")) {
        Start-Process ln -ArgumentList "-s $($(v).dir)/build/export/libcudart.so.10.1.105 $($(v).dir)/build/export/libcudart.so.10.1" -Wait
        Set-Location "/"
        Set-Location $($(v).dir)     
    }

    if (-not (Test-Path ".\build\export\libcudart.so.10.0")) {
        Start-Process ln -ArgumentList "-s $($(v).dir)/build/export/libcudart.so.10.0.130 $($(v).dir)/build/export/libcudart.so.10.0" -Wait
        Set-Location "/"
        Set-Location $($(v).dir)     
    }
    
    if (-not (Test-Path ".\build\export\libcudart.so.9.2")) {
        Start-Process ln -ArgumentList "-s $($(v).dir)/build/export/libcudart.so.9.2.148 $($(v).dir)/build/export/libcudart.so.9.2" -Wait
        Set-Location "/"
        Set-Location $($(v).dir)     
    }

    if (-not (Test-Path ".\build\export\libmicrohttpd.so.10")) {
        Start-Process ln -ArgumentList "-s $($(v).dir)/build/export/libmicrohttpd.so.10.34.0 $($(v).dir)/build/export/libmicrohttpd.so.10" -Wait
        Set-Location "/"
        Set-Location $($(v).dir)     
    }

    if (-not (Test-Path ".\build\export\libcudart.so.10.1")) {
        Start-Process ln -ArgumentList "-s $($(v).dir)/build/export/libcudart.so.10.0.130 $($(v).dir)/build/export/libcudart.so.10.0" -Wait
        Set-Location "/"
        Set-Location $($(v).dir)     
    }
    
    if (-not (Test-Path ".\build\export\libhwloc.so.5")) {
        Start-Process ln -ArgumentList "-s $($(v).dir)/build/export/libhwloc.so.5.5.0 $($(v).dir)/build/export/libhwloc.so.5" -Wait
        Set-Location "/"
        Set-Location $($(v).dir)     
    }

    if (-not (Test-Path ".\build\export\libstdc++.so.6")) {
        Start-Process ln -ArgumentList "-s $($(v).dir)/build/export/libstdc++.so.6.0.25 $($(v).dir)/build/export/libstdc++.so.6" -Wait
        Set-Location "/"
        Set-Location $($(v).dir)     
    }

    if (-not (Test-Path ".\build\export\libnvrtc.so.9.2")) {
        Start-Process ln -ArgumentList "-s $($(v).dir)/build/export/libnvrtc.so.9.2.148 $($(v).dir)/build/export/libnvrtc.so.9.2" -Wait
        Set-Location "/"
        Set-Location $($(v).dir)     
    }

    if (-not (Test-Path ".\build\export\libnvrtc.so.10.0")) {
        Start-Process ln -ArgumentList "-s $($(v).dir)/build/export/libnvrtc.so.10.0.130 $($(v).dir)/build/export/libnvrtc.so.10.0" -Wait
        Set-Location "/"
        Set-Location $($(v).dir)     
    }

    if (-not (Test-Path ".\build\export\libnvrtc.so.10.1")) {
        Start-Process ln -ArgumentList "-s $($(v).dir)/build/export/libnvrtc.so.10.1.105 $($(v).dir)/build/export/libnvrtc.so.10.1" -Wait
        Set-Location "/"
        Set-Location $($(v).dir)     
    }

    if (Test-Path ".\build\bash\get-oc") {
        Copy-Item ".\build\bash\get-oc" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x get-oc"
        Set-Location "/"
        Set-Location $($(v).dir)     
    }
   
    if (Test-Path ".\build\bash\active") {
        Copy-Item ".\build\bash\active" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x active"
        Set-Location "/"
        Set-Location $($(v).dir)     
    }

    if (Test-Path ".\build\bash\version") {
        Copy-Item ".\build\bash\version" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x version"
        Set-Location "/"
        Set-Location $($(v).dir)     
    }
    
    if (Test-Path ".\build\bash\get-screen") {
        Copy-Item ".\build\bash\get-screen" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x get-screen"
        Set-Location "/"
        Set-Location $($(v).dir)     
    }
   
    if (Test-Path ".\build\bash\mine") {
        Copy-Item ".\build\bash\mine" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x mine"
        Set-Location "/"
        Set-Location $($(v).dir)     
    }
   
    if (Test-Path ".\build\bash\background") {
        Copy-Item ".\build\bash\background" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x background"
        Set-Location "/"
        Set-Location $($(v).dir)     
    }
   
    if (Test-Path ".\build\bash\pidinfo") {
        Copy-Item ".\build\bash\pidinfo" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x pidinfo"
        Set-Location "/"
        Set-Location $($(v).dir)     
    }

    if (Test-Path ".\build\bash\dir.sh") {
        Copy-Item ".\build\bash\dir.sh" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x dir.sh"
        Set-Location "/"
        Set-Location $($(v).dir)     
    }

    if (Test-Path ".\build\bash\benchmark") {
        Copy-Item ".\build\bash\benchmark" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x benchmark"
        Set-Location "/"
        Set-Location $($(v).dir)     
    }

    if (Test-Path ".\build\bash\clear_profits") {
        Copy-Item ".\build\bash\clear_profits" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x clear_profits"
        Set-Location "/"
        Set-Location $($(v).dir)     
    }  

    if (Test-Path ".\build\bash\clear_watts") {
        Copy-Item ".\build\bash\clear_watts" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x clear_watts"
        Set-Location "/"
        Set-Location $($(v).dir)     
    }  

    if (Test-Path ".\build\bash\get-lambo") {
        Copy-Item ".\build\bash\get-lambo" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x get-lambo"
        Set-Location "/"
        Set-Location $($(v).dir)     
    }
   
    Set-Location $($(v).dir)
    
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
    $global:BusData = @()

    if ($GetBus -like "*NVIDIA*") {
        invoke-expression "nvidia-smi --query-gpu=gpu_bus_id,gpu_name,memory.total,power.min_limit,power.default_limit,power.max_limit,vbios_version --format=csv" | Tee-Object -Variable NVSMI | Out-Null
        $NVSMI = $NVSMI | ConvertFrom-Csv
        $NVSMI | % { $_."pci.bus_id" = $_."pci.bus_id" -replace "00000000:", "" }
        $GN = $true
    }
    if ($GetBus -like "*AMD*") { $GA = $true }

    if ($GA -or $GN) {
        Global:Write-Log "Searching GPU Types" -ForegroundColor Yellow
        $TypeArray = @("NVIDIA1", "NVIDIA2", "NVIDIA3", "AMD1")
        $TypeArray | ForEach-Object { if ($_ -in $Global:Config.Params.Type) { $NoType = $false } }
        if ($NoType -eq $true) {
            if ($GA) { 
                Global:Write-Log "AMD Detected: Adding AMD" -ForegroundColor Magenta
                $global:Config.params.Type += "AMD1" 
            }
            if ($GN -and $GA) {
                Global:Write-Log "NVIDIA Also Detected" -ForegroundColor Magenta
                $global:Config.params.Type += "NVIDIA2" 
            }
            elseif ($GN) { 
                Global:Write-Log "NVIDIA Detected: Adding NVIDIA" -ForegroundColor Magenta
                $global:Config.Params.Type += "NVIDIA1" 
            }
        }
    }

    $GetBus | Foreach {
        if ($_ -like "*Advanced Micro Devices*" -or $_ -like "*NVIDIA*") {
            ##AMD
            if ($_ -like "*Advanced Micro Devices*" -and $_ -notlike "*RS880*" -and $_ -notlike "*Stoney*") {
                if ($global:Config.Params.Type -like "*AMD*") {        
                    $DeviceList.AMD.Add("$AMDCount", "$CardCount")
                    $AMDCount++
                    $CardCount++
                }
            }
            if ($_ -like "*NVIDIA*" -and $_ -notlike "*nForce*") {
                $Sel = $_
                $busid = $Sel -split " " | Select -First 1
                $subvendor = invoke-expression "lspci -vmms $busid" | Tee-Object -Variable subvendor | % { $_ | Select-String "SVendor" | % { $_ -split "SVendor:\s" | Select -Last 1 } }
                $NVSMI | Where "pci.bus_id" -eq $busid | % {

                    $global:BusData += [PSCustomObject]@{
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

    $global:Config.Params.Type | Foreach {
        if ($_ -like "*CPU*") {
            Global:Write-Log "Getting CPU Count"
            for ($i = 0; $i -lt $global:Config.Params.CPUThreads; $i++) { 
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
    $Rig_File = "/hive-config/rig.conf"
    $Hive = $false
    $NotHiveOS = $false
    if (Test-Path $HiveBin) { $Hive = $true }
    if ($Hive -eq $false -and $global:Config.Params.Farm_Hash -ne "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx") {
        if (-not (Test-Path $Rig_File) ) {
            $NotHiveOS = $True
            New-Item -ItemType Directory -Name "/hive-config" -Force
        }
        ##Connect To Hive
    }

    if (Test-Path $Rig_File) {

        ## Get Hive Config
        $RigConf = Get-Content $Rig_File
        $RigConf = $RigConf | ConvertFrom-StringData                
        $global:Config.hive_params.HiveWorker = $RigConf.WORKER_NAME -replace "`"", ""
        $global:Config.hive_params.HivePassword = $RigConf.RIG_PASSWD -replace "`"", ""
        $global:Config.hive_params.HiveMirror = $RigConf.HIVE_HOST_URL -replace "`"", ""
        $global:Config.hive_params.FarmID = $RigConf.FARM_ID -replace "`"", ""
        $global:Config.hive_params.HiveID = $RigConf.RIG_ID -replace "`"", ""
        $global:Config.hive_params.Wd_enabled = $RigConf.WD_ENABLED -replace "`"", ""
        $global:Config.hive_params.Wd_Miner = $RigConf.WD_MINER -replace "`"", ""
        $global:Config.hive_params.Wd_reboot = $RigConf.WD_REBOOT -replace "`"", ""
        $global:Config.hive_params.Wd_minhashes = $RigConf.WD_MINHASHES -replace "`"", ""
        $global:Config.hive_params.Miner = $RigConf.MINER -replace "`"", ""
        $global:Config.hive_params.Miner2 = $RigConf.MINER2 -replace "`"", ""
        $global:Config.hive_params.Timezone = $RigConf.TIMEZONE -replace "`"", ""

        ## Get Total GPU Count
        $Global:GPU_Count = Global:Get-GPUCount

        ## HiveOS Specific Stuff
        if ($NotHiveOS -eq $false) {
            if ($global:Config.Params.Type -like "*NVIDIA*" -or $global:Config.Params.Type -like "*AMD*") {
                Invoke-Expression ".\build\bash\libc.sh" | Tee-Object -Variable libc | Out-Null
                Invoke-Expression ".\build\bash\libv.sh" | Tee-Object -Variable libv | Out-Null
                $libc | % { Global:Write-Log $_ }
                Start-Sleep -S 1
                $libv | % { Global:Write-Log $_ }
                Start-Sleep -S 1
            }

            Global:Write-Log "Clearing Trash Folder"
            Invoke-Expression "rm -rf .local/share/Trash/files/*" | Tee-Object -Variable trash | Out-Null
            $Trash | % { Global:Write-Log $_ }
        }

        ## Set Cuda for commands
        if ($global:Config.Params.Type -like "*NVIDIA*") { $global:Config.Params.Cuda | Set-Content ".\build\txt\cuda.txt" }
    
        ## Let User Know What Platform commands will work for- Will always be Group 1.
        if ($global:Config.Params.Type -like "*NVIDIA1*") {
            "NVIDIA1" | Out-File ".\build\txt\minertype.txt" -Force
            Global:Write-Log "Group 1 is NVIDIA- Commands and Stats will work for NVIDIA1" -foreground yellow
            Start-Sleep -S 3
        }
        elseif ($global:Config.Params.Type -like "*AMD1*") {
            "AMD1" | Out-File ".\build\txt\minertype.txt" -Force
            Global:Write-Log "Group 1 is AMD- Commands and Stats will work for AMD1" -foreground yellow
            Start-Sleep -S 3
        }
        elseif ($global:Config.Params.Type -like "*CPU*") {
            if ($Global:GPU_Count -eq 0) {
                "CPU" | Out-File ".\build\txt\minertype.txt" -Force
                Global:Write-Log "Group 1 is CPU- Commands and Stats will work for CPU" -foreground yellow
                Start-Sleep -S 3
            }
        }
        elseif ($global:Config.Params.Type -like "*ASIC*") {
            if ($global:GPU_Count -eq 0) {
                "ASIC" | Out-File ".\build\txt\minertype.txt" -Force
                Global:Write-Log "Group 1 is ASIC- Commands and Stats will work for ASIC" -foreground yellow
            }
        }
    }
    
    ## Aaaaannnd...Que that sexy loading screen
    Global:Get-SexyUnixLogo
    Start-Process ".\build\bash\screentitle.sh" -Wait    

    ##Data and Hive Configs
    Global:Write-Log "Getting Data" -ForegroundColor Yellow
    Global:Get-Data

    ## Set Arguments/New Parameters
    if ($global:Config.hive_params.HiveID) {
        $global:Config.hive_params | ConvertTo-Json | Set-Content ".\build\txt\hivekeys.txt"
    }
}
