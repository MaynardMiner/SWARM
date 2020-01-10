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

Function Global:Get-PCISlot($X) { 

    switch ($X) {
        "0:2:2" { $busId = "00:02.0" }
        "1:0:0" { $busID = "01:00.0" }
        "2:0:0" { $busID = "02:00.0" }
        "3:0:0" { $busID = "03:00.0" }
        "4:0:0" { $busID = "04:00.0" }
        "5:0:0" { $busID = "05:00.0" }
        "6:0:0" { $busID = "06:00.0" }
        "7:0:0" { $busID = "07:00.0" }
        "8:0:0" { $busID = "08:00.0" }
        "9:0:0" { $busID = "09:00.0" }
        "10:0:0" { $busID = "0a:00.0" }
        "11:0:0" { $busID = "0b:00.0" }
        "12:0:0" { $busID = "0c:00.0" }
        "13:0:0" { $busID = "0d:00.0" }
        "14:0:0" { $busID = "0e:00.0" }
        "15:0:0" { $busID = "0f:00.0" }
        "16:0:0" { $busID = "0g:00.0" }
        "17:0:0" { $busID = "0h:00.0" }
        "18:0:0" { $busID = "0i:00.0" }
        "19:0:0" { $busID = "0j:00.0" }
        "20:0:0" { $busID = "0k:00.0" }
        "21:0:0" { $busID = "0l:00.0" }
        "22:0:0" { $busID = "0m:00.0" }
        "23:0:0" { $busID = "0n:00.0" }
        "24:0:0" { $busID = "0o:00.0" }
        "25:0:0" { $busID = "0p:00.0" }
        "26:0:0" { $busID = "0q:00.0" }
        "27:0:0" { $busID = "0r:00.0" }
        "28:0:0" { $busID = "0s:00.0" }
        "29:0:0" { $busID = "0t:00.0" }
        "30:0:0" { $busID = "0u:00.0" }
    }

    $busID
}



Function Global:Get-Bus {

    $GPUS = @()
    
    $OldCount = if (Test-Path ".\debug\gpu-count.txt") { $(Get-Content ".\debug\gpu-count.txt") }
    if ($OldCount) {
        Write-Log "Previously Detected GPU List Is:" -ForegroundColor Yellow
        $OldCount | Out-Host
        Start-Sleep -S .5
    }

    $NewCount = @()
    $info = [System.Diagnostics.ProcessStartInfo]::new();
    $info.FileName = ".\build\apps\pci\lspci.exe";
    $info.UseShellExecute = $false;
    $info.RedirectStandardOutput = $true;
    $info.Verb = "runas";
    $Proc = [System.Diagnostics.Process]::New();
    $proc.StartInfo = $Info;
    $proc.Start() | Out-Null;
    $proc.WaitForExit();
    if ($proc.HasExited) { while (-not $proc.StandardOutput.EndOfStream) { $NewCount += $Proc.StandardOutput.ReadLine(); }}
    $NewCount = $NewCount | Where {$_ -like "*VGA*" -or $_ -like "*3D controller*"}

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
        $NVSMI | % { $_."pci.bus_id" = $_."pci.bus_id".split("00000000:") | Select -Last 1 }
    }

    $GPUData = @()

    $Data | % {
        if ($_.vendorid -eq "1002") {
            $busid = $(Global:Get-PCISlot $_.location)
            $GPUData += [PSCustomObject]@{
                "busid"     = $busid
                "name"      = $_.cardname
                "brand"     = "amd"
                "subvendor" = $_.subvendor
                "mem"       = "$($_.memsize)MB"
                "vbios"     = $_.biosversion
                "mem_type"  = $_.memvendor
            }
        }
        elseif ($_.vendorid -eq "10DE") {
            $busid = $(Global:Get-PCISlot $_.location)
            $SMI = $NVSMI | Where "pci.bus_id" -eq $busid
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
            $busid = $(Global:Get-PCISlot $_.location)
            $GPUData += [PSCustomObject]@{
                busid = $busid
                name  = $_.cardname
                brand = "cpu"
            }
        }
    }

    ### Sort list so onboard is first
    $GPUS += $GPUData | Where busid -eq "00:02.0"
    $GPUs += $GPUData | Where busid -ne "00:02.0" | Sort-Object -Property busid

    $NewCount | Set-Content ".\debug\gpu-count.txt"

    $GPUS
}

