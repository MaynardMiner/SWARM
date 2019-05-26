function start-watchdog {
    If ($global:Config.Params.Platform -eq "linux") {
        Start-Process "screen" -ArgumentList "-S pidinfo -d -m"
        Start-Sleep -S 1
        Start-Process ".\build\bash\pidinfo.sh" -ArgumentList "pidinfo miner"
    }
}

function Get-Data {

    if (Test-Path ".\build\bash\stats") {
        Copy-Item ".\build\bash\stats" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x stats"
        Set-Location "/"
        Set-Location $global:Dir     
    }

    if (Test-Path ".\build\bash\nview") {
        Copy-Item ".\build\bash\nview" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x nview"
        Set-Location "/"
        Set-Location $global:Dir     
    }

    if (Test-Path ".\build\bash\bans") {
        Copy-Item ".\build\bash\bans" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x bans"
        Set-Location "/"
        Set-Location $global:Dir     
    }

    if (Test-Path ".\build\bash\get") {
        Copy-Item ".\build\bash\get" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x get"
        Set-Location "/"
        Set-Location $global:Dir     
    }

    if (-not (Test-Path ".\build\export\libnvrtc-builtins.so.10.1")) {
        $Dir = (Split-Path $script:MyInvocation.MyCommand.Path)
        Start-Process ln -ArgumentList "-s $dir/build/export/libnvrtc-builtins.so.10.1.105 $dir/build/export/libnvrtc-builtins.so.10.1" -Wait
        Set-Location "/"
        Set-Location $global:Dir     
    }

    if (-not (Test-Path ".\build\export\libnvrtc-builtins.so")) {
        $Dir = (Split-Path $script:MyInvocation.MyCommand.Path)
        Start-Process ln -ArgumentList "-s $dir/build/export/libnvrtc-builtins.so.10.1 $dir/build/export/libnvrtc-builtins.so" -Wait
        Set-Location "/"
        Set-Location $global:Dir     
    }

    if (-not (Test-Path ".\build\export\libcudart.so.10.1")) {
        $Dir = (Split-Path $script:MyInvocation.MyCommand.Path)
        Start-Process ln -ArgumentList "-s $dir/build/export/libcudart.so.10.1.105 $dir/build/export/libcudart.so.10.1" -Wait
        Set-Location "/"
        Set-Location $global:Dir     
    }

    if (-not (Test-Path ".\build\export\libcudart.so.10.0")) {
        $Dir = (Split-Path $script:MyInvocation.MyCommand.Path)
        Start-Process ln -ArgumentList "-s $dir/build/export/libcudart.so.10.0.130 $dir/build/export/libcudart.so.10.0" -Wait
        Set-Location "/"
        Set-Location $global:Dir     
    }
    
    if (-not (Test-Path ".\build\export\libcudart.so.9.2")) {
        $Dir = (Split-Path $script:MyInvocation.MyCommand.Path)
        Start-Process ln -ArgumentList "-s $dir/build/export/libcudart.so.9.2.148 $dir/build/export/libcudart.so.9.2" -Wait
        Set-Location "/"
        Set-Location $global:Dir     
    }

    if (-not (Test-Path ".\build\export\libmicrohttpd.so.10")) {
        $Dir = (Split-Path $script:MyInvocation.MyCommand.Path)
        Start-Process ln -ArgumentList "-s $dir/build/export/libmicrohttpd.so.10.34.0 $dir/build/export/libmicrohttpd.so.10" -Wait
        Set-Location "/"
        Set-Location $global:Dir     
    }

    if (-not (Test-Path ".\build\export\libcudart.so.10.1")) {
        $Dir = (Split-Path $script:MyInvocation.MyCommand.Path)
        Start-Process ln -ArgumentList "-s $dir/build/export/libcudart.so.10.0.130 $dir/build/export/libcudart.so.10.0" -Wait
        Set-Location "/"
        Set-Location $global:Dir     
    }
    
    if (-not (Test-Path ".\build\export\libhwloc.so.5")) {
        $Dir = (Split-Path $script:MyInvocation.MyCommand.Path)
        Start-Process ln -ArgumentList "-s $dir/build/export/libhwloc.so.5.5.0 $dir/build/export/libhwloc.so.5" -Wait
        Set-Location "/"
        Set-Location $global:Dir     
    }

    if (-not (Test-Path ".\build\export\libstdc++.so.6")) {
        Start-Process ln -ArgumentList "-s $CmdDir/build/export/libstdc++.so.6.0.25 $CmdDir/build/export/libstdc++.so.6" -Wait
        Set-Location "/"
        Set-Location $global:Dir     
    }

    if (-not (Test-Path ".\build\export\libnvrtc.so.9.2")) {
        Start-Process ln -ArgumentList "-s $CmdDir/build/export/libnvrtc.so.9.2.148 $CmdDir/build/export/libnvrtc.so.9.2" -Wait
        Set-Location "/"
        Set-Location $global:Dir     
    }

    if (-not (Test-Path ".\build\export\libnvrtc.so.10.0")) {
        Start-Process ln -ArgumentList "-s $CmdDir/build/export/libnvrtc.so.10.0.130 $CmdDir/build/export/libnvrtc.so.10.0" -Wait
        Set-Location "/"
        Set-Location $global:Dir     
    }

    if (-not (Test-Path ".\build\export\libnvrtc.so.10.1")) {
        Start-Process ln -ArgumentList "-s $CmdDir/build/export/libnvrtc.so.10.1.105 $CmdDir/build/export/libnvrtc.so.10.1" -Wait
        Set-Location "/"
        Set-Location $global:Dir     
    }

    if (Test-Path ".\build\bash\get-oc") {
        Copy-Item ".\build\bash\get-oc" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x get-oc"
        Set-Location "/"
        Set-Location $global:Dir     
    }
   
    if (Test-Path ".\build\bash\active") {
        Copy-Item ".\build\bash\active" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x active"
        Set-Location "/"
        Set-Location $global:Dir     
    }

    if (Test-Path ".\build\bash\version") {
        Copy-Item ".\build\bash\version" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x version"
        Set-Location "/"
        Set-Location $global:Dir     
    }
    
    if (Test-Path ".\build\bash\get-screen") {
        Copy-Item ".\build\bash\get-screen" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x get-screen"
        Set-Location "/"
        Set-Location $global:Dir     
    }
   
    if (Test-Path ".\build\bash\mine") {
        Copy-Item ".\build\bash\mine" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x mine"
        Set-Location "/"
        Set-Location $global:Dir     
    }
   
    if (Test-Path ".\build\bash\background") {
        Copy-Item ".\build\bash\background" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x background"
        Set-Location "/"
        Set-Location $global:Dir     
    }
   
    if (Test-Path ".\build\bash\pidinfo") {
        Copy-Item ".\build\bash\pidinfo" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x pidinfo"
        Set-Location "/"
        Set-Location $global:Dir     
    }

    if (Test-Path ".\build\bash\dir.sh") {
        Copy-Item ".\build\bash\dir.sh" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x dir.sh"
        Set-Location "/"
        Set-Location $global:Dir     
    }

    if (Test-Path ".\build\bash\benchmark") {
        Copy-Item ".\build\bash\benchmark" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x benchmark"
        Set-Location "/"
        Set-Location $global:Dir     
    }

    if (Test-Path ".\build\bash\clear_profits") {
        Copy-Item ".\build\bash\clear_profits" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x clear_profits"
        Set-Location "/"
        Set-Location $global:Dir     
    }  

    if (Test-Path ".\build\bash\clear_watts") {
        Copy-Item ".\build\bash\clear_watts" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x clear_watts"
        Set-Location "/"
        Set-Location $global:Dir     
    }  

    if (Test-Path ".\build\bash\get-lambo") {
        Copy-Item ".\build\bash\get-lambo" -Destination "/usr/bin" -force | Out-Null
        Set-Location "/usr/bin"
        Start-Process "chmod" -ArgumentList "+x get-lambo"
        Set-Location "/"
        Set-Location $global:Dir     
    }
   
    Set-Location $global:Dir
    
}

