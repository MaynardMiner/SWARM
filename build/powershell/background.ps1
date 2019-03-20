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

param(
    [Parameter(Mandatory = $false)]
    [String]$WorkingDir,
    [Parameter(Mandatory = $false)]
    [String]$Platforms,
    [Parameter(Mandatory = $false)]
    [String]$HiveId,
    [Parameter(Mandatory = $false)]
    [String]$HivePassword,
    [Parameter(Mandatory = $false)]
    [String]$HiveMirror,
    [Parameter(Mandatory = $false)]
    [String]$HiveOS,
    [Parameter(Mandatory = $false)]
    [Double]$REJPercent,
    [Parameter(Mandatory = $false)]
    [string]$Remote,
    [Parameter(Mandatory = $false)]
    [string]$API,
    [Parameter(Mandatory = $false)]
    [Int]$Port,
    [Parameter(Mandatory = $false)]
    [string]$APIPassword
)

Write-Host "Platform is $Platforms"
Write-Host "HiveOS ID is $HiveID"
Write-Host "HiveOS = $HiveOS"

##Icon for windows
if ($Platforms -eq "windows") {
    Set-Location $WorkingDir; Invoke-Expression ".\build\powershell\icon.ps1 `"$WorkingDir\build\apps\comb.ico`""
    $Host.UI.RawUI.BackgroundColor = ($bckgrnd = 'Black')
    $Host.UI.RawUI.ForegroundColor = 'White'
    $Host.PrivateData.ErrorForegroundColor = 'Red'
    $Host.PrivateData.ErrorBackgroundColor = $bckgrnd
    $Host.PrivateData.WarningForegroundColor = 'Magenta'
    $Host.PrivateData.WarningBackgroundColor = $bckgrnd
    $Host.PrivateData.DebugForegroundColor = 'Yellow'
    $Host.PrivateData.DebugBackgroundColor = $bckgrnd
    $Host.PrivateData.VerboseForegroundColor = 'Green'
    $Host.PrivateData.VerboseBackgroundColor = $bckgrnd
    $Host.PrivateData.ProgressForegroundColor = 'Cyan'
    $Host.PrivateData.ProgressBackgroundColor = $bckgrnd
    Clear-Host  
}

## Codebase for Further Functions
. .\build\powershell\hashrates.ps1
. .\build\powershell\commandweb.ps1
. .\build\powershell\response.ps1
. .\build\powershell\hiveoc.ps1
. .\build\powershell\octune.ps1
. .\build\powershell\statcommand.ps1
. .\build\powershell\api.ps1

##Start API Server
Write-Host "API Port is $Port"
if ($Platforms -eq "Windows") {Start-Process "powershell" -ArgumentList "-ExecutionPolicy Bypass -WindowStyle hidden -Command `".\build\powershell\apiwatchdog.ps1 $Port`"" -WorkingDirectory $WorkingDir}
$Posh_api = Get-APIServer
$Posh_Api.BeginInvoke() | Out-Null

if ($API -eq "Yes") {
        Write-Host "API Server Started- you can run http://localhost:$Port/end to close" -ForegroundColor Green
    }

## SWARM miner PID
$CheckForSWARM = ".\build\pid\miner_pid.txt"
if (test-Path $CheckForSWARM) {$GetSWARMID = Get-Content $CheckForSWARM; $GETSWARM = Get-Process -ID $GetSWARMID -ErrorAction SilentlyContinue}

## Simplified functions (To Shorten)
function Get-GPUs {$GPU = $Devices[$i]; $GCount.$TypeS.$GPU};

function Write-MinerData1 {
    Write-host " "
    Write-Host "Miner $MinerType is $MinerAPI api"
    Write-Host "Miner Port is $Port"
    Write-Host "Miner Devices is $Devices"
    Write-Host "Miner is Mining $MinerAlgo"
}

function Write-MinerData2 {
    $global:BRAW | Set-Content ".\build\txt\$MinerType-hash.txt"
    Write-Host "Miner $Name was clocked at $($global:BRAW | ConvertTo-Hash)/s" -foreground Yellow
    if ($Platforms -eq "linux") {$Process = Get-Process | Where Name -clike "*$($MinerType)*"}
    Write-Host "Current Running instances: $($Process.Name)"
}
#function Set-Array {
#  param(
#      [Parameter(Position = 0, Mandatory = $true)]
#      [Object]$ParseRates,
#      [Parameter(Position = 1, Mandatory = $true)]
#      [int]$i,
#      [Parameter(Position = 2, Mandatory = $false)]
#      [string]$factor
#   )
#   try {
#       $Parsed = $ParseRates | % {iex $_}
#        if ($ParseRates.Count -eq 1) {[Double]$Parse = $Parsed}
#        elseif ($ParseRates.Count -gt 1) {[Double]$Parse = if($Parsed[$i]){$Parsed[$i]}else{0}}
#        $Parse
#    }
#    catch {
#        $Parse = 0
#        $Parse
#    }
#}

function Set-Array {
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [Object]$ParseRates,
        [Parameter(Position = 1, Mandatory = $true)]
        [int]$i,
        [Parameter(Position = 2, Mandatory = $false)]
        [string]$factor
    )
    try {
        $Parsed = $ParseRates | % {iex $_}
        $Parse = $Parsed | Select -Skip $i -First 1
        if ($null -eq $Parse) {$Parse = 0}
    }
    catch {$Parse = 0}
    $Parse
}

function Set-APIFailure {
    Write-Host "API Summary Failed- Could Not Total Hashrate Or No Accepted Shares" -Foreground Red; 
    $global:BRAW | Set-Content ".\build\txt\$MinerType-hash.txt";
}
  

## NVIDIA HWMON
function Set-NvidiaStats {

    Switch ($Platforms) {
        "linux" {
            switch ($HiveOS) {
                "No" {
                    timeout -s9 10 ./build/apps/VII-smi | Tee-Object -Variable getstats | Out-Null
                    if ($getstats) {
                        $nvidiai = $getstats | ConvertFrom-StringData
                        $nvinfo = @{}
                        $nvinfo.Add("Fans", @())
                        $nvinfo.Add("Temps", @())
                        $nvinfo.Add("Watts", @())
                        $nvidiai.keys | foreach {if ($_ -like "*fan*") {$nvinfo.Fans += $nvidiai.$_}}
                        $nvidiai.keys | foreach {if ($_ -like "*temperature*") {$nvinfo.Temps += $nvidiai.$_}}
                        $nvidiai.keys | foreach {if ($_ -like "*power*") {if ($nvidiai.$_ -eq "failed to get") {$nvinfo.Watts += "75"}else {$nvinfo.Watts += $nvidiai.$_}}}
                    }
                }
                "Yes" {
                    $HiveStats = "/run/hive/gpu-stats.json"
                    do {
                        for ($i = 0; $i -lt 20; $i++) {
                            if (test-Path $HiveStats) {try {$GetHiveStats = Get-Content $HiveStats | ConvertFrom-Json -ErrorAction Stop}catch {$GetHiveStats = $null}}
                            if ($GetHiveStats -ne $null) {
                                $nvinfo = @{}
                                $nvinfo.Add("Fans", $( $GetHiveStats.fan | % {if ($_ -ne 0) {$_}} ) )
                                $nvinfo.Add("Temps", $( $GetHiveStats.temp | % {if ($_ -ne 0) {$_}} ) )
                            }
                            Start-Sleep -S .5
                        }
                    }while ($GetHiveStats.temp.count -lt 1 -and $GetHiveStats.fan.count -lt 1)
                }
            }
        }

        "windows" {
            invoke-expression ".\build\apps\nvidia-smi.exe --query-gpu=power.draw,fan.speed,temperature.gpu --format=csv" | Tee-Object -Variable nvidiaout | Out-Null
            if ($nvidiaout) {$ninfo = $nvidiaout | ConvertFrom-Csv}
            $NVIDIAFans = $ninfo.'fan.speed [%]' | foreach {$_ -replace ("\%", "")}
            $NVIDIATemps = $ninfo.'temperature.gpu'
            $NVIDIAPower = $ninfo.'power.draw [W]' | foreach {$_ -replace ("\[Not Supported\]", "75")} | foreach {$_ -replace (" W", "")}        
            $NVIDIAStats = @{}
            $NVIDIAStats.Add("Fans", $NVIDIAFans)
            $NVIDIAStats.Add("Temps", $NVIDIATemps)
            $NVIDIAStats.Add("Power", $NVIDIAPower)
            $nvinfo = $NVIDIAStats  
        }
    }
    $nvinfo
}