function Global:Get-GPUCount {

    $Bus = $(vars).BusData
    $DeviceList = @{ AMD = @{ }; NVIDIA = @{ }; CPU = @{ } }
    $OCList = @{ AMD = @{ }; Onboard = @{ }; NVIDIA = @{ }; }
    $GN = $false
    $GA = $false
    $NoType = $true

    $DeviceCounter = 0
    $OCCounter = 0
    $NvidiaCounter = 0
    $AmdCounter = 0 
    $OnboardCounter = 0

    $Bus | Foreach {
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
        $global:Config.user_params.type = @()
        $global:Config.params.type = @()
        log "Searching For Mining Types" -ForegroundColor Yellow
        if ($GN -and $GA) {
            log "AMD and NVIDIA Detected" -ForegroundColor Magenta
            $(vars).types += "AMD1", "NVIDIA2"
            $(arg).Type += "AMD1", "NVIDIA2"
            $global:config.user_params.type += "AMD1", "NVIDIA2"
            $global:config.params.type += "AMD1", "NVIDIA2"                  
        }
        elseif ($GN) {
            log "NVIDIA Detected: Adding NVIDIA" -ForegroundColor Magenta
            $(vars).types += "NVIDIA1" 
            $(arg).Type += "NVIDIA1"
            $global:config.user_params.type += "NVIDIA1" 
            $global:config.params.type += "NVIDIA1"        
        }
        elseif ($GA) {
            log "AMD Detected: Adding AMD" -ForegroundColor Magenta
            $(vars).types += "AMD1" 
            $(arg).Type += "AMD1"
            $global:config.user_params.type += "AMD1" 
            $global:config.params.type += "AMD1"    
        }
        log "Adding CPU"
        if ([string]$(arg).CPUThreads -eq "") { 
            $threads = $(Get-CimInstance -ClassName 'Win32_Processor' | Select-Object -Property 'NumberOfCores').NumberOfCores; 
            $(vars).threads = $threads
            $(arg).CPUThreads = $threads
            $global:config.user_params.CPUThreads = $threads
            $global:config.params.CPUThreads = $threads
        }
        log "Using $($(arg).CPUThreads) cores for mining"
        $(vars).types += "CPU"
        $(arg).Type += "CPU"
        $global:config.user_params.type += "CPU"
        $global:config.params.type += "CPU"
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
                $bat = "CMD /r pwsh -ExecutionPolicy Bypass -command `"Set-Location C:\; Set-Location `'$($(vars).dir)`'; Start-Process `"SWARM.bat`"`""
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
    $Desktop = [Environment]::GetFolderPath("Desktop")
    $Desk_Term = "$Desktop\SWARM-TERMINAL.bat"
    if (-Not (Test-Path $Desk_Term)) {
        log "
            
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
        $Term_Script += "ECHO       bench bans"
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
    if ($(arg).Type -like "*NVIDIA*") { [Environment]::SetEnvironmentVariable("CUDA_DEVICE_ORDER", "PCI_BUS_ID", "User") }
        
    ## Check for NVIDIA-SMI and nvml.dll in system32. If it is there- copy to NVSMI
    $x86_driver = [IO.Path]::Join(${env:ProgramFiles(x86)}, "NVIDIA Corporation")
    $x64_driver = [IO.Path]::Join($env:ProgramFiles, "NVIDIA Corporation")
    $x86_NVSMI = [IO.Path]::Join($x86_driver, "NVSMI")
    $x64_NVSMI = [IO.Path]::Join($x64_driver, "NVSMI")
    $smi = [IO.Path]::Join($env:windir, "system32\nvidia-smi.exe")
    $nvml = [IO.Path]::Join($env:windir, "system32\nvml.dll")

    if ( [IO.Directory]::Exists($x86_driver) ) {
        if (-not [IO.Directory]::Exists($x86_NVSMI)) { [IO.Directory]::CreateDirectory($x86_NVSMI) | Out-Null }
        $dest = [IO.Path]::Join($x86_NVSMI, "nvidia-smi.exe")
        try { [IO.File]::Copy($smi, $dest, $true) | Out-Null } catch { }
        $dest = [IO.Path]::Join($x86_NVSMI, "nvml.dll")
        try { [IO.File]::Copy($nvml, $dest, $true) | Out-Null } catch { }
    }

    if ( [IO.Directory]::Exists($x64_driver) ) {
        if (-not [IO.Directory]::Exists($x64_NVSMI)) { [IO.Directory]::CreateDirectory($x64_NVSMI) | Out-Null }
        $dest = [IO.Path]::Join($x64_NVSMI, "nvidia-smi.exe")
        try { [IO.File]::Copy($smi, $dest, $true) | Out-Null } catch { }
        $dest = [IO.Path]::Join($x64_NVSMI, "nvml.dll")
        try { [IO.File]::Copy($nvml, $dest, $true) | Out-Null } catch { }
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

    if ($DoBus -eq $true) { $(vars).BusData = Global:Get-Bus }
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
        $Enabled = $(cat ".\config\parameters\autofan.json" | ConvertFrom-Json | ConvertFrom-StringData).ENABLED
        if ($Enabled -eq 1) {
            log "Starting Autofan" -ForeGroundColor Cyan
            $start = [launchcode]::New()
            $FilePath = "$PSHome\pwsh.exe"
            $CommandLine = '"' + $FilePath + '"'
            $arguments = "-executionpolicy bypass -command `".\build\powershell\scripts\autofan.ps1`""
            $CommandLine += " " + $arguments
            $New_Miner = $start.New_Miner($filepath, $CommandLine, $global:Dir)
            $Process = Get-Process | Where id -eq $New_Miner.dwProcessId
            $Process.ID | Set-Content ".\build\pid\autofan.txt"
        }
    }
    ## Aaaaannnnd...Que that sexy logo. Go Time.

    Global:Get-SexyWinLogo

}