function Get-GPUCount {

    $nvidiacounted = $false
    $amdcounted = $false
    $DeviceList = @{ }
    if ($global:Config.Params.Type -like "*AMD*") { $DeviceList.Add("AMD", @{ })
    }
    if ($global:Config.Params.Type -like "*NVIDIA*") { $DeviceList.Add("NVIDIA", @{ })
    }
    if ($global:Config.Params.Type -like "*CPU*") { $DeviceList.Add("CPU", @{ })
    }

    Invoke-Expression "lspci" | Tee-Object -Variable lspci | Out-null
    $lspci | Set-Content ".\build\txt\gpucount.txt"
    $GetBus = Get-Content ".\build\txt\gpucount.txt"
    $GetBus = $GetBus | Select-String "VGA", "3D"
    $AMDCount = 0
    $NVIDIACount = 0
    $CardCount = 0


    $GetBus | Foreach {
        if ($_ -like "*Advanced Micro Devices*" -or $_ -like "*RS880*" -or $_ -like "*Stoney*" -or $_ -like "*NVIDIA*" -and $_ -notlike "*nForce*") {
            if ($_ -like "*Advanced Micro Devices*" -or $_ -like "*RS880*" -or $_ -like "*Stoney*") {
                if ($global:Config.Params.Type -like "*AMD*") {
                    $DeviceList.AMD.Add("$AMDCount", "$CardCount")
                    $AMDCount++
                    $CardCount++
                }
            }
            if ($_ -like "*NVIDIA*") {
                if ($global:Config.Params.Type -like "*NVIDIA*") {
                    $DeviceList.NVIDIA.Add("$NVIDIACount", "$CardCount")
                    $NVIDIACount++
                    $CardCount++
                }
            }
        }
    }

    $global:Config.Params.Type | Foreach {
        if ($_ -like "*CPU*") {
            Write-Log "Getting CPU Count"
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

function Start-LinuxConfig {

    ## Start SWARM watchdog (for automatic shutdown)
    start-watchdog

    ## Kill Previous Screens
    start-killscript

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
        $global:Config.Hive_Params.HiveWorker = $RigConf.WORKER_NAME -replace "`"", ""
        $global:Config.Hive_Params.HivePassword = $RigConf.RIG_PASSWD -replace "`"", ""
        $global:Config.Hive_Params.HiveMirror = $RigConf.HIVE_HOST_URL -replace "`"", ""
        $global:Config.Hive_Params.FarmID = $RigConf.FARM_ID -replace "`"", ""
        $global:Config.Hive_Params.HiveID = $RigConf.RIG_ID -replace "`"", ""
        $global:Config.Hive_Params.Wd_enabled = $RigConf.WD_ENABLED -replace "`"", ""
        $global:Config.Hive_Params.Wd_Miner = $RigConf.WD_MINER -replace "`"", ""
        $global:Config.Hive_Params.Wd_reboot = $RigConf.WD_REBOOT -replace "`"", ""
        $global:Config.Hive_Params.Wd_minhashes = $RigConf.WD_MINHASHES -replace "`"", ""
        $global:Config.Hive_Params.Miner = $RigConf.MINER -replace "`"", ""
        $global:Config.Hive_Params.Miner2 = $RigConf.MINER2 -replace "`"", ""
        $global:Config.Hive_Params.Timezone = $RigConf.TIMEZONE -replace "`"", ""

        ## HiveOS Specific Stuff
        if ($NotHiveOS -eq $false) {
            if ($global:Config.Params.Type -like "*NVIDIA*" -or $global:Config.Params.Type -like "*AMD*") {
                Invoke-Expression ".\build\bash\libc.sh" | Tee-Object -Variable libc | Out-Null
                Invoke-Expression ".\build\bash\libv.sh" | Tee-Object -Variable libv | Out-Null
                $libc | % { write-log $_ }
                Start-Sleep -S 1
                $libv | % { write-log $_ }
                Start-Sleep -S 1
            }

            write-log "Clearing Trash Folder"
            Invoke-Expression "rm -rf .local/share/Trash/files/*" | Tee-Object -Variable trash | Out-Null
            $Trash | % { Write-Log $_ }
        }

        ## Set Cuda for commands
        if ($global:Config.Params.Type -like "*NVIDIA*") { $global:Config.Params.Cuda | Set-Content ".\build\txt\cuda.txt" }

        ## Get Total GPU Count
        $Global:GPU_Count = Get-GPUCount
    
        ## Let User Know What Platform commands will work for- Will always be Group 1.
        $global:Config.Params.Type | ForEach-Object {
            if ($_ -eq "NVIDIA1") {
                "NVIDIA1" | Out-File ".\build\txt\minertype.txt" -Force
                write-Log "Group 1 is NVIDIA- Commands and Stats will work for NVIDIA1" -foreground yellow
                Start-Sleep -S 3
            }
            if ($_ -eq "AMD1") {
                "AMD1" | Out-File ".\build\txt\minertype.txt" -Force
                write-Log "Group 1 is AMD- Commands and Stats will work for AMD1" -foreground yellow
                Start-Sleep -S 3
            }
            if ($_ -eq "CPU") {
                if ($Global:GPU_Count -eq 0) {
                    "CPU" | Out-File ".\build\txt\minertype.txt" -Force
                    write-Log "Group 1 is CPU- Commands and Stats will work for CPU" -foreground yellow
                    Start-Sleep -S 3
                }
            }
            if ($_ -eq "ASIC") {
                if ($global:GPU_Count -eq 0) {
                    "ASIC" | Out-File ".\build\txt\minertype.txt" -Force
                    write-Log "Group 1 is ASIC- Commands and Stats will work for ASIC" -foreground yellow
                }
            }
        }
    }
    
    ## Aaaaannnd...Que that sexy loading screen
    Get-SexyUnixLogo
    Start-Process ".\build\bash\screentitle.sh" -Wait    

    ##Data and Hive Configs
    write-Log "Getting Data" -ForegroundColor Yellow
    Get-Data

    ## Set Arguments/New Parameters
    if ($global:Config.Hive_Params.HiveID) {
        $global:Config.Hive_Params | ConvertTo-Json | Set-Content ".\build\txt\hivekeys.txt"
    }
}
