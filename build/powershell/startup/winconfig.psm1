Function Resolve-PCIBusInfo { 

    param ( 
        [parameter(ValueFromPipeline = $true, Mandatory = $true)] 
        [string] 
        $locationInfo 
    ) 
    PROCESS { 
        [void]($locationInfo -match "\d+,\d+,\d+")
        $busId, $deviceID, $functionID = $matches[0] -split "," 
    
        switch ($busId) {
            1 { $busID = "01:00.0" }
            2 { $busID = "02:00.0" }
            3 { $busID = "03:00.0" }
            4 { $busID = "04:00.0" }
            5 { $busID = "05:00.0" }
            6 { $busID = "06:00.0" }
            7 { $busID = "07:00.0" }
            8 { $busID = "08:00.0" }
            9 { $busID = "09:00.0" }
            10 { $busID = "0a:00.0" }
            11 { $busID = "0b:00.0" }
            12 { $busID = "0c:00.0" }
            13 { $busID = "0d:00.0" }
            14 { $busID = "0e:00.0" }
            15 { $busID = "0f:00.0" }
            16 { $busID = "0g:00.0" }
            17 { $busID = "0h:00.0" }
            18 { $busID = "0i:00.0" }
            19 { $busID = "0j:00.0" }
            20 { $busID = "0k:00.0" }
        }

        new-object psobject -property @{ 
            "BusID"      = $busID; 
            "DeviceID"   = "$deviceID" 
            "FunctionID" = "$functionID" 
        } 
    }          
}
    
Function Get-BusFunctionID {
    #gwmi -query "SELECT * FROM Win32_PnPEntity"
    $GPUS = @()
    $Services = @("nvlddmkm", "amdkmdap", "igfx", "BasicDisplay")
    $Devices = Get-CimInstance -namespace root\cimv2 -class Win32_PnPEntity | where Service -in $Services | Where DeviceID -like "*PCI*"
    
    for ($i = 0; $i -lt $Devices.Count; $i++) {
        $deviceId = $Devices[$i].PNPDeviceID
        $locationInfo = (get-itemproperty -path "HKLM:\SYSTEM\CurrentControlSet\Enum\$deviceID" -name locationinformation -ErrorAction Stop).locationINformation
        $businfo = Resolve-PCIBusInfo -locationInfo $locationinfo
        $subvendorlist = Get-Content ".\build\data\vendor.json" | ConvertFrom-Json
        $getsubvendor = $Devices[$i].PNPDeviceID -split "&REV_" | Select -first 1
        $getsubvendor = $getsubvendor.Substring($getsubvendor.Length - 4)
        if ($subvendorlist.$getsubvendor) { $subvendor = $subvendorlist.$getsubvendor }
        elseif ($Devices[$i].PNPDeviceID -like "*PCI\VEN_10DE*") { $subvendor = "nvidia" }
        elseif ($Devices[$i].PNPDeviceID -like "*PCI\VEN_1002*") { $subvendor = "amd" }
        else { $subvendor = "microsoft" }

        if ($Devices[$i].PNPDeviceID -like "*PCI\VEN_10DE*") { $brand = "nvidia" }
        elseif ($Devices[$i].PNPDeviceID -like "*PCI\VEN_1002*") { $brand = "amd" }
        else { $Brand = "microsoft" }

        $GPURAM = (Get-CimInstance Win32_VideoController | where PNPDeviceID -eq $Devices[$i].PNPDeviceID).AdapterRam
        $GPURAM = "{0:f0}" -f $($GPURAM / 1000000)
        $GPURAM = "$($GPURAM)M"

        $GPUS += [PSCustomObject]@{
            "Name"      = $Devices[$i].Name;
            "PnPID"     = $Devices[$i].PNPDeviceID
            "PCIBusID"  = "$($businfo.BusID)"
            "subvendor" = $subvendor
            "Brand"     = $brand
            "ram"       = $GPURAM
        }
    }
    $GPUS
}

