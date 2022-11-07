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
Function Global:Get-Bus {

    $GPUS = @()
    
    $OldCount = if (Test-Path ".\debug\gpucount.txt") { $(Get-Content ".\debug\gpucount.txt") }
    if ($OldCount) {
        Write-Log "Previously Detected GPU List Is:" -ForegroundColor Yellow
        $OldCount | Out-Host
        Write-Log "Run 'Hive_Windows_Reset.bat' if this count is in error count again." -ForegroundColor Yellow
        Start-Sleep -S .5
    }

    $NewCount = @()
    $info = [System.Diagnostics.ProcessStartInfo]::new();
    $info.FileName = ".\build\cmd\lspci.bat";
    $info.UseShellExecute = $false;
    $info.RedirectStandardOutput = $true;
    $info.Verb = "runas";
    $Proc = [System.Diagnostics.Process]::New();
    $proc.StartInfo = $Info
    $ttimer = [System.Diagnostics.Stopwatch]::New()
    $ttimer.Restart();
    $proc.Start() | Out-Null
    while (-not $Proc.StandardOutput.EndOfStream) {
        $NewCount += $Proc.StandardOutput.ReadLine();
        if ($ttimer.Elapsed.Seconds -gt 15) {
            $proc.kill() | Out-Null;
            break;
        }
    }
    $Proc.Dispose();            
    $NewCount = $NewCount | Where-Object { $_ -like "*VGA*" -or $_ -like "*3D controller*" }

    if ([string]$OldCount -ne [string]$NewCount) {
        Write-Log "Current Detected GPU List Is:" -ForegroundColor Yellow
        $NewCount | Out-Host
        Start-Sleep -S .5
        Write-Log ""
        Write-Log "GPU count is different - Gathering GPU information" -ForegroundColor Magenta

        ## Add key to bypass install question:
        Set-Location HKCU:
        if (-not (test-Path .\Software\techPowerUp)) {
            New-Item -Path .\Software -Name techPowerUp | Out-Null
            New-Item -path ".\Software\techPowerUp" -Name "GPU-Z" | Out-Null
            New-ItemProperty -Path ".\Software\techPowerUp\GPU-Z" -Name "Install_Dir" -Value "no" | Out-Null
        }
        Set-Location $(vars).dir

        $proc = Start-Process ".\build\apps\gpu-z\gpu-z.exe" -ArgumentList "-dump $($(vars).dir)\debug\data.xml" -PassThru
        $proc | Wait-Process
        
        if (test-Path ".\debug\data.xml") {
            $Data = $([xml](Get-Content ".\debug\data.xml")).gpuz_dump.card
        }
        else {
            Write-Log "WARNING: Failed to gather GPU data" -ForegroundColor Yellow
        }
    }
    elseif (test-path ".\debug\data.xml") {
        $Data = $([xml](Get-Content ".\debug\data.xml")).gpuz_dump.card
    }
    else { log "WARNING: No GPU Data file found!" -ForegroundColor Yellow }

    if ("NVIDIA" -in $Data.vendor) {
        invoke-expression ".\build\cmd\nvidia-smi.bat --query-gpu=gpu_bus_id,gpu_name,memory.total,power.min_limit,power.default_limit,power.max_limit,vbios_version --format=csv" | Tee-Object -Variable NVSMI | Out-Null
        $NVSMI = $NVSMI | ConvertFrom-Csv
        $NVSMI | ForEach-Object { $_."pci.bus_id" = $_."pci.bus_id".split("00000000:") | Select-Object -Last 1 }
    }

    $GPUData = @()

    $Data | ForEach-Object {
        if ($_.vendorid -eq "1002") {
            $first_hex = [int]($_.location -split ":" | Select-Object -First 1)
            $second_hex = [int]($_.location -split ":" | Select-Object -Skip 1 -First 1)
            $third_hex = [int]($_.location -split ":" | Select-Object -Last 1)
            $first_hex = "{0:x2}" -f $first_hex
            $second_hex = "{0:x2}" -f $second_hex
            $third_hex = "{0:x1}" -f $third_hex
            $busid = "$first_hex`:$second_hex`.$third_hex"
            $GPUData += [PSCustomObject]@{
                "busid"     = $busid
                "name"      = $_.cardname
                "brand"     = "amd"
                "subvendor" = $_.subvendor
                "mem"       = "$($_.memsize)MB"
                "vbios"     = $_.biosversion
                "mem_type"  = "$($_.memvendor) $($_.memtype)"
            }
        }
        elseif ($_.vendorid -eq "10DE") {
            $first_hex = [int]($_.location -split ":" | Select-Object -First 1)
            $second_hex = [int]($_.location -split ":" | Select-Object -Skip 1 -First 1)
            $third_hex = [int]($_.location -split ":" | Select-Object -Last 1)
            $first_hex = "{0:x2}" -f $first_hex
            $second_hex = "{0:x2}" -f $second_hex
            $third_hex = "{0:x1}" -f $third_hex
            $busid = "$first_hex`:$second_hex`.$third_hex"
            $SMI = $NVSMI | Where-Object "pci.bus_id" -eq $busid
            $GPUData += [PSCustomObject]@{
                busid     = $busid
                name      = $_.cardname
                brand     = "nvidia"
                subvendor = $_.subvendor
                mem       = $SMI."memory.total [MiB]"
                vbios     = $SMI.vbios_version
                plim_min  = $SMI."power.min_limit [W]"
                plim_def  = $SMI."power.default_limit [W]"
                plim_max  = $SMI."power.max_limit [W]"
            }
        }
        else {
            $first_hex = [int]($_.location -split ":" | Select-Object -First 1)
            $second_hex = [int]($_.location -split ":" | Select-Object -Skip 1 -First 1)
            $third_hex = [int]($_.location -split ":" | Select-Object -Last 1)
            $first_hex = "{0:x2}" -f $first_hex
            $second_hex = "{0:x2}" -f $second_hex
            $third_hex = "{0:x1}" -f $third_hex
            $busid = "$first_hex`:$second_hex`.$third_hex"
            $GPUData += [PSCustomObject]@{
                busid = $busid
                name  = $_.cardname
                brand = "cpu"
            }
        }
    }

    ### Sort list so onboard is first
    $GPUS += $GPUData | Where-Object busid -eq "00:02.0"
    $GPUs += $GPUData | Where-Object busid -ne "00:02.0" | Sort-Object -Property busid

    $NewCount | Set-Content ".\debug\gpucount.txt"

    $GPUS
}