## AMD HWMON
function Set-AMDStats {

    switch ($Platforms) {
        "windows" {
            Invoke-Expression ".\build\apps\odvii.exe s" | Tee-Object -Variable amdout | Out-Null
            if ($amdout) {
                $AMDStats = @{}
                $amdinfo = $amdout | ConvertFrom-StringData
                $ainfo = @{}
                $aerrors = @{}
                $aerrors.Add("Errors", @())
                $ainfo.Add("Fans", @())
                $ainfo.Add("Temps", @())
                $ainfo.Add("Watts", @())
                $amdinfo.keys | foreach {if ($_ -like "*Fan*") {$ainfo.Fans += $amdinfo.$_}}
                $amdinfo.keys | foreach {if ($_ -like "*Temp*") {$ainfo.Temps += $amdinfo.$_}}
                $amdinfo.keys | foreach {if ($_ -like "*Watts*") {$ainfo.Watts += $amdinfo.$_}}
                $amdinfo.keys | foreach {if ($_ -like "*Errors*") {$aerrors.Errors += $amdinfo.$_}}
                $AMDFans = $ainfo.Fans
                $AMDTemps = $ainfo.Temps
                $AMDPower = $ainfo.Watts
                if ($aerrors.Errors) {
                    Write-Host "Warning Errors Detected From Drivers:" -ForegroundColor Red
                    $aerrors.Errors | % {Write-host "$($_)" -ForegroundColor Red}
                    Write-Host "Drivers/Settings May Be Set Incorrectly/Not Compatible
      " -ForegroundColor Red
                }
            }
        }

        "linux" {
            switch ($HiveOS) {
                "Yes" {
                    $HiveStats = "/run/hive/gpu-stats.json"
                    do {
                        for ($i = 0; $i -lt 20; $i++) {
                            if (test-Path $HiveStats) {try {$GetHiveStats = Get-Content $HiveStats | ConvertFrom-Json -ErrorAction Stop}catch {$GetHiveStats = $null}}
                            if ($GetHiveStats -ne $null) {
                                $AMDStats = @{}
                                $AMDFans = $( $GetHiveStats.fan | % {if ($_ -ne 0) {$_}} )
                                $AMDTemps = $( $GetHiveStats.temp | % {if ($_ -ne 0) {$_}} )
                            }
                            Start-Sleep -S .5
                        }
                    }while ($GetHiveStats.temp.count -lt 1 -and $GetHiveStats.fan.count -lt 1)
                }
                "No" {
                    $AMDStats = @{}
                    timeout -s9 10 rocm-smi -f | Tee-Object -Variable AMDFans | Out-Null
                    $AMDFans = $AMDFans | Select-String "%" | foreach {$_ -split "\(" | Select -Skip 1 -first 1} | foreach {$_ -split "\)" | Select -first 1}
                    timeout -s9 10 rocm-smi -t | Tee-Object -Variable AMDTemps | Out-Null
                    $AMDTemps = $AMDTemps | Select-String -CaseSensitive "Temperature" | foreach {$_ -split ":" | Select -skip 2 -First 1} | foreach {$_ -replace (" ", "")} | foreach {$_ -replace ("c", "")}
                }
            }
        }
    }

    $AMDStats.Add("Fans", $AMDFans)
    $AMDStats.Add("Temps", $AMDTemps)
    $AMDStats.Add("Power", $AMDPower)

    $AMDStats

}

##Get Active Miners And Devices
$GCount = Get-Content ".\build\txt\devicelist.txt" | ConvertFrom-Json

##Set Device Flags
$DevNVIDIA = $false
$DevAMD = $false
if ($GCount -like "*NVIDIA*") {$DevNVIDIA = $true; Write-Host "NVIDIA Detected"};
if ($GCount -like "*AMD*") {$DevAMD = $true; Write-Host "AMD Detected"};

##Hive Config
#if (Test-Path ".\build\txt\hivekeys.txt") {$config = Get-Content ".\build\txt\hivekeys.txt" | ConvertFrom-Json}

##Timers
$BackgroundTimer = New-Object -TypeName System.Diagnostics.Stopwatch
$BackgroundTimer.Restart()
$RestartTimer = New-Object -TypeName System.Diagnostics.Stopwatch
#$wd_miner_timer = New-Object -TypeName System.Diagnostics.Stopwatch
#$wd_reboot_timer = New-Object -TypeName System.Diagnostics.Stopwatch
#$wd_miner_seconds = [Double]$config.wd_miner * 60
#$wd_reboot_seconds = [Double]$config.wd_reboot * 60

##Get hive naming conventions:
$GetHiveNames = ".\config\pools\pool-algos.json"
$HiveNames = if (Test-Path $GetHiveNames) {Get-Content $GetHiveNames | ConvertFrom-Json}

