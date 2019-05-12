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

Param (
    [Parameter(mandatory = $false)]
    [string]$WorkingDir
)

$global:Dir = $WorkingDir
Set-Location $WorkingDir

## Get Parameters
$Global:config = [hashtable]::Synchronized(@{ })
$Global:stats = [hashtable]::Synchronized(@{ })
$Global:stats.Add("summary", @{ })
$Global:stats.Add("params", @{ })
$Global:stats.Add("stats", @{ })
$global:Config.Add("params", @{ })
$global:Config.Add("Hive_Params", @{ })
if (Test-Path ".\config\parameters\newarguments.json") {
    $arguments = Get-Content ".\config\parameters\newarguments.json" | ConvertFrom-Json
    $arguments.PSObject.Properties.Name | % { $global:Config.Params.Add("$($_)", $arguments.$_) }
    $arguments = $null
}
else {
    $arguments = Get-Content ".\config\parameters\arguments.json" | ConvertFrom-Json
    $arguments.PSObject.Properties.Name | % { $global:Config.Params.Add("$($_)", $arguments.$_) }
    $arguments = $null
}
if (Test-Path ".\build\txt\hivekeys.txt") {
    $HiveStuff = Get-Content ".\build\txt\hivekeys.txt" | ConvertFrom-Json
    $HiveStuff.PSObject.Properties.Name | % { $global:Config.Hive_Params.Add("$($_)", $HiveStuff.$_) }
    $HiveStuff = $null
}
if (-not $global:Config.Hive_Params.HiveID) {
    Write-Host "No HiveID- HiveOS Disabled"
    $global:Config.Hive_Params.Add("HiveID", $Null)
    $global:Config.Hive_Params.Add("HivePassword", $Null)
    $global:Config.Hive_Params.Add("HiveWorker", $Null)
    $global:Config.Hive_Params.Add("HiveMirror", "https://api.hiveos.farm")
    $global:Config.Hive_Params.Add("FarmID", $Null)
    $global:Config.Hive_Params.Add("Wd_Enabled", $null)
    $Global:config.Hive_Params.Add("Wd_miner", $Null)
    $Global:config.Hive_Params.Add("Wd_reboot", $Null)
    $Global:config.Hive_Params.Add("Wd_minhashes", $Null)
    $Global:config.Hive_Params.Add("Miner", $Null)
    $global:Config.Hive_Params.Add("Miner2", $Null)
    $global:Config.Hive_Params.Add("Timezone", $Null)
}
if (-not $global:Config.Params.Platform) {
    write-Host "Detecting Platform..." -Foreground Cyan
    if (Test-Path "C:\") { $global:Config.Params.Platform = "windows" }
    else { $global:Config.Params.Platform = "linux" }
    Write-Host "OS = $($global:Config.Params.Platform)" -ForegroundColor Green
}


[cultureinfo]::CurrentCulture = 'en-US'
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

Write-Host "Platform is $($global:Config.Params.Platform)"; Write-Host "HiveOS ID is $($global:Config.hive_params.HiveID)"; Write-Host "HiveOS = $($global:Config.params.HiveOS)"

##Icon for windows
if ($global:Config.Params.Platform -eq "windows") {
    Start-Process "powershell" -ArgumentList "-command .\build\powershell\icon.ps1 `".\build\apps\comb.ico`"" -NoNewWindow
    $Host.UI.RawUI.BackgroundColor = ($bckgrnd = 'Black'); $Host.UI.RawUI.ForegroundColor = 'White';
    $Host.PrivateData.ErrorForegroundColor = 'Red'; $Host.PrivateData.ErrorBackgroundColor = $bckgrnd;
    $Host.PrivateData.WarningForegroundColor = 'Magenta'; $Host.PrivateData.WarningBackgroundColor = $bckgrnd;
    $Host.PrivateData.DebugForegroundColor = 'Yellow'; $Host.PrivateData.DebugBackgroundColor = $bckgrnd;
    $Host.PrivateData.VerboseForegroundColor = 'Green'; $Host.PrivateData.VerboseBackgroundColor = $bckgrnd;
    $Host.PrivateData.ProgressForegroundColor = 'Cyan'; $Host.PrivateData.ProgressBackgroundColor = $bckgrnd;
    Clear-Host  
}

## Codebase for Further Functions
## Codebase for Further Functions
. .\build\api\html\api.ps1; . .\build\api\html\include.ps1; . .\build\api\miners\bminer.ps1;
. .\build\api\miners\ccminer.ps1; . .\build\api\miners\cpuminer.ps1; . .\build\api\miners\cpuminer.ps1;
. .\build\api\miners\dstm.ps1; . .\build\api\miners\energiminer.ps1; . .\build\api\miners\ethminer.ps1;
. .\build\api\miners\ewbf.ps1; . .\build\api\miners\excavator.ps1; . .\build\api\miners\gminer.ps1;
. .\build\api\miners\grin-miner.ps1; . .\build\api\miners\include.ps1; . .\build\api\miners\lolminer.ps1;
. .\build\api\miners\miniz.ps1; . .\build\api\miners\sgminer.ps1; . .\build\api\miners\trex.ps1;
. .\build\api\miners\wildrig.ps1; . .\build\api\miners\xmrig-opt.ps1; . .\build\api\miners\xmrstak.ps1;
. .\build\powershell\hashrates.ps1; . .\build\api\hiveos\do-command.ps1; . .\build\api\hiveos\response.ps1;
. .\build\api\hiveos\hiveoc.ps1; . .\build\powershell\command-stats.ps1; . .\build\api\miners\srbminer.ps1;
. .\build\api\miners\cgminer.ps1; . .\build\api\miners\nbminer.ps1; . .\build\api\miners\multiminer.ps1;
. .\build\api\tcp\agent-server.ps1; . .\build\api\hiveos\stats.ps1;  . .\build\api\tcp\hive-server.ps1;

##Start API Server
$Hive_Path = "/hive/bin"
Write-Host "API Port is $($global:Config.Params.Port)";      
$Posh_api = Get-APIServer;  
$Posh_Api.BeginInvoke() | Out-Null
$Posh_SwarmTCP = Get-SWARMServer;
$Posh_SwarmTCP.BeginInvoke() | Out-Null
if(test-path $Hive_Path) {
$Posh_HiveTCP= Get-HiveServer;
$Posh_HiveTCP.BeginInvoke() | Out-Null
}
if ($global:Config.Params.API -eq "Yes") { Write-Host "API Server Started- you can run http://localhost:$($global:Config.Params.Port)/end to close" -ForegroundColor Green }

## SWARM miner PID
$CheckForSWARM = ".\build\pid\miner_pid.txt"
if (Test-Path $CheckForSWARM) { $GetSWARMID = Get-Content $CheckForSWARM; $GETSWARM = Get-Process -ID $GetSWARMID -ErrorAction SilentlyContinue }

##Get Active Miners And Devices
$GCount = Get-Content ".\build\txt\devicelist.txt" | ConvertFrom-Json

##Timers
$BackgroundTimer = New-Object -TypeName System.Diagnostics.Stopwatch
$BackgroundTimer.Restart()
$RestartTimer = New-Object -TypeName System.Diagnostics.Stopwatch

##Get hive naming conventions:
$GetHiveNames = ".\config\pools\pool-algos.json"
$HiveNames = if (Test-Path $GetHiveNames) { Get-Content $GetHiveNames | ConvertFrom-Json }

While ($True) {

    ## Timer For When To Restart Loop
    $RestartTimer.Restart()

    ##Bool for Current Miners
    $Switched = $false

    ##Determine if Miner Switched
    $CheckForMiners = ".\build\txt\bestminers.txt"
    if (Test-Path $CheckForMiners) { $GetMiners = Get-Content $CheckForMiners | ConvertFrom-Json -ErrorAction Stop }
    else { Write-Host "No Miners Running..." }
    if ($GETSWARM.HasExited -eq $true) { Write-Host "SWARM Has Exited..."; }

    ##Handle New Miners
    if ($GetMiners -and $GETSWARM.HasExited -eq $false) {
        $GetMiners | ForEach-Object { if (-not ($CurrentMiners | Where-Object Path -eq $_.Path | Where-Object Arguments -eq $_.Arguments )) { $Switched = $true } }
        if ($Switched -eq $True) {
            Write-Host "Miners Have Switched
" -ForegroundColor Cyan
            $CurrentMiners = $GetMiners;
            ##Set Starting Date & Device Flags
            $StartTime = Get-Date
            ## Determine Which GPU's to stat
        }
    }
    else {
        $StartTime = Get-Date
    }

    ## Determine if CPU in only used. Set Flags for what to do.
    $global:Config.Params.CPUOnly = $true; $DoCPU = $false; $DoAMD = $false; $DoNVIDIA = $false; $DoASIC = $false
    $CurrentMiners | ForEach-Object {
        if ($_.Type -like "*NVIDIA*" -or $_.Type -like "*AMD*" -or $_.Type -like "*ASIC*") {
            $global:Config.Params.CPUOnly = $false; "GPU" | Set-Content ".\build\txt\miner.txt"
        }
        if ($_.Type -like "*NVIDIA*") {
            $DoNVIDIA = $true
        }
        if ($_.Type -like "*AMD*") {
            $DoAMD = $true
        }
        if ($_.Type -eq "CPU") {
            $DoCPU = $true
        }
        if ($_.Type -like "*ASIC*") {
            $DoASIC = $true
        }
    }
    
    ## Build All Initial Global Value
    $global:AllKHS = 0; $global:AllACC = 0; $global:ALLREJ = 0; $global:SWARM_ALGO = @{ }; $global:HIVE_ALGO = @{ };
    $Group1 = $null; $Default_Group = $null; $Hive = $null; $global:UPTIME = 0;

    if ($DoAMD -or $DoNVIDIA) {
        $global:GPUHashrates = [PSCustomObject]@{ }; $global:GPUHashTable = @();             
        $global:GPUFans = [PSCustomObject]@{ }; $global:GPUTemps = [PSCustomObject]@{ }; 
        $global:GPUPower = [PSCustomObject]@{ }; $global:GPUFanTable = @();              
        $global:GPUTempTable = @(); $global:GPUPowerTable = @();                
        $global:GPUKHS = 0;
    }
    
    if ($DoCPU) {
        $global:CPUHashrates = [PSCustomObject]@{ }; $global:CPUHashTable = @(); 
        $global:CPUKHS = 0;
    }

    if ($DoASIC) {
        $global:ASICHashrates = [PSCustomObject]@{ }; $global:ASICHashTable = @(); 
        $global:ASICKHS = 0;
    }

    ##Start Adding Zeros
    if ($DoAMD -or $DoNVIDIA) {
        if ($DoAMD) {
            for ($i = 0; $i -lt $GCount.AMD.PSObject.Properties.Value.Count; $i++) {
                $global:GPUHashrates | Add-Member -MemberType NoteProperty -Name "$($GCount.AMD.$i)" -Value 0; 
                $global:GPUFans | Add-Member -MemberType NoteProperty -Name "$($GCount.AMD.$i)" -Value 0; 
                $global:GPUTemps | Add-Member -MemberType NoteProperty -Name "$($GCount.AMD.$i)" -Value 0; 
                $global:GPUPower | Add-Member -MemberType NoteProperty -Name "$($GCount.AMD.$i)" -Value 0
            }
        }
        if ($DoNVIDIA) {
            for ($i = 0; $i -lt $GCount.NVIDIA.PSObject.Properties.Value.Count; $i++) {
                $global:GPUHashrates | Add-Member -MemberType NoteProperty -Name "$($GCount.NVIDIA.$i)" -Value 0; 
                $global:GPUFans | Add-Member -MemberType NoteProperty -Name "$($GCount.NVIDIA.$i)" -Value 0; 
                $global:GPUTemps | Add-Member -MemberType NoteProperty -Name "$($GCount.NVIDIA.$i)" -Value 0; 
                $global:GPUPower | Add-Member -MemberType NoteProperty -Name "$($GCount.NVIDIA.$i)" -Value 0    
            }
        }
    }
    
    if ($DOCPU) {
        for ($i = 0; $i -lt $GCount.CPU.PSObject.Properties.Value.Count; $i++) {
            $global:CPUHashrates | Add-Member -MemberType NoteProperty -Name "$($GCount.CPU.$i)" -Value 0; 
        }
    }
    if ($DoASIC) { 
        $ASICS = $CurrentMiners.Type | Where { $_ -like "*ASIC*" }
        for ($i = 0; $i -lt $ASICS.Count; $i++) {
            $global:ASICHashRates | Add-Member -MemberType NoteProperty -Name "0" -Value 0; 
        }
    }

    ## Windows-To-Hive Stats
    if ($global:Config.Params.Platform -eq "windows") {

        ## Rig Metrics
        if ($global:Config.Params.HiveOS -eq "Yes") {
            $diskSpace = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" | Select-Object Freespace
            $diskSpace = $diskSpace.Freespace / [math]::pow( 1024, 3 )
            $diskSpace = [math]::Round($diskSpace)
            $diskSpace = "$($diskSpace)G"
            $ramtotal = Get-Content ".\build\txt\ram.txt" | Select-Object -First 1
            $cpu = $(Get-CimInstance Win32_PerfFormattedData_PerfOS_System).ProcessorQueueLength
            $LoadAverage = Set-Stat -Name "load-average" -Value $cpu
            $LoadAverages = @("$([Math]::Round($LoadAverage.Minute,2))", "$([Math]::Round($LoadAverage.Minute_5,2))", "$([Math]::Round($LoadAverage.Minute_15,2))")
            $ramfree = [math]::Round((Get-Ciminstance Win32_OperatingSystem | Select FreePhysicalMemory).FreePhysicalMemory / 1kb, 2)
        }
    }

    ##NVIDIA GPU Stats
    if ($DoNVIDIA -eq $true) { $NVIDIAStats = Set-NvidiaStats }

    ##AMD GPU Stats
    if ($DoAMD -eq $true) { $AMDStats = Set-AMDStats }

    ## Start API Calls For Each Miner
    if ($CurrentMiners -and $GETSWARM.HasExited -eq $false) {

        $global:MinerTable = @{ }

        $CurrentMiners | ForEach-Object {

            ## Static Miner Information
            $MinerAlgo = "$($_.Algo)"; $MinerName = "$($_.MinerName)"; $Name = "$($_.Name)";
            $Port = $($_.Port); $global:MinerType = "$($_.Type)"; $MinerAPI = "$($_.API)";
            $Server = "$($_.Server)"; $HashPath = ".\logs\$($_.Type).log"; $global:TypeS = "none"
            $global:Devices = 0; $MinerDevices = $_.Devices

            ##Algorithm Parsing For Stats
            if ($MinerType -ne "ASIC") { $HiveAlgo = $HiveNames.$MinerAlgo.hiveos_name }
            else { $HiveAlgo = $MinerAlgo }

            ## Determine API Type
            if ($MinerType -like "*NVIDIA*") { $global:TypeS = "NVIDIA" }
            elseif ($MinerType -like "*AMD*") { $global:TypeS = "AMD" }
            elseif ($MinerType -like "*CPU*") { $global:TypeS = "CPU" }
            elseif ($MinerType -like "*ASIC*") { $global:TypeS = "ASIC" }

            ##Build Algo Table
            switch ($MinerType) {
                "NVIDIA1" { $global:HIVE_ALGO.Add("Main", $HiveAlgo); $global:SWARM_ALGO.Add("Main", $MinerAlgo) }
                "AMD1" { $global:HIVE_ALGO.Add("Main", $HiveAlgo); $global:SWARM_ALGO.Add("Main", $MinerAlgo) }
                default { $global:HIVE_ALGO.Add($MinerType, $HiveAlgo); $global:SWARM_ALGO.Add($MinerType, $MinerAlgo) }
            }         
            
            ## Determine Devices
            Switch ($global:TypeS) {
                "NVIDIA" {
                    if ($MinerDevices -eq "none") { $global:Devices = Get-DeviceString -TypeCount $GCount.NVIDIA.PSObject.Properties.Value.Count }
                    else { $global:Devices = Get-DeviceString -TypeDevices $MinerDevices }
                }
                "AMD" {
                    if ($MinerDevices -eq "none") { $global:Devices = Get-DeviceString -TypeCount $GCount.AMD.PSObject.Properties.Value.Count }
                    else { $global:Devices = Get-DeviceString -TypeDevices $MinerDevices }
                }
                "ASIC" { $global:Devices = $null }
                "CPU" { $global:Devices = Get-DeviceString -TypeCount $GCount.CPU.PSObject.Properties.Value.Count }
            }

            ## Get Power Stats
            if ($global:TypeS -eq "NVIDIA") { $StatPower = $NVIDIAStats.Watts }
            if ($global:TypeS -eq "AMD") { $StatPower = $AMDStats.Watts }
            if ($global:TypeS -eq "NVIDIA" -or $global:TypeS -eq "AMD") {
                if ($StatPower -ne "" -or $StatPower -ne $null) {
                    for ($i = 0; $i -lt $Devices.Count; $i++) {
                        $global:GPUPower.$(Get-GPUS) = Set-Array $StatPower $Devices[$i]
                    }
                }
            }


            ## Now Fans & Temps
            Switch ($global:TypeS) {
                "NVIDIA" {
                    switch ($global:Config.Params.Platform) {
                        "Windows" {
                            for ($i = 0; $i -lt $Devices.Count; $i++) {
                                try { $global:GPUFans.$(Get-GPUS) = Set-Array $NVIDIAStats.Fans $Devices[$i] }
                                catch { Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break }
                            }
                            for ($i = 0; $i -lt $Devices.Count; $i++) {
                                try { $global:GPUTemps.$(Get-GPUS) = Set-Array $NVIDIAStats.Temps $Devices[$i] }
                                catch { Write-Host "Failed To Parse GPU Temp Array" -foregroundcolor red; break }
                            }
                        }
                        "linux" {
                            switch ($global:Config.Params.HiveOS) {
                                "Yes" {
                                    for ($i = 0; $i -lt $Devices.Count; $i++) {
                                        try { $global:GPUFans.$(Get-GPUS) = Set-Array $NVIDIAStats.Fans (Get-GPUs) }
                                        catch { Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break }
                                    }
                                    for ($i = 0; $i -lt $Devices.Count; $i++) {
                                        try { $global:GPUTemps.$(Get-GPUS) = Set-Array $NVIDIAStats.Temps (Get-GPUs) }
                                        catch { Write-Host "Failed To Parse GPU Temp Array" -foregroundcolor red; break }
                                    }            
                                }
                                "No" {
                                    for ($i = 0; $i -lt $Devices.Count; $i++) {
                                        try { $global:GPUFans.$(Get-GPUS) = Set-Array $NVIDIAStats.Fans $Devices[$i] }
                                        catch { Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break }
                                    }
                                    for ($i = 0; $i -lt $Devices.Count; $i++) {
                                        try { $global:GPUTemps.$(Get-GPUS) = Set-Array $NVIDIAStats.Temps $Devices[$i] }
                                        catch { Write-Host "Failed To Parse GPU Temp Array" -foregroundcolor red; break }
                                    }                    
                                }
                            }
                        }
                    }
                }
                "AMD" {
                    Switch ($global:Config.Params.Platform) {
                        "windows" {
                            for ($i = 0; $i -lt $Devices.Count; $i++) {
                                try { $global:GPUFans.$(Get-GPUS) = Set-Array $AMDStats.Fans $Devices[$i] }
                                catch { Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break }
                            }
                            for ($i = 0; $i -lt $Devices.Count; $i++) {
                                try { $global:GPUTemps.$(Get-GPUS) = Set-Array $AMDStats.Temps $Devices[$i] }
                                catch { Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break }
                            }
                        }
                        "linux" {
                            switch ($global:Config.Params.HiveOS) {
                                "Yes" {
                                    for ($i = 0; $i -lt $Devices.Count; $i++) {
                                        try { $global:GPUFans.$(Get-GPUS) = Set-Array $AMDStats.Fans (Get-GPUs) }
                                        catch { Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break }
                                    }
                                    for ($i = 0; $i -lt $Devices.Count; $i++) {
                                        try { $global:GPUTemps.$(Get-GPUS) = Set-Array $AMDStats.Temps (Get-GPUs) }
                                        catch { Write-Host "Failed To Parse GPU Temp Array" -foregroundcolor red; break }
                                    }
                                }
                                "No" {
                                    for ($i = 0; $i -lt $Devices.Count; $i++) {
                                        try { $global:GPUFans.$(Get-GPUS) = Set-Array $AMDStats.Fans $Devices[$i] }
                                        catch { Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break }
                                    }
                                    for ($i = 0; $i -lt $Devices.Count; $i++) {
                                        try { $global:GPUTemps.$(Get-GPUS) = Set-Array $AMDStats.Temps $Devices[$i] }
                                        catch { Write-Host "Failed To Parse GPU Temp Array" -foregroundcolor red; break }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            ## Set Global Miner-Specific Variables.
            $global:RAW = 0; $global:MinerREJ = 0;
            $global:MinerACC = 0;

            ##Write Miner Information
            Write-MinerData1

            ## Start Calling Miner API
            switch ($MinerAPI) {
                'energiminer' { try { Get-StatsEnergiminer }catch { Get-OhNo } }
                'claymore' { try { Get-StatsEthminer }catch { Get-OhNo } }
                'excavator' { try { Get-StatsExcavator }catch { Get-OhNo } }
                'miniz' { try { Get-StatsMiniz }catch { Get-OhNo } }
                'gminer' { try { Get-StatsGminer }catch { Get-OhNo } }
                'grin-miner' { try { Get-StatsGrinMiner }catch { Get-OhNo } }
                'ewbf' { try { Get-StatsEWBF }catch { Get-OhNo } }
                'ccminer' { try { Get-StatsCcminer }catch { Get-OhNo } }
                'bminer' { try { Get-StatsBminer }catch { Get-OhNo } }
                'trex' { try { Get-StatsTrex }catch { Get-OhNo } }
                'dstm' { try { Get-StatsDSTM }catch { Get-OhNo } }
                'lolminer' { try { Get-StatsLolminer }catch { Get-OhNo } }
                'sgminer-gm' { try { Get-StatsSgminer }catch { Get-OhNo } }
                'cpuminer' { Get-StatsCpuminer }
                'xmrstak' { try { Get-StatsXmrstak }catch { Get-OhNo } }
                'xmrig-opt' { try { Get-Statsxmrigopt }catch { Get-OhNo } }
                'wildrig' { try { Get-StatsWildRig }catch { Get-OhNo } }
                'cgminer' { try { Get-StatsCgminer }catch { Get-OhNo } }
                'nebutech' { try { Get-StatsNebutech }catch { Get-OhNo } }
                'srbminer' { try { Get-StatsSrbminer }catch { Get-OhNo } }
                'multiminer' { try { Get-StatsMultiminer }catch { Get-OhNo } }
            }

            ##Check To See if High Rejections
            if ($BackgroundTimer.Elapsed.TotalSeconds -gt 60) {
                $Shares = [Double]$global:MinerACC + [double]$global:MinerREJ
                $RJPercent = $global:MinerREJ / $Shares * 100
                if ($RJPercent -gt $global:Config.Params.Rejections -and $Shares -gt 0) {
                    Write-Host "Warning: Miner is reaching Rejection Limit- $($RJPercent.ToString("N2")) Percent Out of $Shares Shares" -foreground yellow
                    if (-not (Test-Path ".\timeout")) { New-Item "timeout" -ItemType Directory | Out-Null }
                    if (-not (Test-Path ".\timeout\warnings")) { New-Item ".\timeout\warnings" -ItemType Directory | Out-Null }
                    "Bad Shares" | Out-File ".\timeout\warnings\$($_.Name)_$($_.Algo)_rejection.txt"
                }
                else { if (Test-Path ".\timeout\warnings\$($_.Name)_$($_.Algo)_rejection.txt") { Remove-Item ".\timeout\warnings\$($_.Name)_$($_.Algo)_rejection.txt" -Force } }
            }
        }
    }


    ##Select Algo For Online Stats
    if ($global:HIVE_ALGO.Main) { $StatAlgo = $global:HIVE_ALGO.Main }
    else { $FirstMiner = $global:HIVE_ALGO.keys | Select-Object -First 1; if ($FirstMiner) { $StatAlgo = $global:HIVE_ALGO.$FirstMiner } }

    if ($global:SWARM_ALGO.Main) { $SwarmAlgo = $global:SWARM_ALGO.Main }
    else { $FirstMiner = $global:SWARM_ALGO.keys | Select-Object -First 1; if ($FirstMiner) { $SwarmAlgo = $global:SWARM_ALGO.$FirstMiner } }
    if ($StatAlgo) {
        Write-Host "
HiveOS Name For Algo is $StatAlgo" -ForegroundColor Magenta
    }

    ##Now To Format All Stats For Online Table And Screen
    if ($DoNVIDIA) {
        for ($i = 0; $i -lt $GCount.NVIDIA.PSObject.Properties.Value.Count; $i++) {
            $global:GPUHashTable += 0; $global:GPUFanTable += 0; $global:GPUTempTable += 0; $global:GPUPowerTable += 0;
        }
    }
    if ($DoAMD) {
        for ($i = 0; $i -lt $GCount.AMD.PSObject.Properties.Value.Count; $i++) {
            $global:GPUHashTable += 0; $global:GPUFanTable += 0; $global:GPUTempTable += 0; $global:GPUPowerTable += 0;
        }
    }
    if ($DoCPU) {
        for ($i = 0; $i -lt $GCount.CPU.PSObject.Properties.Value.Count; $i++) {
            $global:CPUHashTable += 0;
        }
    }
    if ($DoASIC) {
        $global:ASICHashTable += 0;
    }

    if ($DoNVIDIA) {
        for ($i = 0; $i -lt $GCount.NVIDIA.PSObject.Properties.Value.Count; $i++) {
            $global:GPUHashTable[$($GCount.NVIDIA.$i)] = "{0:f4}" -f $($global:GPUHashrates.$($GCount.NVIDIA.$i))
            $global:GPUFanTable[$($GCount.NVIDIA.$i)] = "$($global:GPUFans.$($GCount.NVIDIA.$i))"
            $global:GPUTempTable[$($GCount.NVIDIA.$i)] = "$($global:GPUTemps.$($GCount.NVIDIA.$i))"
            $global:GPUPowerTable[$($GCount.NVIDIA.$i)] = "$($global:GPUPower.$($GCount.NVIDIA.$i))"
        }
    }
    if ($DoAMD) {
        for ($i = 0; $i -lt $GCount.AMD.PSObject.Properties.Value.Count; $i++) {
            $global:GPUHashTable[$($GCount.AMD.$i)] = "{0:f4}" -f $($global:GPUHashrates.$($GCount.AMD.$i))
            $global:GPUFanTable[$($GCount.AMD.$i)] = "$($global:GPUFans.$($GCount.AMD.$i))"
            $global:GPUTempTable[$($GCount.AMD.$i)] = "$($global:GPUTemps.$($GCount.AMD.$i))"
            $global:GPUPowerTable[$($GCount.AMD.$i)] = "$($global:GPUPower.$($GCount.AMD.$i))"
        }
    }

    if ($DoCPU) {
        for ($i = 0; $i -lt $GCount.CPU.PSObject.Properties.Value.Count; $i++) {
            $global:CPUHashTable[$($GCount.CPU.$i)] = "{0:f4}" -f $($global:CPUHashrates.$($GCount.CPU.$i))
        }
    }

    if ($DoASIC) { $global:ASICHashTable[0] = "{0:f4}" -f $($global:ASICHashrates."0") }

    if ($DoAMD -or $DoNVIDIA) { $global:GPUKHS = [Math]::Round($global:GPUKHS, 4) }
    if ($DoCPU) { $global:CPUKHS = [Math]::Round($global:CPUKHS, 4) }
    if ($DoASIC) { $global:ASICKHS = [Math]::Round($global:ASICKHS, 4) }
    $global:UPTIME = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)


    $global:Stats.summary = @{
        summary = $global:MinerTable;
    }
    $global:Stats.stats = @{
        gpus       = $global:GPUHashTable;
        cpus       = $global:CPUHashTable;
        asics      = $global:ASICHashTable;
        cpu_total  = $global:CPUKHS;
        asic_total = $global:ASICKHS;
        gpu_total  = $global:GPUKHS;
        algo       = $StatAlgo;
        uptime     = $global:UPTIME;
        hsu        = "khs";
        fans       = $global:GPUFanTable;
        temps      = $global:GPUTempTable;
        power      = $global:GPUPowerTable;
        accepted   = $global:AllACC;
        rejected   = $global:AllREJ;
    }
    $global:Stats.params = @{
        params = $global:config.params
    }

    if ($GetMiners -and $GETSWARM.HasExited -eq $false) {
        Write-Host " "
        if ($DoAMD -or $DoNVIDIA) { Write-Host "GPU_Hashrates: $global:GPUHashTable" -ForegroundColor Green }
        if ($DoCPU) { Write-Host "CPU_Hashrates: $global:CPUHashTable" -ForegroundColor Green }
        if ($DoASIC) { Write-Host "ASIC_Hashrates: $global:ASICHashTable" -ForegroundColor Green }
        if ($DoAMD -or $DoNVIDIA) { Write-Host "GPU_Fans: $global:GPUFanTable" -ForegroundColor Yellow }
        if ($DoAMD -or $DoNVIDIA) { Write-Host "GPU_Temps: $global:GPUTempTable" -ForegroundColor Cyan }
        if ($DoAMD -or $DoNVIDIA) { Write-Host "GPU_Power: $global:GPUPowerTable"  -ForegroundColor Magenta }
        if ($DoAMD -or $DoNVIDIA) { Write-Host "GPU_TOTAL_KHS: $global:GPUKHS" -ForegroundColor Yellow }
        if ($DoCPU) { Write-Host "CPU_TOTAL_KHS: $global:CPUKHS" -ForegroundColor Yellow }
        if ($DoASIC) { Write-Host "ASIC_TOTAL_KHS: $global:ASICKHS" -ForegroundColor Yellow }
        Write-Host "ACC: $global:ALLACC" -ForegroundColor DarkGreen -NoNewline
        Write-Host " REJ: $global:ALLREJ" -ForegroundColor DarkRed -NoNewline
        Write-Host " ALGO: $SwarmAlgo" -ForegroundColor Gray -NoNewline
        Write-Host " UPTIME: $global:UPTIME
" -ForegroundColor White
    }
    
    Send-HiveStats 

    if ($RestartTimer.Elapsed.TotalSeconds -le 10) {
        $GoToSleep = [math]::Round(10 - $RestartTimer.Elapsed.TotalSeconds)
        if ($GoToSleep -gt 0) { Start-Sleep -S $GoToSleep }
    }
}