function Global:Get-GPUCount {

    $Bus = $(vars).BusData
    $DeviceList = @{ AMD = [ordered]@{ }; NVIDIA = [ordered]@{ }; CPU = [ordered]@{ } }
    $OCList = @{ AMD = @{ }; Onboard = @{ }; NVIDIA = @{ }; }
    $GN = $false
    $GA = $false
    $NoType = $true

    $DeviceCounter = 0
    $OCCounter = 0
    $NvidiaCounter = 0
    $AmdCounter = 0 
    $OnboardCounter = 0

    $Bus | ForEach-Object {
        $Sel = $_
        if ($Sel.Brand -eq "nvidia") {
            $GN = $true
            $DeviceList.NVIDIA.Add("$NvidiaCounter", "$DeviceCounter")
            $OCList.NVIDIA.Add("$NvidiaCounter", "$DeviceCounter")
            $NvidiaCounter++
            $DeviceCounter++
            $OCCounter++
        }
        elseif ($Sel.Brand -eq "amd") {
            $GA = $true
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

    if ([string]$(arg).type -eq "") {
        $M_Types = @()
        log "Searching For Mining Types" -ForegroundColor Yellow
        if ($GN -and $GA) {
            log "AMD and NVIDIA Detected" -ForegroundColor Magenta
            $M_Types += "AMD1", "NVIDIA2"
        }
        elseif ($GN) {
            log "NVIDIA Detected: Adding NVIDIA" -ForegroundColor Magenta
            $M_Types += "NVIDIA1" 
        }
        elseif ($GA) {
            log "AMD Detected: Adding AMD" -ForegroundColor Magenta
            $M_Types += "AMD1" 
        }
        log "Adding CPU"
        if ([string]$(arg).CPUThreads -eq "") { 
            $threads = $(Get-CimInstance -ClassName 'Win32_Processor' | Select-Object -Property 'NumberOfCores').NumberOfCores; 
        }
        else {
            $threads = $(arg).CPUThreads;
        }
        $M_Types += "CPU"
        $(vars).types = $M_Types
        $(arg).Type = $M_Types
        $global:config.user_params.type = $M_Types
        $global:config.params.type = $M_types
        $(vars).threads = $threads
        $(arg).CPUThreads = $threads
        $global:config.user_params.CPUThreads = $threads
        $global:config.params.CPUThreads = $threads
        log "Using $threads cores for mining"
    }
    
    if ($(arg).Type -like "*CPU*") { for ($i = 0; $i -lt $(arg).CPUThreads; $i++) { $DeviceList.CPU.Add("$($i)", $i) } }
    $DeviceList | ConvertTo-Json | Set-Content ".\debug\devicelist.txt"
    $OCList | ConvertTo-Json | Set-Content ".\debug\oclist.txt"
    $GPUCount = 0
    $GPUCount += $DeviceList.Nvidia.Count
    $GPUCount += $DeviceList.AMD.Count
    $GPUCount
}
function Global:Start-WindowsConfig {

    ## Add Swarm to Startup
    if ($(arg).Startup) {
        $CurrentUser = $env:UserName
        $Startup_Path = "C:\Users\$CurrentUser\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
        $Bat_Startup = Join-Path $Startup_Path "SWARM.bat"
        switch ($(arg).Startup) {
            "Yes" {
                log "Attempting to add current SWARM.bat to startup" -ForegroundColor Magenta
                log "If you do not wish SWARM to start on startup, use -Startup No argument"
                log "Startup FilePath: $Startup_Path"
                $exec = "$PSHOME\pwsh.exe".Replace("C:\","")
                $exec = "C:\`"$exec`""
                $bat = "CMD /r $exec -ExecutionPolicy Bypass -command `"Set-Location C:\; Set-Location `'$($(vars).dir)`'; Start-Process `"SWARM.bat`"`""
                $Bat_Startup = Join-Path $Startup_Path "SWARM.bat"
                $bat | Set-Content $Bat_Startup
            }
            "No" {
                log "Startup No Was Specified. Removing From Startup" -ForegroundColor Magenta
                if (Test-Path $Bat_Startup) { Remove-Item $Bat_Startup -Force }
            }    
        }
    }
    
    ##Create a CMD.exe shortcut for SWARM on desktop
    ## Create Shortcut
    $Exec_Shortcut = [IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "SWARM.lnk")
    $Term_Shortcut = [IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "SWARM terminal.lnk")

    if (test-Path $Exec_Shortcut) { Remove-Item $Exec_Shortcut -Force | Out-Null }
    if (test-Path $Term_Shortcut) { Remove-Item $Term_Shortcut -Force | Out-Null }

    $WshShell = New-Object -comObject WScript.Shell

    $Shortcut = $WshShell.CreateShortcut($Exec_Shortcut)
    $Shortcut.TargetPath = join-path $(vars).dir "SWARM.bat"
    $Shortcut.WorkingDirectory = $(vars).dir
    $Shortcut.IconLocation = Join-Path $(vars).dir "build\apps\icons\SWARM.ico"
    $Shortcut.Description = "Shortcut For SWARM.bat. You can right-click -> edit this shortcut"
    $Shortcut.Save()

    $Shortcut = $WshShell.CreateShortcut($Term_Shortcut)
    $Shortcut.TargetPath = join-path $(vars).dir "SWARM Terminal.bat"
    $Shortcut.WorkingDirectory = $(vars).dir
    $Shortcut.IconLocation = Join-Path $(vars).dir "build\apps\icons\comb.ico"
    $Shortcut.Description = "Shortcut To Open Terminal For SWARM. Will Run As Administrator"
    $Shortcut.Save()

    $bytes = [System.IO.File]::ReadAllBytes($Exec_Shortcut)
    $bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON (Use –bor to set RunAsAdministrator option and –bxor to unset)
    [System.IO.File]::WriteAllBytes($Exec_Shortcut, $bytes)

    $bytes = [System.IO.File]::ReadAllBytes($Term_Shortcut)
    $bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON (Use –bor to set RunAsAdministrator option and –bxor to unset)
    [System.IO.File]::WriteAllBytes($Term_Shortcut, $bytes)


    ## Check for NVIDIA-SMI and nvml.dll in system32. If it is there- copy to NVSMI
    $x86_driver = [IO.Path]::Join(${env:ProgramFiles(x86)}, "NVIDIA Corporation")
    $x64_driver = [IO.Path]::Join($env:ProgramFiles, "NVIDIA Corporation")
    $x86_NVSMI = [IO.Path]::Join($x86_driver, "NVSMI")
    $x64_NVSMI = [IO.Path]::Join($x64_driver, "NVSMI")
    $smi = [IO.Path]::Join($env:windir, "system32\nvidia-smi.exe")
    $nvml = [IO.Path]::Join($env:windir, "system32\nvml.dll")

    ## Set the device order to match the PCI bus if NVIDIA is installed
    if ([IO.Directory]::Exists($x86_driver) -or [IO.Directory]::Exists($x64_driver)) {
        $Target1 = [System.EnvironmentVariableTarget]::Machine
        $Target2 = [System.EnvironmentVariableTarget]::Process
        [Environment]::SetEnvironmentVariable("CUDA_DEVICE_ORDER", "PCI_BUS_ID", $Target1)
        [Environment]::SetEnvironmentVariable("CUDA_DEVICE_ORDER", "PCI_BUS_ID", $Target2)
    }

    if ( [IO.Directory]::Exists($x86_driver) ) {
        if (-not [IO.Directory]::Exists($x86_NVSMI)) { [IO.Directory]::CreateDirectory($x86_NVSMI) | Out-Null }
        $dest = [IO.Path]::Join($x86_NVSMI, "nvidia-smi.exe")
        try { [IO.File]::Copy($smi, $dest, $true) | Out-Null } catch { }
        $dest = [IO.Path]::Join($x86_NVSMI, "nvml.dll")
        try { [IO.File]::Copy($nvml, $dest, $true) | Out-Null } catch { }
        ## Output issue for user if transfer failed
        if(-not ([IO.File]::Exists($dest))) {
            log "nvidia-smi and nvml.dll does not exist in $x86_NVSMI. SWARM failed to transfer. Miners and gpu stats will not work correctly." -ForegroundColor Red
        }
    }

    if ( [IO.Directory]::Exists($x64_driver) ) {
        if (-not [IO.Directory]::Exists($x64_NVSMI)) { [IO.Directory]::CreateDirectory($x64_NVSMI) | Out-Null }
        $dest = [IO.Path]::Join($x64_NVSMI, "nvidia-smi.exe")
        try { [IO.File]::Copy($smi, $dest, $true) | Out-Null } catch { }
        $dest = [IO.Path]::Join($x64_NVSMI, "nvml.dll")
        try { [IO.File]::Copy($nvml, $dest, $true) | Out-Null } catch { }
        if(-not ([IO.File]::Exists($dest))) {
            log "nvidia-smi and nvml.dll does not exist in $x64_NVSMI. SWARM failed to transfer. Miners and gpu stats will not work correctly." -ForegroundColor Red
        }
    }

    ## TDR delay fix for Windows.
    log "Patching TDR delay if required..." -ForegroundColor Yellow
    $Registry = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Default).OpenSubKey("SYSTEM\CurrentControlSet\Control\GraphicsDrivers",$True)
    if("TdrDelay" -notin $Registry.GetValueNames()) {
        $Registry.SetValue("TdrDelay",20,[Microsoft.Win32.RegistryValueKind]::DWord);
        $Registry.SetValue("TdrDdiDelay",10,[Microsoft.Win32.RegistryValueKind]::DWord);
        log "TDR BSOD delay has been set, but restart of PC suggested. Continuing in a few seconds..." -ForegroundColor Magenta
        Start-Sleep -Seconds 10;
    }

    
    ## Fetch Ram Size, Write It To File (For Commands)
    $TotalMemory = [math]::Round((Get-CimInstance -ClassName CIM_ComputerSystem).TotalPhysicalMemory / 1mb, 2) 
    $TotalMemory | Set-Content ".\debug\ram.txt"
    
    ## GPU Bus Hash Table
    $DoBus = $true
    if ($(arg).Type -like "*CPU*" -or $(arg).Type -like "*ASIC*") {
        if ("AMD1" -notin $(arg).type -and "NVIDIA1" -notin $(arg).type -and "NVIDIA2" -notin $(arg).type -and "NVIDIA3" -notin $(arg).type) {
            $Dobus = $false
        }
    }

    if ($DoBus -eq $true) { 
        $(vars).BusData = Global:Get-Bus 
        $(vars).BusData | ConvertTo-Json -Depth 5 | Set-Content ".\debug\busdata.txt"
    }
    $(vars).GPU_Count = Global:Get-GPUCount

    ## Websites
    if ($(vars).WebSites) {
        Global:Add-Module "$($(vars).web)\methods.psm1"
        $rigdata = Global:Get-RigData

        $(vars).WebSites | ForEach-Object {
            switch ($_) {
                "HiveOS" {
                    Global:Get-WebModules "HiveOS"
                    $response = $rigdata | Global:Invoke-WebCommand -Site "HiveOS" -Action "Hello"
                    Global:Start-WebStartup $response "HiveOS"
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

    ## Start AutoFan
    if (test-path ".\config\parameters\autofan.json") {
        $Enabled = $(Get-Content ".\config\parameters\autofan.json" | ConvertFrom-Json | ConvertFrom-StringData).ENABLED
        if ($Enabled -eq 1) {
            log "Starting Autofan" -ForeGroundColor Cyan
            $start = [launchcode]::New()
            $FilePath = "$PSHome\pwsh.exe"
            $CommandLine = '"' + $FilePath + '"'
            $Windowstyle = "Minimized"
            if ($(arg).Hidden -eq "Yes") {
                $Windowstyle = "Hidden"
            }            
            $arguments = "-executionpolicy bypass -WindowStyle $WindowStyle -command `".\build\powershell\scripts\autofan.ps1`""
            $CommandLine += " " + $arguments
            $New_Miner = $start.New_Miner($filepath, $CommandLine, $global:Dir)
            $Process = Get-Process | Where-Object id -eq $New_Miner.dwProcessId
            $Process.ID | Set-Content ".\build\pid\autofan.txt"
        }
    }
    ## Aaaaannnnd...Que that sexy logo. Go Time.

    Global:Get-SexyWinLogo

}