While ($True) {
    ## Timer For When To Restart Loop
    $RestartTimer.Restart()

    ##Bool for Current Miners
    $Switched = $false

    ##Determine if Miner Switched
    $CheckForMiners = ".\build\txt\bestminers.txt"
    if (test-Path $CheckForMiners) {$GetMiners = Get-Content $CheckForMiners | ConvertFrom-Json -ErrorAction Stop}
    else {Write-Host "No Miners Running..."}
    if ($GETSWARM.HasExited -eq $true) {Write-Host "SWARM Has Exited..."}

    ##Handle New Miners
    if ($GetMiners -and $GETSWARM.HasExited -eq $false) {
        $GetMiners | ForEach {if (-not ($CurrentMiners | Where Path -eq $_.Path | Where Arguments -eq $_.Arguments )) {$Switched = $true}}
        if ($Switched -eq $True) {
            Write-Host "Miners Have Switched
" -ForegroundColor Cyan
            $CurrentMiners = $GetMiners;
            ##Set Starting Date & Device Flags
            $StartTime = Get-Date
            ## Determine Which GPU's to stat
            $CurrentMiners | Foreach {
                $NEW = 0; 
                $NEW | Set-Content ".\build\txt\$($_.Type)-hash.txt";
                $Name = $($_.Name)
            }
        }
    }
    else {
        $StartTime = Get-Date
        $NEW = 0;
        if ($DevNVIDIA -eq $true) { 
            $NEW | Set-Content ".\build\txt\NVIDIA1-hash.txt";
            $NEW | Set-Content ".\build\txt\NVIDIA2-hash.txt";
            $NEW | Set-Content ".\build\txt\NVIDIA2-hash.txt";
        }
        if ($DevAMD -eq $true) {
            $NEW | Set-Content ".\build\txt\AMD1-hash.txt";  
        }
        $NEW | Set-Content ".\build\txt\CPU-hash.txt";
    }

    ## Set-OC
    if ($Switched -eq $true) {
        Write-Host "Starting Tuning"
        Start-OC -Platforms $Platforms -Dir $WorkingDir
        ## ADD Delay for OC and Miners To Start Up
        Start-Sleep -S 10
    }

    ## Determine if CPU in only used
    $CPUOnly = $true
    $CurrentMiners | Foreach {if ($_.Type -like "*NVIDIA*" -or $_.Type -like "*AMD*") {$CPUOnly = $false; "GPU" | Set-Content ".\build\txt\miner.txt"}}
    if ($CPUOnly -eq $true) {"CPU" | Set-Content ".\build\txt\miner.txt"}
    ## Build Initial Hash Tables For Stats
    $global:GPUHashrates = [PSCustomObject]@{}
    $global:CPUHashrates = [PSCustomObject]@{}
    $global:GPUsFans = [PSCustomObject]@{}
    $global:GPUsTemps = [PSCustomObject]@{}
    $global:GPUsPower = [PSCustomObject]@{}
    for ($i = 0; $i -lt $GCount.CPU.PSObject.Properties.Value.Count; $i++) {$global:CPUHashrates | Add-Member -MemberType NoteProperty -Name "$($GCount.CPU.$i)" -Value 0; }
    if ($DevAMD -eq $true) {for ($i = 0; $i -lt $GCount.AMD.PSObject.Properties.Value.Count; $i++) {$global:GPUHashrates | Add-Member -MemberType NoteProperty -Name "$($GCount.AMD.$i)" -Value 0; $global:GPUsFans | Add-Member -MemberType NoteProperty -Name "$($GCount.AMD.$i)" -Value 0; $global:GPUsTemps | Add-Member -MemberType NoteProperty -Name "$($GCount.AMD.$i)" -Value 0; $global:GPUsPower | Add-Member -MemberType NoteProperty -Name "$($GCount.AMD.$i)" -Value 0}}
    if ($DevNVIDIA -eq $true) {for ($i = 0; $i -lt $GCount.NVIDIA.PSObject.Properties.Value.Count; $i++) {$global:GPUHashrates | Add-Member -MemberType NoteProperty -Name "$($GCount.NVIDIA.$i)" -Value 0; $global:GPUsFans | Add-Member -MemberType NoteProperty -Name "$($GCount.NVIDIA.$i)" -Value 0; $global:GPUsTemps | Add-Member -MemberType NoteProperty -Name "$($GCount.NVIDIA.$i)" -Value 0; $global:GPUsPower | Add-Member -MemberType NoteProperty -Name "$($GCount.NVIDIA.$i)" -Value 0}}

    ## Reset All Stats, Rebuild Tables
    $global:BALGO = @(); $global:BHiveAlgo = @(); $global:BHashRates = @(); $global:BFans = @(); $global:BTemps = @(); $global:BPower = @(); 
    $global:BCPUKHS = $null; $global:BCPUACC = 0; $global:BCPUREJ = 0; $global:BRAW = 0; $global:BKHS = 0; $global:BREJ = 0; $global:BACC = 0;
    $global:GPUHashrates | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | % {$global:GPUHashrates.$_ = 0};
    $global:CPUHashrates | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | % {$global:CPUHashrates.$_ = 0};
    $global:GPUsFans | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | % {$global:GPUsFans.$_ = 0};
    $global:GPUsTemps | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | % {$global:GPUsTemps.$_ = 0};
    $global:GPUsPower | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | % {$global:GPUsPower.$_ = 0};

    ## Windows-To-Hive Stats
    if ($Platforms -eq "windows") {
        ## Rig Metrics
        if ($HiveOS -eq "Yes") {
            $ramtotal = Get-Content ".\build\txt\ram.txt"
            $cpu = $(Get-WmiObject Win32_PerfFormattedData_PerfOS_System).ProcessorQueueLength
            $LoadAverage = Set-Stat -Name "load-average" -Value $cpu
            $LoadAverages = @("$([Math]::Round($LoadAverage.Minute,2))", "$([Math]::Round($LoadAverage.Minute_5,2))", "$([Math]::Round($LoadAverage.Minute_10,2))")
            $ramfree = $(Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
        }
        if ($DevNVIDIA -eq $true) {$NVIDIAStats = Set-NvidiaStats}
        if ($DevAMD -eq $true) {$AMDStats = Set-AMDStats}
    }

    ## Linux-To-Hive Stats
    if ($Platforms -eq "linux") {
        if ($DevNVIDIA -eq $true) {$NVIDIAStats = Set-NvidiaStats}
        if ($DevAMD -eq $true) {$AMDStats = Set-AMDStats}
    }

    ## Start API Calls For Each Miner
    if ($CurrentMiners -and $GETSWARM.HasExited -eq $false) {
        $CurrentMiners | Foreach {
            ## Miner Information
            $MinerAlgo = "$($_.Algo)"
            $MinerName = "$($_.MinerName)"
            $Name = "$($_.Name)"
            $Server = "localhost"
            $Port = $($_.Port)
            $MinerType = "$($_.Type)"
            $MinerAPI = "$($_.API)"
            $HashPath = ".\logs\$($_.Type).log"
            $global:BHiveAlgo += $HiveNames.$($_.Algo).hiveos_name

            ## Set Object For Type (So It doesn't need to be repeated)
            if ($MinerType -like "*NVIDIA*") {$TypeS = "NVIDIA"}
            elseif ($MinerType -like "*AMD*") {$TypeS = "AMD"}
            elseif ($MinerType -like "*CPU*") {$TypeS = "CPU"}

            ## Determine Devices
            if ($_.Type -ne "CPU") {
                if ($_.Devices -eq "none") {$Devices = Get-DeviceString -TypeCount $GCount.$TypeS.PSObject.Properties.Value.Count}
                else {$Devices = Get-DeviceString -TypeDevices $_.Devices}
            }
            elseif ($_.Type -eq "CPU") {$Devices = Get-DeviceString -TypeCount $GCount.$TypeS.PSObject.Properties.Value.Count}


            ## First Power For Windows
            if ($Platforms -eq "windows" -and $HiveOS -eq "Yes") {
                if ($TypeS -eq "NVIDIA") {$StatPower = $NVIDIAStats.Power}
                if ($TypeS -eq "AMD") {$StatPower = $AMDStats.Power}
                if ($StatPower -ne "" -or $StatPower -ne $null) {for ($i = 0; $i -lt $Devices.Count; $i++) {$global:GPUsPower.$(Get-GPUS) = Set-Array $StatPower $Devices[$i]}}
            }


            ## Now Fans & Temps
            if ($MinerType -Like "*NVIDIA*") {
                switch ($Platforms) {
                    "Windows" {
                        for ($i = 0; $i -lt $Devices.Count; $i++) {try {$global:GPUsFans.$(Get-GPUS) = Set-Array $NVIDIAStats.Fans $Devices[$i]}catch {Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break}}
                        for ($i = 0; $i -lt $Devices.Count; $i++) {try {$global:GPUsTemps.$(Get-GPUS) = Set-Array $NVIDIAStats.Temps $Devices[$i]}catch {Write-Host "Failed To Parse GPU Temp Array" -foregroundcolor red; break}}
                    }
                    "linux" {
                        switch ($HiveOS) {
                            "Yes" {
                                for ($i = 0; $i -lt $Devices.Count; $i++) {try {$global:GPUsFans.$(Get-GPUS) = Set-Array $NVIDIAStats.Fans (Get-GPUs)}catch {Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break}}
                                for ($i = 0; $i -lt $Devices.Count; $i++) {try {$global:GPUsTemps.$(Get-GPUS) = Set-Array $NVIDIAStats.Temps (Get-GPUs)}catch {Write-Host "Failed To Parse GPU Temp Array" -foregroundcolor red; break}}            
                            }
                            "No" {
                                for ($i = 0; $i -lt $Devices.Count; $i++) {try {$global:GPUsFans.$(Get-GPUS) = Set-Array $NVIDIAStats.Fans $Devices[$i]}catch {Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break}}
                                for ($i = 0; $i -lt $Devices.Count; $i++) {try {$global:GPUsTemps.$(Get-GPUS) = Set-Array $NVIDIAStats.Temps $Devices[$i]}catch {Write-Host "Failed To Parse GPU Temp Array" -foregroundcolor red; break}}                    
                            }
                        }
                    }
                }
            }
            if ($MinerType -Like "*AMD*") {
                Switch ($Platforms) {
                    "windows" {
                        for ($i = 0; $i -lt $Devices.Count; $i++) {try {$global:GPUsFans.$(Get-GPUS) = Set-Array $AMDStats.Fans $Devices[$i]}catch {Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break}}
                        for ($i = 0; $i -lt $Devices.Count; $i++) {try {$global:GPUsTemps.$(Get-GPUS) = Set-Array $AMDStats.Temps $Devices[$i]}catch {Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break}}
                    }
                    "linux" {
                        switch ($HiveOS) {
                            "Yes" {
                                for ($i = 0; $i -lt $Devices.Count; $i++) {try {$global:GPUsFans.$(Get-GPUS) = Set-Array $AMDStats.Fans (Get-GPUs)}catch {Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break}}
                                for ($i = 0; $i -lt $Devices.Count; $i++) {try {$global:GPUsTemps.$(Get-GPUS) = Set-Array $AMDStats.Temps (Get-GPUs)}catch {Write-Host "Failed To Parse GPU Temp Array" -foregroundcolor red; break}}
                            }
                            "No" {
                                for ($i = 0; $i -lt $Devices.Count; $i++) {try {$global:GPUsFans.$(Get-GPUS) = Set-Array $AMDStats.Fans $Devices[$i]}catch {Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break}}
                                for ($i = 0; $i -lt $Devices.Count; $i++) {try {$global:GPUsTemps.$(Get-GPUS) = Set-Array $AMDStats.Temps $Devices[$i]}catch {Write-Host "Failed To Parse GPU Temp Array" -foregroundcolor red; break}}
                            }
                        }
                    }
                }
            }

            ## Set Initial Output
            $HS = "khs"
            $global:BRAW = 0
            $MinerACC = 0
            $MinerREJ = 0
            Write-MinerData1

            ## Start Calling Miners

            switch ($MinerAPI) {

                'energiminer' {
                    $Request = $null; try {$Request = Get-Content ".\logs\$MinerType.log" -ErrorAction Stop}catch {}
                    if ($Request) {
                        $Data = $Request | Select-String "Mh/s" | Select -Last 1
                        $Data = $Data -split " "
                        $MHS = 0
                        $MHS = $Data | Select-String -Pattern "Mh/s" -AllMatches -Context 1, 0 | % {$_.Context.PreContext[0]}
                        $MHS = $MHS -replace '\x1b\[[0-9;]*m', ''
                        $global:BRAW = [Double]$MHS * 1000000
                        Write-MinerData2;
                        $global:BKHS += [Double]$MHS * 1000
                        $Hash = $null; $Hash = $Data | Select-String -Pattern "GPU/" -AllMatches -Context 0, 1
                        $Hash = $Hash -replace '\x1b\[[0-9;]*m', '' | % {$_ -split ' ' | Select -skip 3 -first 1}
                        try {for ($i = 0; $i -lt $Devices.Count; $i++) {$global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i)}}catch {Write-Host "Failed To parse GPU Threads" -ForegroundColor Red};
                        $MinerACC = $($Request | Select-String "Accepted").count
                        $MinerREJ = $($Request | Select-String "Rejected").count
                        $global:BACC += $MinerACC
                        $global:BREJ += $MinerREJ
                        $global:BUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
                        $global:BALGO += "$MinerAlgo"
                    }
                    else {Set-APIFailure; break}
                }

                'claymore' {
                    if ($MinerName -eq "PhoenixMiner" -or $MinerName -eq "Phoenixminer.exe") {$Message = @{id = 1; jsonrpc = "2.0"; method = "miner_getstat2"} | ConvertTo-Json -Compress
                    }
                    else {$Message = @{id = 1; jsonrpc = "2.0"; method = "miner_getstat1"} | ConvertTo-Json -Compress
                    }
                    $Request = $null; $Request = Get-TCP -Server $Server -Port $Port -Message $Message 
                    if ($Request) {
                        try {$Data = $Null; $Data = $Request | ConvertFrom-Json -ErrorAction STop; }catch {Write-Host "Failed To parse API" -ForegroundColor Red}
                        if ($Data) {$Summary = $Data.result[2]; $Threads = $Data.result[3]; }
                        if ($Minername -eq "TT-Miner.exe" -or $MinerName -eq "TT-Miner") {$global:BRAW += $Summary -split ";" | Select -First 1 | % {[Double]$_}}
                        else {$global:BRAW += $Summary -split ";" | Select -First 1 | % {[Double]$_ * 1000}}
                        Write-MinerData2;
                        if ($Minername -eq "TT-Miner.exe" -or $MinerName -eq "TT-Miner") {$global:BKHS += $Summary -split ";" | Select -First 1 | % {[Double]$_ / 1000}}
                        else {$global:BKHS += $Summary -split ";" | Select -First 1 | % {[Double]$_}}
                        if ($Minername -eq "TT-Miner.exe" -or $MinerName -eq "TT-Miner") {$Hash = $Null; $Hash = $Threads -split ";" | % {[double]$_ / 1000}}
                        else {$Hash = $Null; $Hash = $Threads -split ";"}
                        try {for ($i = 0; $i -lt $Devices.Count; $i++) {$global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i)}}catch {Write-Host "Failed To parse GPU Threads" -ForegroundColor Red};
                        $MinerACC = $Summary -split ";" | Select -skip 1 -first 1
                        $MinerREJ = $Summary -split ";" | Select -skip 2 -first 1
                        $global:BACC += $Summary -split ";" | Select -skip 1 -first 1
                        $global:BREJ += $Summary -split ";" | Select -skip 2 -first 1
                        $global:BUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
                        $global:BALGO += "$MinerAlgo"
                    }
                    else {Set-APIFailure; break}
                }

                'excavator' {
                    $HS = "khs"
                    $global:BRAW = 0
                    $Message = $null; $Message = @{id = 1; method = "algorithm.list"; params = @()} | ConvertTo-Json -Compress
                    $Request = $null; $Request = Get-TCP -Server $Server -Port $port -Message $Message
                    if ($Request) {
                        try {$Data = $Null; $Data = $Request | ConvertFrom-Json -ErrorAction Stop; }catch {Write-Host "Failed To parse API" -ForegroundColor Red}
                        $global:BRAW = $Summary.algorithms.speed
                        Write-MinerData2;
                        $global:BKHS += [Double]$Summary.algorithms.speed / 1000
                    }
                    else {Set-APIFailure; break}
                    $Message = @{id = 1; method = "worker.list"; params = @()} | ConvertTo-Json -Compress
                    $GetThreads = $Null; $GetThreads = Get-TCP -Server $Server -Port $port -Message $Message
                    if ($GetThreads) {
                        $Threads = $GetThreads | ConvertFrom-Json -ErrorAction Stop
                        $Hash = $Null; $Hash = $Threads.workers.algorithms.speed
                        try {for ($i = 0; $i -lt $Devices.Count; $i++) {$global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i) / 1000}}catch {Write-Host "Failed To parse threads" -ForegroundColor Red};
                        $global:BACC += $Summary.algorithms.accepted_shares
                        $global:BREJ += $Summary.algorithms.rejected_shares
                        $MinerACC += $Summary.algorithms.accepted_shares
                        $MinerREJ += $Summary.algorithms.rejected_shares
                        $global:BUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
                        $global:BALGO += "$($Summary.algorithms.name)"
                    }
                    else {Write-Host "API Threads Failed"; break}
                }

                'miniz' {
                    $HS = "hs"
                    try {$Request = $Null; $Request = Invoke-Webrequest "http://$($server):$port" -UseBasicParsing -TimeoutSec 10}catch {}
                    if ($Request) {
                        $Data = $null; $Data = $Request.Content -split " "
                        $Hash = $Null; $Hash = $Data | Select-String "Sol/s" | Select-STring "data-label" | foreach {$_ -split "</td>" | Select -First 1} | foreach {$_ -split ">" | Select -Last 1}
                        $global:BRAW = $Hash | Select -Last 1
                        Write-MinerData2;
                        $global:BKHS += [Double]$global:BRAW / 1000
                        $Shares = $Data | Select-String "Shares" | Select -Last 1 | foreach {$_ -split "</td>" | Select -First 1} | Foreach {$_ -split ">" | Select -Last 1}
                        $global:BACC += $Shares -split "/" | Select -first 1
                        $global:BREJ += $Shares -split "/" | Select -Last 1
                        $MinerACC = $Shares -split "/" | Select -first 1
                        $MinerREJ = $Shares -split "/" | Select -Last 1
                        try {for ($i = 0; $i -lt $Devices.Count; $i++) {$global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i) / 1000}}catch {Write-Host "Failed To parse Threads" -ForegroundColor Red};
                        $global:BALGO += "$MinerAlgo"
                        $global:BUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
                    }
                    else {Set-APIFailure; break}
                }

                'gminer' {
                    $HS = "hs"
                    $Request = $null; $Request = Get-HTTP -Server $server -Port $Port -Message "/stat" -Timeout 5
                    if ($Request) {
                        try {$Data = $null; $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop}Catch {Write-Host "Failed To parse API" -ForegroundColor Red}
                        $Data.devices.speed | % {$global:BRAW += [Double]$_}
                        $Hash = $Null; $Hash = $Data.devices.speed
                        Write-MinerData2;
                        try {for ($i = 0; $i -lt $Devices.Count; $i++) {$global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i) / 1000}}catch {Write-Host "Failed To parse Threads" -ForegroundColor Red};
                        $Data.devices.accepted_shares | Select -First 1 | Foreach {$MinerACC += $_}
                        $Data.devices.rejected_shares | Select -First 1 | Foreach {$MinerREJ += $_}
                        $Data.devices.accepted_shares | Select -First 1 | Foreach {$global:BACC += $_}
                        $Data.devices.rejected_shares | Select -First 1 | Foreach {$global:BREJ += $_}
                        $Data.devices.speed | foreach {$global:BKHS += [Double]$_}
                        $global:BUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
                        $global:BALGO += "$MinerAlgo"
                    }
                    else {Set-APIFailure; break}
                }

                'grin-miner' {
                    $HS = "hs"
                    try {$Request = Get-Content ".\logs\$MinerType.log" -ErrorAction SilentlyContinue}catch {Write-Host "Failed to Read Miner Log"}
                    if ($Request) {
                        $Hash = @()
                        $Devices | % {
                            $DeviceData = $Null
                            $DeviceData = $Request | Select-String "Device $($_)" | % {$_ | Select-String "Graphs per second: "} | Select -Last 1
                            $DeviceData = $DeviceData -split "Graphs per second: " | Select -Last 1 | % {$_ -split " - Total" | Select -First 1}
                            if ($DeviceData) {$Hash += $DeviceData; $global:BRAW += [Double]$DeviceData}else {$Hash += 0; $global:BRAW += 0}
                        }
                        Write-MinerData2;
                        try {for ($i = 0; $i -lt $Devices.Count; $i++) {$global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i)}}catch {Write-Host "Failed To parse GPU Threads" -ForegroundColor Red};
                        $global:BACCepted = $null
                        $global:BREJected = $null
                        $global:BACCepted = $($Request | Select-String "Share Accepted!!").count
                        $global:BREJected = $($Request | Select-String "Failed to submit a solution").count
                        $global:BACC += $global:BACCepted
                        $global:BREJ += $global:BREJected
                        $MinerACC += $global:BACCepted
                        $MinerREJ += $global:BREJected
                        $global:BUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
                        $global:BALGO += "$MinerAlgo"
                    }
                    else {Set-APIFailure; break}
                }
  
                'ewbf' {
                    $HS = "hs"
                    $Message = $null; $Message = @{id = 1; method = "getstat"} | ConvertTo-Json -Compress
                    $Request = $Null; $Request = Get-TCP -Server $Server -Port $port -Message $Message
                    if ($Request) { 
                        try {$Data = $Null; $Data = $Request | ConvertFrom-Json -ErrorAction Stop; }catch {Write-Host "Failed To parse API" -ForegroundColor Red}
                        $Data = $Data.result
                        $Data.speed_sps | foreach {$global:BRAW += [Double]$_}
                        $Hash = $Null; $Hash = $Data.speed_sps
                        Write-MinerData2;
                        try {for ($i = 0; $i -lt $Devices.Count; $i++) {$global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i) / 1000}}catch {Write-Host "Failed To parse Threads" -ForegroundColor Red};
                        $Data.accepted_shares | Foreach {$MinerACC += $_}
                        $Data.rejected_shares | Foreach {$MinerREJ += $_}
                        $Data.accepted_shares | Foreach {$global:BACC += $_}
                        $Data.rejected_shares | Foreach {$global:BREJ += $_}
                        $Data.speed_sps | foreach {$global:BKHS += [Double]$_}
                        $global:BUPTIME = ((Get-Date) - [DateTime]$Data.start_time[0]).seconds
                        $global:BALGO += "$MinerAlgo"
                    }
                    else {Set-APIFailure; break}
                }

                'ccminer' {
                    $HS = "khs"
                    $Request = $Null; $Request = Get-TCP -Server $Server -Port $port -Message "summary"
                    if ($Request) {
                        Write-Host "MinerName is $MinerName"
                        switch ($MinerName) {
                            "zjazz_cuda.exe" {if ($MinerAlgo -eq "cuckoo") {$Multiplier = 2000000}else {$Multiplier = 1000}}
                            "zjazz_cuda" {if ($MinerAlgo -eq "cuckoo") {$Multiplier = 2000000}else {$Multiplier = 1000}}
                            "zjazz_amd.exe" {if ($MinerAlgo -eq "cuckoo") {$Multiplier = 2000000}else {$Multiplier = 1000}}
                            "zjazz_amd" {if ($MinerAlgo -eq "cuckoo") {$Multiplier = 2000000}else {$Multiplier = 1000}}
                            default {$Multiplier = 1000}
                        }
                        Write-Host "Multiplier is $Multiplier"
                        try {$GetKHS = $Request -split ";" | ConvertFrom-StringData -ErrorAction Stop}catch {Write-Warning "Failed To Get Summary"}
                        $global:BRAW = if ([Double]$GetKHS.KHS -ne 0 -or [Double]$GetKHS.ACC -ne 0) {[Double]$GetKHS.KHS * $Multiplier}
                        Write-MinerData2;
                        $global:BKHS += if ([Double]$GetKHS.KHS -ne 0 -or [Double]$GetKHS.ACC -ne 0) {[Double]$GetKHS.KHS}
                    }
                    else {Set-APIFailure; break}
                    $GetThreads = $Null; $GetThreads = Get-TCP -Server $Server -Port $port -Message "threads"
                    if ($GetThreads) {
                        $Data = $null; $Data = $GetThreads -split "\|"
                        $Hash = $Null; $Hash = $Data -split ";" | Select-String "KHS" | foreach {$_ -replace ("KHS=", "")}
                        try {for ($i = 0; $i -lt $Devices.Count; $i++) {$global:GPUHashrates.$(Get-Gpus) = Set-Array $Hash $i}}catch {Write-Host "Failed To parse Threads" -ForegroundColor Red};
                        try {$MinerACC += $Request -split ";" | Select-String "ACC=" | foreach {$_ -replace ("ACC=", "")}}catch {}
                        try {$MinerREJ += $Request -split ";" | Select-String "REJ=" | foreach {$_ -replace ("REJ=", "")}}catch {}
                        try {$global:BACC += $Request -split ";" | Select-String "ACC=" | foreach {$_ -replace ("ACC=", "")}}catch {}
                        try {$global:BREJ += $Request -split ";" | Select-String "REJ=" | foreach {$_ -replace ("REJ=", "")}}catch {}
                        $global:BALGO += "$MinerAlgo"
                        $global:BUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
                    }
                    else {Write-Host "API Threads Failed"; break}
                }

                'bminer' {
                    $Request = $Null; $Request = Get-HTTP -Port $Port -Message "/api/status"
                    if ($Request) {
                        try {$Data = $Null; $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop; }catch {Write-Host "Failed To parse API" -ForegroundColor Red}
                        for ($i = 0; $i -lt $Devices.Count; $i++) {$GPU = $Devices[$i]; $global:BRAW += [Double]$Data.Miners.$GPU.solver.solution_rate}
                        Write-MinerData2;
                        $Hash = $Null; $Hash = $Data.Miners
                        if ($HS -eq "hs") {$HashFactor = 1}
                        if ($HS -eq "khs") {$Hashfactor = 1000}
                        try {for ($i = 0; $i -lt $Devices.Count; $i++) {$GPU = $Devices[$i]; $global:GPUHashrates.$(Get-Gpus) = [Double]$Hash.$GPU.solver.solution_rate / 1000}}catch {Write-Host "Failed To parse Threads" -ForegroundColor Red};
                        $Data.stratum.accepted_shares | Foreach {$MinerACC += $_}
                        $Data.stratum.rejected_shares | Foreach {$MinerREJ += $_}
                        $Data.stratum.accepted_shares | Foreach {$global:BACC += $_}
                        $Data.stratum.rejected_shares | Foreach {$global:BREJ += $_}
                        for ($i = 0; $i -lt $Devices.Count; $i++) {$GPU = $Devices[$i]; $global:BKHS += [Double]$Data.Miners.$GPU.solver.solution_rate / 1000}
                        $global:BUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
                        $global:BALGO += "$MinerAlgo"
                    }
                    else {Set-APIFailure; break}
                }

                'trex' {
                    $HS = "khs"
                    $Request = $Null; $Request = Get-HTTP -Port $Port -Message "/summary"
                    if ($Request) {
                        try {$Data = $Null; $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop; }catch {Write-Host "Failed To parse API" -ForegroundColor Red}
                        $global:BRAW = if ([Double]$Data.hashrate_minute -ne 0 -or [Double]$Data.accepted_count -ne 0) {[Double]$Data.hashrate_minute}
                        Write-MinerData2;
                        $Hash = $Null; $Hash = $Data.gpus.hashrate_minute
                        try {for ($i = 0; $i -lt $Devices.Count; $i++) {$global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i) / 1000}}catch {Write-Host "Failed To parse Threads" -ForegroundColor Red};
                        $Data.accepted_count | Foreach {$MinerACC += $_}
                        $Data.rejected_count | Foreach {$MinerREJ += $_}
                        $Data.accepted_count | Foreach {$global:BACC += $_}
                        $Data.rejected_count | Foreach {$global:BREJ += $_}
                        $global:BKHS += if ([Double]$Data.hashrate_minute -ne 0 -or [Double]$Data.accepted_count -ne 0) {[Double]$Data.hashrate_minute / 1000}
                        $global:BUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
                        $global:BALGO += "$($Data.Algorithm)"
                    }
                    else {Set-APIFailure; break}
                }
  
                'dstm' {
                    $HS = "hs"
                    $Request = $Null; $Request = $null; $Request = Get-TCP -Server $Server -Port $port -Message "summary"
                    if ($Request) {
                        try {$Data = $Null; $Data = $Request | ConvertFrom-Json -ErrorAction Stop; }catch {Write-Host "Failed To parse GPU Array" -ForegroundColor Red}
                        $Data = $Data.result
                        $Data.sol_ps | foreach {$global:BRAW += [Double]$_}
                        Write-MinerData2;
                        $Hash = $Null; $Hash = $Data.sol_ps
                        try {for ($i = 0; $i -lt $Devices.Count; $i++) {$global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i) / 1000}}catch {Write-Host "Failed To parse GPU Array" -ForegroundColor Red};
                        $Data.rejected_shares | Foreach {$MinerREJ += $_}
                        $Data.accepted_shares | Foreach {$MinerACC += $_}  
                        $Data.rejected_shares | Foreach {$global:BREJ += $_}
                        $Data.accepted_shares | Foreach {$global:BACC += $_}
                        $Data.sol_ps | foreach {$global:BKHS += [Double]$_}
                        $global:BALGO += "$MinerAlgo"
                        $global:BUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
                    }
                    else {Set-APIFailure; break}
                }

                'lolminer' {
                    $HS = "hs"
                    $Message = "/summary"
                    $request = $null; $Request = Get-HTTP -Server $Server -Port $port -Message $Message
                    if ($request) {
                        try {$Data = $Null; $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop; }catch {Write-Host "Failed To parse API" -ForegroundColor Red}
                        $global:BRAW = [Double]$Data.Session.Performance_Summary
                        Write-MinerData2;
                        $Hash = $Data.GPUs.Performance
                        try {for ($i = 0; $i -lt $Devices.Count; $i++) {$global:GPUHashrates.$(Get-Gpus) = (Set-Array $Hash $i) / 1000}}catch {Write-Host "Failed To parse GPU Array" -ForegroundColor Red};
                        $MinerACC += [Double]$Data.Session.Accepted
                        $MinerREJ += [Double]$Data.Session.Submitted - [Double]$Data.Session.Accepted
                        $global:BACC += $Data.Session.Accepted
                        $global:BREJ += [Double]$Data.Session.Submitted - [Double]$Data.Session.Accepted
                        $global:BKHS += [Double]$Data.Session.Performance_Summary / 1000
                        $global:BALGO += "$MinerAlgo"
                        $global:BUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)          
                    }
                    else {Set-APIFailure; break}
                }

                'sgminer-gm' {
                    $HS = "hs"
                    $Message = $null; $Message = @{command = "summary+devs"; parameter = ""} | ConvertTo-Json -Compress
                    $Request = $null; $Request = Get-TCP -Server $Server -Port $port -Message $Message
                    if ($Request) {
                        $Tryother = $false
                        try {$Data = $Null; $Data = $Request | ConvertFrom-Json -ErrorAction Stop}catch {$Tryother = $true}
                        if ($Tryother -eq $true) {
                            try {
                                $Request = $Request.Substring($Request.IndexOf("{"), $Request.LastIndexOf("}") - $Request.IndexOf("{") + 1) -replace " ", "_"
                                $Data = $Request | ConvertFrom-Json -ErrorAction Stop
                            }
                            catch {Write-Host "Failed To parse GPU Array" -ForegroundColor Red}
                        }
                        $summary = $Data.summary.summary
                        $threads = $Data.devs.devs
                        $Hash = $Null; $Sum = $Null;
                        if ($summary.'KHS_5s' -gt 0) {$Sum = $summary.'KHS_5s'; $sgkey = 'KHS_5s'}
                        elseif ($summary.'KHS 5s' -gt 0) {$Sum = $summary.'KHS 5s'; $sgkey = 'KHS 5s'}
                        elseif ($summary.'KHS_30s' -gt 0) {$Sum = $Summary.'KHS_30s'; $sgkey = 'KHS_30s'}
                        elseif ($summary.'KHS 30s' -gt 0) {$sum = $summary.'KHS 30s'; $sgkey = 'KHS 30s'}
                        $Hash = $threads.$sgkey
                        $global:BRAW += [Double]$Sum * 1000
                        $global:BRAW | Set-Content ".\build\txt\$MinerType-hash.txt"
                        Write-MinerData2;
                        $global:BKHS += $Sum
                        try {for ($i = 0; $i -lt $Devices.Count; $i++) {$global:GPUHashrates.$(Get-Gpus) = Set-Array $Hash $i}}catch {Write-Host "Failed To parse GPU Array" -ForegroundColor Red};
                        $summary.Rejected | Foreach {$MinerREJ += $_}
                        $summary.Accepted | Foreach {$MinerACC += $_}    
                        $summary.Rejected | Foreach {$global:BREJ += $_}
                        $summary.Accepted | Foreach {$global:BACC += $_}
                        $global:BALGO += "$MinerALgo"
                        $global:BUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
                    }
                    else {Set-APIFailure; break}
                }

                'cpuminer' {
                    $GetCPUSUmmary = $Null; $GetCPUSummary = Get-TCP -Server $Server -Port $Port -Message "summary"
                    if ($GetCPUSummary) {
                        $CPUSUM = $GetCPUSummary -split ";" | Select-String "KHS=" | foreach {$_ -replace ("KHS=", "")}
                        $CPURAW = [double]$CPUSUM * 1000
                        $CPURAW | Set-Content ".\build\txt\$MinerType-hash.txt"
                    }
                    else {Write-Host "API Summary Failed- Could Not Total Hashrate" -Foreground Red; $CPURAW = 0; $CPURAW | Set-Content ".\build\txt\$MinerType-hash.txt"}
                    $GetCPUThreads = $Null
                    $GetCPUThreads = Get-TCP -Server $Server -Port $Port -Message "threads"
                    if ($GetCPUThreads) {
                        $Data = $GetCPUThreads -split "\|"
                        $kilo = $false
                        $KHash = $Data | Select-String "kH/s"
                        if ($KHash) {$Hash = $Data -split ";" | Select-String "kH/s"; $kilo = $true}
                        else {$Hash = $Data -split ";" | Select-String "H/s"; $kilo = $false}
                        $Hash = $Hash | foreach {$_ -split "=" | Select -Last 1 }
                        $J = $Hash | % {iex $_}
                        $CPUHash = @()
                        if ($kilo -eq $true) {
                            $global:BCPUKHS = 0
                            if ($Hash) {for ($i = 0; $i -lt $Devices.Count; $i++) {$GPU = $Devices[$i]; $global:CPUHashrates.$($GCount.$TypeS.$GPU) = $(if ($J.Count -eq 1) {$J}else {$J[$i]})}}
                            $J |Foreach {$global:BCPUKHS += $_}
                            $CPUHS = "khs"
                        }
                        else {
                            $global:BCPUKHS = 0
                            if ($Hash) {for ($i = 0; $i -lt $Devices.Count; $i++) {$GPU = $Devices[$i]; $global:CPUHashrates.$($GCount.$TypeS.$GPU) = $(if ($J.Count -eq 1) {$J / 1000}else {$J[$i] / 1000})}}
                            $J |Foreach {$global:BCPUKHS += $_}
                            $CPUHS = "hs"
                        }
                        $global:CPUHashrates | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {$CPUHash += "CPU=$($global:CPUHashrates.$_)"}
                        $global:BCPUACC = $GetCPUSummary -split ";" | Select-String "ACC=" | foreach {$_ -replace ("ACC=", "")}
                        $global:BCPUREJ = $GetCPUSummary -split ";" | Select-String "REJ=" | foreach {$_ -replace ("REJ=", "")}
                        $CPUUPTIME = $GetCPUSummary -split ";" | Select-String "UPTIME=" | foreach {$_ -replace ("UPTIME=", "")}
                        $CPUALGO = $GetCPUSummary -split ";" | Select-String "ALGO=" | foreach {$_ -replace ("ALGO=", "")}
                        $CPUTEMP = $GetCPUSummary -split ";" | Select-String "TEMP=" | foreach {$_ -replace ("TEMP=", "")}
                        $CPUFAN = $GetCPUSummary -split ";" | Select-String "FAN=" | foreach {$_ -replace ("FAN=", "")}
                    }
                    else {Write-Host "API Threads Failed- Could Not Get Individual GPU Information" -Foreground Red}
                }

                'xmrstak' {
                    $HS = "hs"
                    $Message = $Null; $Message = "/api.json"
                    $Request = $Null; $Request = Get-HTTP -Port $Port -Message $Message
                    if ($Request) {
                        try {$Data = $Null; $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop; }catch {Write-Host "Failed To gather summary" -ForegroundColor Red}
                        $HashRate_Total = [Double]$Data.hashrate.total[0]
                        if (-not $HashRate_Total) {$HashRate_Total = [Double]$Data.hashrate.total[1]} #fix
                        if (-not $HashRate_Total) {$HashRate_Total = [Double]$Data.hashrate.total[2]} #fix
                        $global:BRAW = $HashRate_Total
                        Write-Host "Note: XMR-STAK/XMRig API is not great. You can't match threads to specific GPU." -ForegroundColor Yellow
                        Write-MinerData2
                        try {$Hash = for ($i = 0; $i -lt $Data.hashrate.threads.count; $i++) {$Data.Hashrate.threads[$i] | Select -First 1}}catch {}
                        try {for ($i = 0; $i -lt $Devices.Count; $i++) {$GPU = $Devices[$i]; $global:GPUHashrates.$(Get-Gpus) = ($Hash[$GPU] | Select -First 1) / 1000}}catch {Write-Host "Failed To parse threads" -ForegroundColor Red};
                        $MinerACC += $Data.results.shares_good
                        $MinerREJ += [Double]$Data.results.shares_total - [Double]$Data.results.shares_good
                        $global:BACC += $Data.results.shares_good
                        $global:BREJ += [Double]$Data.results.shares_total - [Double]$Data.results.shares_good
                        $global:BUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
                        $global:BALGO += "$MinerAlgo"
                        try {$global:BKHS += [Double]$HashRate_Total / 1000}catch {}
                    }
                    else {Set-APIFailure; break}
                }

                'xmrstak-opt' {
                    Write-Host "Miner $MinerType is xmrstak api"
                    Write-Host "Miner Devices is $Devices"
                    Write-Host "Note: XMR-STAK API sucks. You can't match threads to GPU." -ForegroundColor Yellow
                    $CPUHS = "hs"
                    $Message = "/api.json"
                    $Request = $Null
                    $Request = Get-HTTP -Port $Port -Message $Message
                    if ($Request) {
                        try {$Data = $Null; $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop; }catch {Write-Host "Failed To parse API" -ForegroundColor Red}
                        $Hash = $Data.Hashrate.Threads
                        try {$Data.hashrate.total -split "," | % {if ($_ -ne "") {$CPURAW = $_; $global:BCPUKHS = $_; $CPUSUM = $_; break}}}catch {}
                        $CPURAW | Set-Content ".\build\txt\$MinerType-hash.txt"
                        for ($i = 0; $i -lt $Devices.Count; $i++) {$GPU = $Devices[$i]; $global:CPUHashrates.$($GCount.$TypeS.$GPU) = $(if ($Hash.Count -eq 1) {[Double]$($Hash[0] | Select -first 1) / 1000}else {[Double]$($Hash[$i] | Select -First 1) / 1000})}
                        $MinerACC = 0
                        $MinerREJ = 0
                        $MinerACC += $Data.results.shares_good
                        $MinerREJ += [Double]$Data.results.shares_total - [Double]$Data.results.shares_good
                        $global:BCPUACC += $Data.results.shares_good
                        $global:BCPUREJ += [Double]$Data.results.shares_total - [Double]$Data.results.shares_good
                        $CPUUPTIME = $Data.connection.uptime
                        $CPUALGO = $MinerAlgo
                    }
                    else {Write-Host "$MinerAPI API Failed- Could Not Get Stats" -Foreground Red; $CPURAW = 0; $CPURAW | Set-Content ".\build\txt\$MinerType-hash.txt"}
                }

                'wildrig' {
                    $HS = "khs"
                    $Message = $Null; $Message = '/api.json'
                    $Request = $Null; $Request = Get-HTTP -Port $Port -Message $Message
                    if ($Request) {
                        try {$Data = $Null; $Data = $Request.Content | ConvertFrom-Json -ErrorAction Stop; }catch {Write-Host "Failed To parse API" -ForegroundColor Red}
                        try {$global:BRAW = $Data.hashrate.total[0]}catch {}
                        Write-MinerData2;
                        $Hash = $Data.hashrate.threads
                        try {for ($i = 0; $i -lt $Devices.Count; $i++) {$GPU = $Devices[$i]; $global:GPUHashrates.$(Get-Gpus) = [Double]($Hash[$GPU] | Select -First 1) / 1000}}catch {Write-Host "Failed To parse GPU Array" -ForegroundColor Red}
                        $MinerACC += $Data.results.shares_good
                        $MinerREJ += [Double]$Data.results.shares_total - [Double]$Data.results.shares_good 
                        $global:BACC += $Data.results.shares_good
                        $global:BREJ += [Double]$Data.results.shares_total - [Double]$Data.results.shares_good
                        $global:BUPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)
                        $global:BALGO += "$MinerAlgo"
                        try {$global:BKHS += [Double]$Data.hashrate.total[0] / 1000}catch {}
                    }
                    else {Set-APIFailure; break}
                }
            }

            ##Check To See if High Rejections
            if ($BackgroundTimer.Elapsed.TotalSeconds -gt 60) {
                $Shares = [Double]$MinerACC + [double]$MinerREJ
                $RJPercent = $MinerREJ / $Shares * 100
                if ($RJPercent -gt $REJPercent -and $Shares -gt 0) {
                    Write-Host "Warning: Miner is reaching Rejection Limit- $($RJPercent.ToString("N2")) Percent Out of $Shares Shares" -foreground yellow
                    if (-not (Test-Path ".\timeout")) {New-Item "timeout" -ItemType Directory | Out-Null}
                    if (-not (Test-Path ".\timeout\warnings")) {New-Item ".\timeout\warnings" -ItemType Directory | Out-Null}
                    "Bad Shares" | Out-File ".\timeout\warnings\$($_.Name)_$($_.Algo)_rejection.txt"
                }
                else {if (Test-Path ".\timeout\warnings\$($_.Name)_$($_.Algo)_rejection.txt") {Remove-Item ".\timeout\warnings\$($_.Name)_$($_.Algo)_rejection.txt" -Force}}
            }
 
        }
    }

    if ($CPUOnly -eq $true) {
        $global:BCPUKHS = [Math]::Round($global:BCPUKHS, 4)
        $HIVE = "
$($CPUHash -join "`n")
KHS=$global:BCPUKHS
ACC=$global:BCPUACC
REJ=$global:BCPUREJ
ALGO=$CPUALGO
TEMP=$CPUTEMP
FAN=$CPUFAN
UPTIME=$CPUUPTIME
HSU=$CPUHS
"
        $Hive | Set-Content ".\build\txt\hivestats.txt"

        if ($GetMiners -and $GETSWARM.HasExited -eq $false) {
            Write-Host " "
            Write-Host "$global:BHashRates" -ForegroundColor Green -NoNewline
            Write-Host " KHS=$global:BCPUKHS" -ForegroundColor Yellow -NoNewline
            Write-Host " ACC=$global:BCPUACC" -ForegroundColor DarkGreen -NoNewline
            Write-Host " REJ=$global:BCPUREJ" -ForegroundColor DarkRed -NoNewline
            Write-Host " ALGO=$CPUALGO" -ForegroundColor Gray -NoNewline
            Write-Host " FAN=$CPUFAN" -ForegroundColor Cyan -NoNewline
            Write-Host " UPTIME=$CPUUPTIME
" -ForegroundColor White
        }
    }
    else {
        if ($DEVNVIDIA -eq $True) {if ($GCount.NVIDIA.PSObject.Properties.Value.Count -gt 0) {for ($i = 0; $i -lt $GCount.NVIDIA.PSObject.Properties.Value.Count; $i++) {$global:BHashRates += 0; $global:BFans += 0; $global:BTemps += 0}}}
        if ($DevAMD -eq $True) {if ($GCount.AMD.PSObject.Properties.Value.Count -gt 0) {for ($i = 0; $i -lt $GCount.AMD.PSObject.Properties.Value.Count; $i++) {$global:BHashRates += 0; $global:BFans += 0; $global:BTemps += 0}}}
        if ($DEVNVIDIA -eq $True) {for ($i = 0; $i -lt $GCount.NVIDIA.PSOBject.Properties.Value.Count; $i++) {$global:BHashRates[$($GCount.NVIDIA.$i)] = "GPU={0:f4}" -f $($global:GPUHashrates.$($GCount.NVIDIA.$i))}}
        if ($DevAMD -eq $True) {for ($i = 0; $i -lt $GCount.AMD.PSObject.Properties.Value.Count; $i++) {$global:BHashRates[$($GCount.AMD.$i)] = "GPU={0:f4}" -f $($global:GPUHashrates.$($GCount.AMD.$i))}}
        if ($DEVNVIDIA -eq $True) {for ($i = 0; $i -lt $GCount.NVIDIA.PSObject.Properties.Value.Count; $i++) {$global:BFans[$($GCount.NVIDIA.$i)] = "FAN=$($global:GPUsFans.$($GCount.NVIDIA.$i))"}}
        if ($DevAMD -eq $True) {for ($i = 0; $i -lt $GCount.AMD.PSObject.Properties.Value.Count; $i++) {$global:BFans[$($GCount.AMD.$i)] = "FAN=$($global:GPUsFans.$($GCount.AMD.$i))"}}
        if ($DEVNVIDIA -eq $True) {for ($i = 0; $i -lt $GCount.NVIDIA.PSObject.Properties.Value.Count; $i++) {$global:BTemps[$($GCount.NVIDIA.$i)] = "TEMP=$($global:GPUsTemps.$($GCount.NVIDIA.$i))"}}
        if ($DevAMD -eq $True) {for ($i = 0; $i -lt $GCount.AMD.PSObject.Properties.Value.Count; $i++) {$global:BTemps[$($GCount.AMD.$i)] = "TEMP=$($global:GPUsTemps.$($GCount.AMD.$i))"}}
        if ($Platforms -eq "windows" -and $HiveOS -eq "Yes") {
            if ($DEVNVIDIA -eq $True) {if ($GCount.NVIDIA.PSObject.Properties.Value.Count -gt 0) {for ($i = 0; $i -lt $GCount.NVIDIA.PSObject.Properties.Value.Count; $i++) {$global:BPower += 0}}}
            if ($DevAMD -eq $True) {if ($GCount.AMD.PSObject.Properties.Value.Count -gt 0) {for ($i = 0; $i -lt $GCount.AMD.PSObject.Properties.Value.Count; $i++) {$global:BPower += 0}}}
            if ($DEVNVIDIA -eq $True) {for ($i = 0; $i -lt $GCount.NVIDIA.PSObject.Properties.Value.Count; $i++) {$global:BPower[$($GCount.NVIDIA.$i)] = "POWER=$($global:GPUsPower.$($GCount.NVIDIA.$i))"}}
            if ($DevAMD -eq $True) {for ($i = 0; $i -lt $GCount.AMD.PSObject.Properties.Value.Count; $i++) {$global:BPower[$($GCount.AMD.$i)] = "POWER=$($global:GPUsPower.$($GCount.AMD.$i))"}}
        }  
        for ($i = 0; $i -lt $global:BHashRates.count; $i++) {
            if ($global:BHashRates[$i] -eq 'GPU=0' -or $global:BHashRates[$i] -eq 'GPU=' -or $global:BHashRates[$i] -eq 'GPU=0.0000') {
                $global:BHashRates[$i] = 'GPU=0.000'; $global:BKHS += 0.000
            }
        }

        $global:BALGO = $global:BALGO | Select -First 1
        $global:BHiveAlgo = $global:BHiveAlgo | Select -First 1
        $global:BKHS = [Math]::Round($global:BKHS, 4)

        $HIVE = "
$($global:BHashRates -join "`n")
KHS=$global:BKHS
ACC=$global:BACC
REJ=$global:BREJ
ALGO=$global:BALGO
HIVEALGO=$global:BHiveAlgo
$($global:BFans -join "`n")
$($global:BTemps -join "`n")
UPTIME=$global:BUPTIME
HSU=khs
"

        if ($GetMiners -and $GETSWARM.HasExited -eq $false) {
            Write-Host " "
            Write-Host "$global:BHashRates" -ForegroundColor Green -NoNewline
            Write-Host " KHS=$global:BKHS" -ForegroundColor Yellow -NoNewline
            Write-Host " ACC=$global:BACC" -ForegroundColor DarkGreen -NoNewline
            Write-Host " REJ=$global:BREJ" -ForegroundColor DarkRed -NoNewline
            Write-Host " ALGO=$global:BALGO" -ForegroundColor Gray -NoNewline
            Write-Host " $global:BFans" -ForegroundColor Cyan -NoNewline
            Write-Host " $global:BTemps" -ForegroundColor Magenta -NoNewline
            if ($Platforms -eq "windows") {Write-Host " $global:BPower"  -ForegroundColor DarkCyan -NoNewline}
            Write-Host " UPTIME=$global:BUPTIME
" -ForegroundColor White
        }

        if ($global:BCPUKHS -ne $null) {$global:BCPUKHS = [Math]::Round($global:BCPUKHS, 4); Write-Host "CPU=$global:BCPUKHS"}
        $Hive | Set-Content ".\build\txt\hivestats.txt"
    }

    if ($Platforms -eq "windows" -and $HiveOS -eq "Yes") {
        $Stats = Build-HiveResponse
        try {$response = Invoke-RestMethod "$HiveMirror/worker/api" -TimeoutSec 15 -Method POST -Body ($Stats | ConvertTo-Json -Depth 4 -Compress) -ContentType 'application/json'}
        catch {Write-Warning "Failed To Contact HiveOS.Farm"; $response = $null}
        $response | ConvertTo-Json | Set-Content ".\build\txt\response.txt"
        if ($response) {
            if ($response.result.command -eq "batch") {
                $batch = $response.result.commands
                for ($b = 0; $b -lt $batch.count; $b++) {
                    $do_command = $batch[$b]
                    $do_command = $do_command -replace "@{", ""
                    $do_command = $do_command -replace "}", ""
                    $do_command = $do_command -split ";"
                    $do_command = $do_command -replace "amd_oc=", ""
                    $do_command = $do_command -replace "nvidia_oc=", ""
                    $parsed_batch = $do_command
                    $new_command = $do_command | ConvertFrom-StringData
                    $batch_command = [PSCustomObject]@{"result" = @{command = $new_command.Command; id = $new_command.id; $new_command.command = $parsed_batch}}
                    $SwarmResponse = Start-webcommand -command $batch_command -HiveID $HiveId -HivePassword $HivePassword -HiveMirror $HiveMirror
                }
            }
            else {$SwarmResponse = Start-webcommand -command $response -HiveID $HiveId -HivePassword $HivePassword -HiveMirror $HiveMirror}
            if ($SwarmResponse -ne $null) {
                if ($SwarmResponse -eq "config") {
                    Write-Warning "Config Command Initiated- Restarting SWARM"
                    $MinerFile = ".\build\pid\miner_pid.txt"
                    if (Test-Path $MinerFile) {$MinerId = Get-Process -Id (Get-Content $MinerFile) -ErrorAction SilentlyContinue}
                    if ($MinerId) {
                        Stop-Process $MinerId
                        Start-Sleep -S 3
                    }
                    Start-Process ".\SWARM.bat"
                    Start-Sleep -S 3
                    Exit
                }
                if ($SwarmResponse -eq "stats") {
                    Write-Host "Hive Received Stats"
                }
                if ($SwarmResponse -eq "exec") {
                    Write-Host "Sent Command To Hive"
                }
                if ($SwarmResponse -eq "update") {
                    Write-Host "Update Completed- Exiting"
                    Exit
                }
            }
        }
    }

    if ($BackgroundTimer.Elapsed.TotalSeconds -gt 120) {Clear-Content ".\build\txt\hivestats.txt"; $BackgroundTimer.Restart()}

    ##Watchdog
   # if ($config.Wd_Enabled -ne $null) {
    #    if ($config.Wd_Enabled -ne 0) {
     #       if ($global:BKHS -eq 0) {
      #          if ($wd_miner_timer.isRunning) {
       #             $wd_miner_seconds = [Double]$config.wd_miner * 60
        #            $wd_reboot_seconds = [Double]$config.wd_reboot * 60                
         #           if ($wd_miner_timer.Elapsed.TotalSeconds -gt $wd_miner_seconds) {
          #
        #         }
        #            if ($wd_miner_timer.Elapsed.TotalSeconds -gt $wd_miner_seconds) {
        #       
        #            }
        #        }
        #    } 
       # }
   # }

    if ($RestartTimer.Elapsed.TotalSeconds -le 10) {
        $GoToSleep = [math]::Round(10 - $RestartTimer.Elapsed.TotalSeconds)
        if ($GoToSleep -gt 0) {Start-Sleep -S $GoToSleep}
    }

}
