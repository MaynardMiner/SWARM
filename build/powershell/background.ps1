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

$WorkingDir = "C:\Users\Mayna\Documents\GitHub\SWARM"
$global:Dir = $WorkingDir
Set-Location $WorkingDir
try { if ((Get-MpPreference).ExclusionPath -notcontains (Convert-Path .)) { Start-Process "powershell" -Verb runAs -ArgumentList "Add-MpPreference -ExclusionPath `'$WorkingDir`'" -WindowStyle Minimized } }catch { }
try{ $Net = Get-NetFireWallRule } catch {}
if($Net) {
try { if( -not ( $Net | Where {$_.DisplayName -like "*background.ps1*"} ) ) { New-NetFirewallRule -DisplayName 'background.ps1' -Direction Inbound -Program "$workingdir\build\powershell\background.ps1" -Action Allow | Out-Null} } catch { }
}
$Net = $null

if(Test-Path "C:\"){ Start-Process "powershell" -ArgumentList "$global:dir\build\powershell\icon.ps1 `'$global:dir\build\apps\comb.ico`'" -NoNewWindow }

$global:global = "$Global:Dir\build\powershell\global";
$global:background = "$Global:Dir\build\powershell\background";
$global:miners = "$Global:Dir\build\api\miners";
$global:tcp = "$Global:Dir\build\api\tcp";
$global:html = "$Global:Dir\build\api\html";
$global:web = "$Global:Dir\build\api\web";

$p = [Environment]::GetEnvironmentVariable("PSModulePath")
if ($P -notlike "*$Global:Dir\build\powershell*") {
    $P += ";$global:global";
    $P += ";$global:background";
    $P += ";$global:miners";
    $P += ";$global:tcp";
    $P += ";$global:html";
    $P += ";$global:web";
    [Environment]::SetEnvironmentVariable("PSModulePath", $p)
    Write-Host "Modules Are Loaded" -ForegroundColor Green
}

Import-Module -Name "$global:background\startup.psm1"
## Get Parameters
$Global:config = [hashtable]::Synchronized(@{ })
$Global:stats = [hashtable]::Synchronized(@{ })
Get-Params
[cultureinfo]::CurrentCulture = 'en-US'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12,[Net.SecurityProtocolType]::Tls11,[Net.SecurityProtocolType]::tls
Set-Window

$global:NetModules = @()
$global:WebSites = @()
if ($Config.Params.Farm_Hash -ne "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx") { $global:NetModules += ".\build\api\hiveos"; $global:WebSites += "HiveOS" }
if ($Config.Params.Swarm_Hash -eq "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx") { $global:NetModules += ".\build\api\SWARM"; $global:WebSites += "SWARM" }

Write-Host "Platform is $($global:Config.Params.Platform)"; 
Write-Host "HiveOS ID is $($global:Config.hive_params.HiveID)"; 
Write-Host "HiveOS = $($global:Config.params.HiveOS)"

Start-Servers

##Starting Variables.
$global:GPUHashrates = $null       
$global:GPUFans = $null
$global:GPUTemps = $null
$global:GPUPower = $null
$global:GPUFanTable = $null
$global:GPUTempTable = $null
$global:GPUPowerTable = $null                
$global:GPUKHS = $null
$global:CPUHashrates = $null
$global:CPUHashTable = $null
$global:CPUKHS = $null
$global:ASICHashrates = $null
$global:ASICKHS = $null
$global:ramfree = $null
$global:diskSpace = $null
$global:ramtotal = $null
$Global:cpu = $null
$Global:LoadAverages = $null
$Global:StartTime = $Null
$CheckForSWARM = ".\build\pid\miner_pid.txt"
if (Test-Path $CheckForSWARM) { $global:GETSWARMID = Get-Content $CheckForSWARM; $Global:GETSWARM = Get-Process -ID $global:GETSWARMID -ErrorAction SilentlyContinue }
$Global:GCount = Get-Content ".\build\txt\devicelist.txt" | ConvertFrom-Json
$global:BackgroundTimer = New-Object -TypeName System.Diagnostics.Stopwatch
$global:BackgroundTimer.Restart()
$global:RestartTimer = New-Object -TypeName System.Diagnostics.Stopwatch

Remove-Module -Name "startup"

While ($True) {

    $global:CPUOnly = $True ; $global:DoCPU = $false; $global:DoAMD = $false; 
    $global:DoNVIDIA = $false; $global:DoASIC = $false; $global:AllKHS = 0; 
    $global:AllACC = 0; $global:ALLREJ = 0; $global:SWARM_ALGO = @{ }; 
    $global:HIVE_ALGO = @{ }; $Group1 = $null; $Default_Group = $null; 
    $Hive = $null; $global:UPTIME = 0;

    Import-Module -Name "$global:background\run.psm1"
    Import-Module -Name "$global:background\initial.psm1"
    Import-Module -Name "$global:global\gpu.psm1"
    Import-Module -Name "$global:global\stats.psm1"
    Import-Module -Name "$global:global\hashrates.psm1"
    Invoke-MinerCheck
    New-StatTables
    Get-Metrics
    Remove-Module "initial"
    if ($global:DoNVIDIA -eq $true) { $NVIDIAStats = Set-NvidiaStats }
    if ($global:DoAMD -eq $true) { $AMDStats = Set-AMDStats }

    ## Start API Calls For Each Miner
    if ($global:CurrentMiners -and $Global:GETSWARM.HasExited -eq $false) {

        $global:MinerTable = @{ }

        $global:CurrentMiners | ForEach-Object {

            ## Static Miner Information
            $global:MinerAlgo = "$($_.Algo)"; $MinerName = "$($_.MinerName)"; $global:Name = "$($_.Name)";
            $global:Port = $($_.Port); $global:MinerType = "$($_.Type)"; $global:MinerAPI = "$($_.API)";
            $global:Server = "$($_.Server)"; $HashPath = ".\logs\$($_.Type).log"; $global:TypeS = "none"
            $global:Devices = 0; $MinerDevices = $_.Devices

            ##Algorithm Parsing For Stats
            $HiveAlgo = $global:MinerAlgo -replace "`_"," "
            $HiveAlgo = $HiveAlgo -replace "veil","x16rt"
            $NewName = $global:MinerAlgo -replace "`/","`-"
            $NewName = $global:MinerAlgo -replace "`_","`-"

            ## Determine API Type
            if ($global:MinerType -like "*NVIDIA*") { $global:TypeS = "NVIDIA" }
            elseif ($global:MinerType -like "*AMD*") { $global:TypeS = "AMD" }
            elseif ($global:MinerType -like "*CPU*") { $global:TypeS = "CPU" }
            elseif ($global:MinerType -like "*ASIC*") { $global:TypeS = "ASIC" }

            ##Build Algo Table
            switch ($global:MinerType) {
                "NVIDIA1" { $global:HIVE_ALGO.Add("Main", $HiveAlgo); $global:SWARM_ALGO.Add("Main", $global:MinerAlgo) }
                "AMD1" { $global:HIVE_ALGO.Add("Main", $HiveAlgo); $global:SWARM_ALGO.Add("Main", $global:MinerAlgo) }
                default { $global:HIVE_ALGO.Add($global:MinerType, $HiveAlgo); $global:SWARM_ALGO.Add($global:MinerType, $global:MinerAlgo) }
            }         
            
            ## Determine Devices
            Switch ($global:TypeS) {
                "NVIDIA" {
                    if ($MinerDevices -eq "none") { $global:Devices = Get-DeviceString -TypeCount $Global:GCount.NVIDIA.PSObject.Properties.Value.Count }
                    else { $global:Devices = Get-DeviceString -TypeDevices $MinerDevices }
                }
                "AMD" {
                    if ($MinerDevices -eq "none") { $global:Devices = Get-DeviceString -TypeCount $Global:GCount.AMD.PSObject.Properties.Value.Count }
                    else { $global:Devices = Get-DeviceString -TypeDevices $MinerDevices }
                }
                "ASIC" { $global:Devices = $null }
                "CPU" { $global:Devices = Get-DeviceString -TypeCount $Global:GCount.CPU.PSObject.Properties.Value.Count }
            }

            ## Get Power Stats
            if ($global:TypeS -eq "NVIDIA") { $StatPower = $NVIDIAStats.Watts }
            if ($global:TypeS -eq "AMD") { $StatPower = $AMDStats.Watts }
            if ($global:TypeS -eq "NVIDIA" -or $global:TypeS -eq "AMD") {
                if ($StatPower -ne "" -or $StatPower -ne $null) {
                    for ($global:i = 0; $global:i -lt $global:Devices.Count; $global:i++) {
                        $global:GPUPower.$(Get-GPUS) = Set-Array $StatPower $global:Devices[$global:i]
                    }
                }
            }


            ## Now Fans & Temps
            Switch ($global:TypeS) {
                "NVIDIA" {
                    switch ($global:Config.Params.Platform) {
                        "Windows" {
                            for ($global:i = 0; $global:i -lt $global:Devices.Count; $global:i++) {
                                try { $global:GPUFans.$(Get-GPUS) = Set-Array $NVIDIAStats.Fans $global:Devices[$global:i] }
                                catch { Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break }
                            }
                            for ($global:i = 0; $global:i -lt $global:Devices.Count; $global:i++) {
                                try { $global:GPUTemps.$(Get-GPUS) = Set-Array $NVIDIAStats.Temps $global:Devices[$global:i] }
                                catch { Write-Host "Failed To Parse GPU Temp Array" -foregroundcolor red; break }
                            }
                        }
                        "linux" {
                            switch ($global:Config.Params.HiveOS) {
                                "Yes" {
                                    for ($global:i = 0; $global:i -lt $global:Devices.Count; $global:i++) {
                                        try { $global:GPUFans.$(Get-GPUS) = Set-Array $NVIDIAStats.Fans (Get-GPUs) }
                                        catch { Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break }
                                    }
                                    for ($global:i = 0; $global:i -lt $global:Devices.Count; $global:i++) {
                                        try { $global:GPUTemps.$(Get-GPUS) = Set-Array $NVIDIAStats.Temps (Get-GPUs) }
                                        catch { Write-Host "Failed To Parse GPU Temp Array" -foregroundcolor red; break }
                                    }            
                                }
                                "No" {
                                    for ($global:i = 0; $global:i -lt $global:Devices.Count; $global:i++) {
                                        try { $global:GPUFans.$(Get-GPUS) = Set-Array $NVIDIAStats.Fans $global:Devices[$global:i] }
                                        catch { Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break }
                                    }
                                    for ($global:i = 0; $global:i -lt $global:Devices.Count; $global:i++) {
                                        try { $global:GPUTemps.$(Get-GPUS) = Set-Array $NVIDIAStats.Temps $global:Devices[$global:i] }
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
                            for ($global:i = 0; $global:i -lt $global:Devices.Count; $global:i++) {
                                try { $global:GPUFans.$(Get-GPUS) = Set-Array $AMDStats.Fans $global:Devices[$global:i] }
                                catch { Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break }
                            }
                            for ($global:i = 0; $global:i -lt $global:Devices.Count; $global:i++) {
                                try { $global:GPUTemps.$(Get-GPUS) = Set-Array $AMDStats.Temps $global:Devices[$global:i] }
                                catch { Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break }
                            }
                        }
                        "linux" {
                            switch ($global:Config.Params.HiveOS) {
                                "Yes" {
                                    for ($global:i = 0; $global:i -lt $global:Devices.Count; $global:i++) {
                                        try { $global:GPUFans.$(Get-GPUS) = Set-Array $AMDStats.Fans (Get-GPUs) }
                                        catch { Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break }
                                    }
                                    for ($global:i = 0; $global:i -lt $global:Devices.Count; $global:i++) {
                                        try { $global:GPUTemps.$(Get-GPUS) = Set-Array $AMDStats.Temps (Get-GPUs) }
                                        catch { Write-Host "Failed To Parse GPU Temp Array" -foregroundcolor red; break }
                                    }
                                }
                                "No" {
                                    for ($global:i = 0; $global:i -lt $global:Devices.Count; $global:i++) {
                                        try { $global:GPUFans.$(Get-GPUS) = Set-Array $AMDStats.Fans $global:Devices[$global:i] }
                                        catch { Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break }
                                    }
                                    for ($global:i = 0; $global:i -lt $global:Devices.Count; $global:i++) {
                                        try { $global:GPUTemps.$(Get-GPUS) = Set-Array $AMDStats.Temps $global:Devices[$global:i] }
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
            switch ($global:MinerAPI) {
                'energiminer' { 
                    try { 
                        Import-Module -Name "$global:miners\energiminer.psm1"; 
                        Get-StatsEnergiminer;
                        Remove-Module -name "energiminer"
                    } catch { Get-OhNo } 
                }
                'claymore' { 
                    try { 
                        Import-Module -Name "$global:miners\ethminer.psm1"; 
                        Get-StatsEthminer;
                        Remove-Module -name "ethminer"
                    } catch { Get-OhNo } 
                }
                'excavator' {
                    try { 
                        Import-Module -Name "$global:miners\excavator.psm1"; 
                        Get-StatsExcavator;
                        Remove-Module -name "excavator"
                    } catch { Get-OhNo } 
                }
                'miniz' { 
                    try { 
                        Import-Module -Name "$global:miners\miniz.psm1"; 
                        Get-Statsminiz;
                        Remove-Module -name "miniz"
                    } catch { Get-OhNo } 
                }
                'gminer' { 
                    try { 
                        Import-Module -Name "$global:miners\gminer.psm1"; 
                        Get-StatsGminer;
                        Remove-Module -name "gminer"
                    } catch { Get-OhNo } 
                }
                'grin-miner' { 
                    try { 
                        Import-Module -Name "$global:miners\grinminer.psm1"; 
                        Get-StartGrinMiner;
                        Remove-Module -name "grinminer"
                    } catch { Get-OhNo } 
                }
                'ewbf' { 
                    try { 
                        Import-Module -Name "$global:miners\ewbf.psm1"; 
                        Get-Statsewbf;
                        Remove-Module -name "ewbf"
                    } catch { Get-OhNo } 
                }
                'ccminer' { 
                    try { 
                        Import-Module -Name "$global:miners\ccminer.psm1"; 
                        Get-StatsCcminer;
                        Remove-Module -name "ccminer"
                    } catch { Get-OhNo } 
                }
                'bminer' { 
                    try { 
                        Import-Module -Name "$global:miners\bminer.psm1"; 
                        Get-StatsBminer;
                        Remove-Module -name "bminer"
                    } catch { Get-OhNo } 
                }
                'trex' { 
                    try { 
                        Import-Module -Name "$global:miners\trex.psm1"; 
                        Get-StatsTrex;
                        Remove-Module -name "trex"
                    } catch { Get-OhNo } 
                }
                'dstm' { 
                    try { 
                        Import-Module -Name "$global:miners\dstm.psm1"; 
                        Get-Statsdstm;
                        Remove-Module -name "dstm"
                    } catch { Get-OhNo } 
                }
                'lolminer' { 
                    try { 
                        Import-Module -Name "$global:miners\lolminer.psm1"; 
                        Get-Statslolminer;
                        Remove-Module -name "lolminer"
                    } catch { Get-OhNo } 
                }
                'sgminer-gm' { 
                    try { 
                        Import-Module -Name "$global:miners\sgminer.psm1"; 
                        Get-StatsSgminer;
                        Remove-Module -name "sgminer"
                    } catch { Get-OhNo } 
                }
                'cpuminer' { 
                    try { 
                        Import-Module -Name "$global:miners\cpuminer.psm1"; 
                        Get-Statscpuminer;
                        Remove-Module -name "cpuminer"
                    } catch { Get-OhNo } 
                }
                'xmrstak' { 
                    try { 
                        Import-Module -Name "$global:miners\xmrstak.psm1"; 
                        Get-Statsxmrstak;
                        Remove-Module -name "xmrstak"
                    } catch { Get-OhNo } 
                }
                'xmrig-opt' { 
                    try { 
                        Import-Module -Name "$global:miners\xmrigopt.psm1"; 
                        Get-Statsxmrigopt;
                        Remove-Module -name "xmrigopt"
                    } catch { Get-OhNo } 
                }
                'wildrig' { 
                    try { 
                        Import-Module -Name "$global:miners\wildrig.psm1"; 
                        Get-Statswildrig
                        Remove-Module -name "wildrig"
                    } catch { Get-OhNo } 
                }
                'cgminer' { 
                    try { 
                        Import-Module -Name "$global:miners\cgminer.psm1"; 
                        Get-Statscgminer
                        Remove-Module -name "cgminer"
                    } catch { Get-OhNo } 
                }
                'nebutech' { 
                    #try { 
                        Import-Module -Name "$global:miners\nbminer.psm1"; 
                        Get-StatsNebutech
                        Remove-Module -name "nbminer"
                    #} catch { Get-OhNo } 
                }
                'srbminer' { 
                    try { 
                        Import-Module -Name "$global:miners\srbminer.psm1"; 
                        Get-Statssrbminer
                        Remove-Module -name "srbminer"
                    } catch { Get-OhNo } 
                }
                'multiminer' { 
                    try { 
                        Import-Module -Name "$global:miners\multiminer.psm1"; 
                        Get-Statsmultiminer
                        Remove-Module -name "multiminer"
                    } catch { Get-OhNo } 
                }
            }

            ##Check To See if High Rejections
            if ($BackgroundTimer.Elapsed.TotalSeconds -gt 60) {
                $Shares = [Double]$global:MinerACC + [double]$global:MinerREJ
                $RJPercent = $global:MinerREJ / $Shares * 100
                if ($RJPercent -gt $global:Config.Params.Rejections -and $Shares -gt 0) {
                    Write-Host "Warning: Miner is reaching Rejection Limit- $($RJPercent.ToString("N2")) Percent Out of $Shares Shares" -foreground yellow
                    if (-not (Test-Path ".\timeout")) { New-Item "timeout" -ItemType Directory | Out-Null }
                    if (-not (Test-Path ".\timeout\warnings")) { New-Item ".\timeout\warnings" -ItemType Directory | Out-Null }
                    "Bad Shares" | Out-File ".\timeout\warnings\$($_.Name)_$($NewName)_rejection.txt"
                }
                else { if (Test-Path ".\timeout\warnings\$($_.Name)_$($NewName)_rejection.txt") { Remove-Item ".\timeout\warnings\$($_.Name)_$($NewName)_rejection.txt" -Force } }
            }
        }
    }


    ##Select Algo For Online Stats
    if ($global:HIVE_ALGO.Main) { $Global:StatAlgo = $global:HIVE_ALGO.Main }
    else { $FirstMiner = $global:HIVE_ALGO.keys | Select-Object -First 1; if ($FirstMiner) { $Global:StatAlgo = $global:HIVE_ALGO.$FirstMiner } }

    if ($global:SWARM_ALGO.Main) { $SwarmAlgo = $global:SWARM_ALGO.Main }
    else { $FirstMiner = $global:SWARM_ALGO.keys | Select-Object -First 1; if ($FirstMiner) { $Global:StatAlgo = $global:SWARM_ALGO.$FirstMiner } }
    if ($Global:StatAlgo) {
        Write-Host "
HiveOS Name For Algo is $Global:StatAlgo" -ForegroundColor Magenta
    }

    ##Now To Format All Stats For Online Table And Screen
    if ($global:DoNVIDIA) {
        for ($global:i = 0; $global:i -lt $Global:GCount.NVIDIA.PSObject.Properties.Value.Count; $global:i++) {
            $global:GPUHashTable += 0; $global:GPUFanTable += 0; $global:GPUTempTable += 0; $global:GPUPowerTable += 0;
        }
    }
    if ($global:DoAMD) {
        for ($global:i = 0; $global:i -lt $Global:GCount.AMD.PSObject.Properties.Value.Count; $global:i++) {
            $global:GPUHashTable += 0; $global:GPUFanTable += 0; $global:GPUTempTable += 0; $global:GPUPowerTable += 0;
        }
    }
    if ($global:DoCPU) {
        for ($global:i = 0; $global:i -lt $Global:GCount.CPU.PSObject.Properties.Value.Count; $global:i++) {
            $global:CPUHashTable += 0;
        }
    }
    if ($global:DoASIC) {
        $global:ASICHashTable += 0;
    }

    if ($global:DoNVIDIA) {
        for ($global:i = 0; $global:i -lt $Global:GCount.NVIDIA.PSObject.Properties.Value.Count; $global:i++) {
            $global:GPUHashTable[$($Global:GCount.NVIDIA.$global:i)] = "{0:f4}" -f $($global:GPUHashrates.$($Global:GCount.NVIDIA.$global:i))
            $global:GPUFanTable[$($Global:GCount.NVIDIA.$global:i)] = "$($global:GPUFans.$($Global:GCount.NVIDIA.$global:i))"
            $global:GPUTempTable[$($Global:GCount.NVIDIA.$global:i)] = "$($global:GPUTemps.$($Global:GCount.NVIDIA.$global:i))"
            $global:GPUPowerTable[$($Global:GCount.NVIDIA.$global:i)] = "$($global:GPUPower.$($Global:GCount.NVIDIA.$global:i))"
        }
    }
    if ($global:DoAMD) {
        for ($global:i = 0; $global:i -lt $Global:GCount.AMD.PSObject.Properties.Value.Count; $global:i++) {
            $global:GPUHashTable[$($Global:GCount.AMD.$global:i)] = "{0:f4}" -f $($global:GPUHashrates.$($Global:GCount.AMD.$global:i))
            $global:GPUFanTable[$($Global:GCount.AMD.$global:i)] = "$($global:GPUFans.$($Global:GCount.AMD.$global:i))"
            $global:GPUTempTable[$($Global:GCount.AMD.$global:i)] = "$($global:GPUTemps.$($Global:GCount.AMD.$global:i))"
            $global:GPUPowerTable[$($Global:GCount.AMD.$global:i)] = "$($global:GPUPower.$($Global:GCount.AMD.$global:i))"
        }
    }

    if ($global:DoCPU) {
        for ($global:i = 0; $global:i -lt $Global:GCount.CPU.PSObject.Properties.Value.Count; $global:i++) {
            $global:CPUHashTable[$($Global:GCount.CPU.$global:i)] = "{0:f4}" -f $($global:CPUHashrates.$($Global:GCount.CPU.$global:i))
        }
    }

    if ($global:DoASIC) { $global:ASICHashTable[0] = "{0:f4}" -f $($global:ASICHashrates."0") }

    if ($global:DoAMD -or $global:DoNVIDIA) { $global:GPUKHS = [Math]::Round($global:GPUKHS, 4) }
    if ($global:DoCPU) { $global:CPUKHS = [Math]::Round($global:CPUKHS, 4) }
    if ($global:DoASIC) { $global:ASICKHS = [Math]::Round($global:ASICKHS, 4) }
    $global:UPTIME = [math]::Round(((Get-Date) - $Global:StartTime).TotalSeconds)


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
        algo       = $Global:StatAlgo;
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

    if ($global:GetMiners -and $global:GETSWARM.HasExited -eq $false) {
        Write-Host " "
        if ($global:DoAMD -or $global:DoNVIDIA) { Write-Host "GPU_Hashrates: $global:GPUHashTable" -ForegroundColor Green }
        if ($global:DoCPU) { Write-Host "CPU_Hashrates: $global:CPUHashTable" -ForegroundColor Green }
        if ($global:DoASIC) { Write-Host "ASIC_Hashrates: $global:ASICHashTable" -ForegroundColor Green }
        if ($global:DoAMD -or $global:DoNVIDIA) { Write-Host "GPU_Fans: $global:GPUFanTable" -ForegroundColor Yellow }
        if ($global:DoAMD -or $global:DoNVIDIA) { Write-Host "GPU_Temps: $global:GPUTempTable" -ForegroundColor Cyan }
        if ($global:DoAMD -or $global:DoNVIDIA) { Write-Host "GPU_Power: $global:GPUPowerTable"  -ForegroundColor Magenta }
        if ($global:DoAMD -or $global:DoNVIDIA) { Write-Host "GPU_TOTAL_KHS: $global:GPUKHS" -ForegroundColor Yellow }
        if ($global:DoCPU) { Write-Host "CPU_TOTAL_KHS: $global:CPUKHS" -ForegroundColor Yellow }
        if ($global:DoASIC) { Write-Host "ASIC_TOTAL_KHS: $global:ASICKHS" -ForegroundColor Yellow }
        Write-Host "ACC: $global:ALLACC" -ForegroundColor DarkGreen -NoNewline
        Write-Host " REJ: $global:ALLREJ" -ForegroundColor DarkRed -NoNewline
        Write-Host " ALGO: $SwarmAlgo" -ForegroundColor White -NoNewline
        Write-Host " UPTIME: $global:UPTIME
" -ForegroundColor Yellow
    }

    Remove-Module -Name "gpu"
    Remove-Module -Name "run"
    Remove-Module -Name "stats"
    Remove-Module -Name "hashrates"
    
    if ($global:Websites) {
        $GetNetMods = @($global:NetModules | Foreach { Get-ChildItem $_ })
        $GetNetMods | ForEach-Object { Import-Module $_.FullName }
        Import-Module -Name "$global:Web\methods.psm1"
        Send-HiveStats
        $GetNetMods | ForEach-Object {Remove-Module -Name "$($_.BaseName)"}
    }

    if ($RestartTimer.Elapsed.TotalSeconds -le 10) {
        $GoToSleep = [math]::Round(10 - $RestartTimer.Elapsed.TotalSeconds)
        if ($GoToSleep -gt 0) { Start-Sleep -S $GoToSleep }
    }

}