function Get-GPUCount {

    $Bus = $global:BusData | Sort-Object PCIBusID
    $DeviceList = @{ }
    $OCList = @{ }

    if ($global:Config.Params.Type -like "*AMD*") { $DeviceList.Add("AMD", @{ })
    }
    if ($global:Config.Params.Type -like "*NVIDIA*") { $DeviceList.Add("NVIDIA", @{ })
    }
    if ($global:Config.Params.Type -like "*CPU*") { $DeviceList.Add("CPU", @{ })
    }

    if ($global:Config.Params.Type -like "*AMD*") { $OCList.Add("AMD", @{ })
    }
    if ($global:Config.Params.Type -like "*NVIDIA*") { $OCList.Add("NVIDIA", @{ })
    }
    $OCList.Add("Onboard", @{ })

    $DeviceCounter = 0
    $OCCounter = 0
    $NvidiaCounter = 0
    $AmdCounter = 0 
    $OnboardCounter = 0

    $Bus | Foreach {
        $Sel = $_
        if ($Sel.Brand -eq "nvidia" -and $Sel.PCIBusID -ne "0") {
            $DeviceList.NVIDIA.Add("$NvidiaCounter", "$DeviceCounter")
            $OCList.NVIDIA.Add("$NvidiaCounter", "$DeviceCounter")
            $NvidiaCounter++
            $DeviceCounter++
            $OCCounter++
        }
        elseif ($Sel.Brand -eq "amd" -and $Sel.PCIBusID -ne "0") {
            $DeviceList.AMD.Add("$AmdCounter", "$DeviceCounter")
            $OCList.AMD.Add("$AmdCounter", "$OCCounter")
            $AmdCounter++
            $DeviceCounter++
            $OCCounter++
        }
        else {
            $OCList.Onboard.Add("$OnboardCounter", "$OCCounter")
            $OnboardCounter++
            $OCCounter++
        }
    }
    
    if ($global:Config.Params.Type -like "*CPU*") { for ($i = 0; $i -lt $global:Config.Params.CPUThreads; $i++) { $DeviceList.CPU.Add("$($i)", $i) } }
    $DeviceList | ConvertTo-Json | Set-Content ".\build\txt\devicelist.txt"
    $OCList | ConvertTo-Json | Set-Content ".\build\txt\oclist.txt"
    $GPUCount = 0
    $GPUCount += $DeviceList.Nvidia.Count
    $GPUCount += $DeviceList.AMD.Count
    $GPUCount
}
function Start-WindowsConfig {

    ## Add Swarm to Startup
    if ($global:Config.Params.Startup) {
        $CurrentUser = $env:UserName
        $Startup_Path = "C:\Users\$CurrentUser\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
        $Bat_Startup = Join-Path $Startup_Path "SWARM.bat"
        switch ($global:Config.Params.Startup) {
            "Yes" {
                write-Log "Attempting to add current SWARM.bat to startup" -ForegroundColor Magenta
                write-Log "If you do not wish SWARM to start on startup, use -Startup No argument"
                write-Log "Startup FilePath: $Startup_Path"
                $bat = "CMD /r pwsh -ExecutionPolicy Bypass -command `"Set-Location $global:dir; Start-Process `"SWARM.bat`"`""
                $Bat_Startup = Join-Path $Startup_Path "SWARM.bat"
                $bat | Set-Content $Bat_Startup
            }
            "No" {
                write-Log "Startup No Was Specified. Removing From Startup" -ForegroundColor Magenta
                if (Test-Path $Bat_Startup) { Remove-Item $Bat_Startup -Force }
            }    
        }
    }
    
    ##Create a CMD.exe shortcut for SWARM on desktop
    $CurrentUser = $env:UserName
    $Desk_Term = "C:\Users\$CurrentUser\desktop\SWARM-TERMINAL.bat"
    if (-Not (Test-Path $Desk_Term)) {
        write-Log "
            
    Making a terminal on desktop. This can be used for commands.
    
    " -ForegroundColor Yellow
        $Term_Script = @()
        $Term_Script += "`@`Echo Off"
        $Term_Script += "ECHO You can run terminal commands here."
        $Term_Script += "ECHO Commands such as:"
        $Term_Script += "echo.       "
        $Term_Script += "echo.       "
        $Term_Script += "ECHO       get stats"
        $Term_Script += "ECHO       get active"
        $Term_Script += "ECHO       get help"
        $Term_Script += "ECHO       benchmark timeout"
        $Term_Script += "ECHO       version query"
        $Term_Script += "echo.       "
        $Term_Script += "echo.       "
        $Term_Script += "echo.       "
        $Term_Script += "ECHO For full command list, see: https://github.com/MaynardMiner/SWARM/wiki"
        $Term_Script += "echo.       "
        $Term_Script += "echo.       "
        $Term_Script += "echo.       "
        $Term_Script += "ECHO Starting CMD.exe"
        $Term_Script += "echo.       "
        $Term_Script += "echo.       "
        $Term_Script += "echo.       "
        $Term_Script += "cmd.exe"
        $Term_Script | Set-Content $Desk_Term
    }
    
    ## Windows Bug- Set Cudas to match PCI Bus Order
    if ($global:Config.Params.Type -like "*NVIDIA*") { [Environment]::SetEnvironmentVariable("CUDA_DEVICE_ORDER", "PCI_BUS_ID", "User") }
    
    ##Set Cuda For Commands
    if ($global:Config.Params.Type -like "*NVIDIA*") { $global:Config.Params.Cuda = "10"; $global:Config.Params.Cuda | Set-Content ".\build\txt\cuda.txt" }
    
    ##Detect if drivers are installed, not generic- Close if not. Print message on screen
    if ($global:Config.Params.Type -like "*NVIDIA*" -and -not (Test-Path "C:\Program Files\NVIDIA Corporation\NVSMI\nvml.dll")) {
        write-Log "nvml.dll is missing" -ForegroundColor Red
        Start-Sleep -S 3
        write-Log "To Fix:" -ForegroundColor Blue
        write-Log "Update Windows, Purge Old NVIDIA Drivers, And Install Latest Drivers" -ForegroundColor Blue
        Start-Sleep -S 3
        write-Log "Closing Miner"
        Start-Sleep -S 1
        exit
    }
    
    ## Fetch Ram Size, Write It To File (For Commands)
    $TotalMemory = [math]::Round((Get-CimInstance -ClassName CIM_ComputerSystem).TotalPhysicalMemory / 1mb, 2) 
    $TotalMemory | Set-Content ".\build\txt\ram.txt"
    
    ## GPU Bus Hash Table
    $global:BusData = Get-BusFunctionID
    
    ## Get Total GPU HashTable
    $Global:GPU_Count = Get-GPUCount
    
    ## Websites
    if ($global:Websites) {
        $GetNetMods = @($global:NetModules | Foreach { Get-ChildItem $_ })
        $GetNetMods | ForEach-Object { Import-Module $_.FullName }
        Import-Module -Name "$global:Web\methods.psm1"
        $rigdata = Get-RigData $Global:Config.Params.Platform

        $global:Websites | ForEach-Object {

            switch ($_) {
                "HiveOS" {
                    $hiveresponse = Start-Peekaboo $rigdata
                    if ($hiveresponse.result) {
                        $RigConf = $hiveresponse
                    }
                    elseif (Test-Path ".\build\txt\get-hello.txt") {
                        Write-Log "WARNGING: Failed To Contact HiveOS. Using Last Known Configuration"
                        Start-Sleep -S 2
                        $RigConf = Get-Content ".\build\txt\get-hello.txt" | ConvertFrom-Json
                    }
                
                    if ($RigConf) {
                        $RigConf.result | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
                            $Action = $_
                
                            Switch ($Action) {
                                "config" {
                                    $Rig = [string]$RigConf.result.config | ConvertFrom-StringData                
                                    $global:Config.Hive_Params.HiveWorker = $Rig.WORKER_NAME -replace "`"", ""
                                    $global:Config.Hive_Params.HivePassword = $Rig.RIG_PASSWD -replace "`"", ""
                                    $global:Config.Hive_Params.HiveMirror = $Rig.HIVE_HOST_URL -replace "`"", ""
                                    $global:Config.Hive_Params.FarmID = $Rig.FARM_ID -replace "`"", ""
                                    $global:Config.Hive_Params.HiveID = $Rig.RIG_ID -replace "`"", ""
                                    $global:Config.Hive_Params.Wd_enabled = $Rig.WD_ENABLED -replace "`"", ""
                                    $global:Config.Hive_Params.Wd_Miner = $Rig.WD_MINER -replace "`"", ""
                                    $global:Config.Hive_Params.Wd_reboot = $Rig.WD_REBOOT -replace "`"", ""
                                    $global:Config.Hive_Params.Wd_minhashes = $Rig.WD_MINHASHES -replace "`"", ""
                                    $global:Config.Hive_Params.Miner = $Rig.MINER -replace "`"", ""
                                    $global:Config.Hive_Params.Miner2 = $Rig.MINER2 -replace "`"", ""
                                    $global:Config.Hive_Params.Timezone = $Rig.TIMEZONE -replace "`"", ""
                
                                    if (Test-Path ".\build\txt\hivekeys.txt") { $OldHiveKeys = Get-Content ".\build\txt\hivekeys.txt" | ConvertFrom-Json }
                
                                    ## If password was changed- Let Hive know message was recieved
                
                                    if ($OldHiveKeys) {
                                        if ("$($global:Config.Hive_Params.HivePassword)" -ne "$($OldHiveKeys.HivePassword)") {
                                            $method = "message"
                                            $messagetype = "warning"
                                            $data = "Password change received, wait for next message..."
                                            $DoResponse = Add-HiveResponse -Method $method -MessageType $messagetype -Data $data -CommandID $command.result.id
                                            $DoResponse = $DoResponse | ConvertTo-Json -Depth 1 -Compress
                                            $SendResponse = Invoke-RestMethod "$($global:Config.Hive_Params.HiveMirror)/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
                                            $SendResponse
                                            $DoResponse = @{method = "password_change_received"; params = @{rig_id = $global:Config.Hive_Params.HiveID; passwd = $global:Config.Hive_Params.HivePassword }; jsonrpc = "2.0"; id = "0" }
                                            $DoResponse = $DoResponse | ConvertTo-Json -Depth 1 -Compress
                                            $Send2Response = Invoke-RestMethod "$mirror/worker/api" -TimeoutSec 15 -Method POST -Body $DoResponse -ContentType 'application/json'
                                        }
                                    }
                
                                    ## Set Arguments/New Parameters
                                    $global:Config.Hive_Params | ConvertTo-Json | Set-Content ".\build\txt\hivekeys.txt"
                                }
                
                                ##If Hive Sent OC Start SWARM OC
                                "nvidia_oc" {
                                    Start-NVIDIAOC $RigConf.result.nvidia_oc 
                                }
                                "amd_oc" {
                                    Start-AMDOC $RigConf.result.amd_oc
                                }
                            }
                        }
                        ## Print Data to output, so it can be recorded in transcript
                        $RigConf.result.config
                        $GetNetMods | ForEach-Object {Remove-Module $_.BaseName} 
                        Remove-Module -Name "methods"
                    }
                    else {
                        write-Log "No HiveOS Rig.conf- Do you have an account? Did you use your farm hash?"
                        Start-Sleep -S 2
                        $GetNetMods | ForEach-Object {Remove-Module $_.BaseName} 
                        Remove-Module -Name "methods"
                    }
                }

            }

        }
    }

## Aaaaannnnd...Que that sexy logo. Go Time.

Get-SexyWinLogo

}