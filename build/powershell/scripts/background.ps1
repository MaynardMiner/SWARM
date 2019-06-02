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

#$WorkingDir = "C:\Users\Mayna\Documents\GitHub\SWARM"
#$WorkingDir = "/root/hive/miners/custom/SWARM"
Set-Location $WorkingDir
. .\build\powershell\global\modules.ps1
$Global:config = [hashtable]::Synchronized(@{ })
$Global:stats = [hashtable]::Synchronized(@{ })
$global:config.Add("var", @{ })
$(v).Add("dir", $WorkingDir)

try { if ((Get-MpPreference).ExclusionPath -notcontains (Convert-Path .)) { Start-Process "powershell" -Verb runAs -ArgumentList "Add-MpPreference -ExclusionPath `'$WorkingDir`'" -WindowStyle Minimized } }catch { }
try { $Net = Get-NetFireWallRule } catch { }
if ($Net) {
    try { if ( -not ( $Net | Where { $_.DisplayName -like "*background.ps1*" } ) ) { New-NetFirewallRule -DisplayName 'background.ps1' -Direction Inbound -Program "$workingdir\build\powershell\scripts\background.ps1" -Action Allow | Out-Null } } catch { }
}
$Net = $null

if ($IsWindows) { Start-Process "powershell" -ArgumentList "Set-Location `'$($(v).dir)`'; .\build\powershell\scripts\icon.ps1 `'$($(v).dir)\build\apps\comb.ico`'" -NoNewWindow }

$(v).Add("global", "$($(v).dir)\build\powershell\global")
$(v).Add("background", "$($(v).dir)\build\powershell\background")
$(v).Add("miners", "$($(v).dir)\build\api\miners")
$(v).Add("tcp", "$($(v).dir)\build\api\tcp")
$(v).Add("html", "$($(v).dir)\build\api\html")
$(v).Add("web", "$($(v).dir)\build\api\web")

$p = [Environment]::GetEnvironmentVariable("PSModulePath")
if ($P -notlike "*$($(v).dir)\build\powershell*") {
    $P += ";$($(v).global)";
    $P += ";$($(v).background)";
    $P += ";$($(v).miners)";
    $P += ";$($(v).tcp)";
    $P += ";$($(v).html)";
    $P += ";$($(v).web)";
    [Environment]::SetEnvironmentVariable("PSModulePath", $p)
    Write-Host "Modules Are Loaded" -ForegroundColor Green
}

$(v).Add("Modules", @())
Import-Module "$($(v).global)\include.psm1" -Scope Global
Global:Add-Module "$($(v).background)\startup.psm1"

## Get Parameters
Global:Get-Params
[cultureinfo]::CurrentCulture = 'en-US'
$AllProtocols = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12' 
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
Global:Set-Window

$(v).Add("NetModules", @())
$(v).Add("WebSites", @())
if ($Config.Params.Farm_Hash -ne "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" -and -not (Test-Path "/hive/miners") ) { $global:NetModules += ".\build\api\hiveos"; $global:WebSites += "HiveOS" }
#if ($Config.Params.Swarm_Hash -ne "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx") { $global:NetModules += ".\build\api\SWARM"; $global:WebSites += "SWARM" }

Write-Host "Platform is $($global:Config.Params.Platform)"; 
Write-Host "HiveOS ID is $($global:Config.hive_params.HiveID)"; 
Write-Host "HiveOS = $($global:Config.params.HiveOS)"

Global:Start-Servers

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
$Global:StartTime = Get-Date
$CheckForSWARM = ".\build\pid\miner_pid.txt"
if (Test-Path $CheckForSWARM) { 
    $global:GETSWARMID = Get-Content $CheckForSWARM; 
    $Global:GETSWARM = Get-Process -ID $global:GETSWARMID -ErrorAction SilentlyContinue 
}
$Global:GCount = Get-Content ".\build\txt\devicelist.txt" | ConvertFrom-Json
$global:BackgroundTimer = New-Object -TypeName System.Diagnostics.Stopwatch
$global:BackgroundTimer.Restart()
$global:RestartTimer = New-Object -TypeName System.Diagnostics.Stopwatch

Remove-Module -Name "startup"

While ($True) {

    if ($global:Config.Params.Platform -eq "linux" -and -not $global:WebSites) {
        if ($global:GETSWARM.HasExited -eq $true) {
            Write-Host "Closing down SWARM" -ForegroundColor Yellow
            Global:start-killscript
        }
    }

    $global:CPUOnly = $True ; $global:DoCPU = $false; $global:DoAMD = $false; 
    $global:DoNVIDIA = $false; $global:DoASIC = $false; $global:AllKHS = 0; 
    $global:AllACC = 0; $global:ALLREJ = 0; $global:SWARM_ALGO = @{ }; 
    $global:HIVE_ALGO = @{ }; $Group1 = $null; $Default_Group = $null; 
    $Hive = $null; $global:UPTIME = 0;

    Global:Add-Module "$($(v).background)\run.psm1"
    Global:Add-Module "$($(v).background)\initial.psm1"
    Global:Add-Module "$($(v).global)\gpu.psm1"
    Global:Add-Module "$($(v).global)\stats.psm1"
    Global:Add-Module "$($(v).global)\hashrates.psm1"
    
    Global:Invoke-MinerCheck
    Global:New-StatTables
    Global:Get-Metrics
    Remove-Module "initial"
    if ($global:DoNVIDIA -eq $true) { $NVIDIAStats = Global:Set-NvidiaStats }
    if ($global:DoAMD -eq $true) { $AMDStats = Global:Set-AMDStats }

    ## Start API Calls For Each Miner
    if ($global:CurrentMiners -and $Global:GETSWARM.HasExited -eq $false) {

        $global:MinerTable = @{ }

        $global:CurrentMiners | ForEach-Object {

            ## Static Miner Information
            $global:MinerAlgo = "$($_.Algo)"; $global:MinerName = "$($_.MinerName)"; $global:Name = "$($_.Name)";
            $global:Port = $($_.Port); $global:MinerType = "$($_.Type)"; $global:MinerAPI = "$($_.API)";
            $global:Server = "$($_.Server)"; $HashPath = ".\logs\$($_.Type).log"; $global:TypeS = "none"
            $global:Devices = 0; $MinerDevices = $_.Devices

            ##Algorithm Parsing For Stats
            $HiveAlgo = $global:MinerAlgo -replace "`_", " "
            $HiveAlgo = $HiveAlgo -replace "veil", "x16rt"
            $NewName = $global:MinerAlgo -replace "`/", "`-"
            $NewName = $global:MinerAlgo -replace "`_", "`-"

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
                    if ($MinerDevices -eq "none") { $global:Devices = Global:Get-DeviceString -TypeCount $Global:GCount.NVIDIA.PSObject.Properties.Value.Count }
                    else { $global:Devices = Global:Get-DeviceString -TypeDevices $MinerDevices }
                }
                "AMD" {
                    if ($MinerDevices -eq "none") { $global:Devices = Global:Get-DeviceString -TypeCount $Global:GCount.AMD.PSObject.Properties.Value.Count }
                    else { $global:Devices = Global:Get-DeviceString -TypeDevices $MinerDevices }
                }
                "ASIC" { $global:Devices = $null }
                "CPU" { $global:Devices = Global:Get-DeviceString -TypeCount $Global:GCount.CPU.PSObject.Properties.Value.Count }
            }

            ## Get Power Stats
            if ($global:TypeS -eq "NVIDIA") { $StatPower = $NVIDIAStats.Watts }
            if ($global:TypeS -eq "AMD") { $StatPower = $AMDStats.Watts }
            if ($global:TypeS -eq "NVIDIA" -or $global:TypeS -eq "AMD") {
                if ($StatPower -ne "" -or $StatPower -ne $null) {
                    for ($global:i = 0; $global:i -lt $global:Devices.Count; $global:i++) {
                        $global:GPUPower.$(Global:Get-GPUs) = Global:Set-Array $StatPower $global:Devices[$global:i]
                    }
                }
            }


            ## Now Fans & Temps
            Switch ($global:TypeS) {
                "NVIDIA" {
                    switch ($global:Config.Params.Platform) {
                        "Windows" {
                            for ($global:i = 0; $global:i -lt $global:Devices.Count; $global:i++) {
                                try { $global:GPUFans.$(Global:Get-GPUs) = Global:Set-Array $NVIDIAStats.Fans $global:Devices[$global:i] }
                                catch { Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break }
                            }
                            for ($global:i = 0; $global:i -lt $global:Devices.Count; $global:i++) {
                                try { $global:GPUTemps.$(Global:Get-GPUs) = Global:Set-Array $NVIDIAStats.Temps $global:Devices[$global:i] }
                                catch { Write-Host "Failed To Parse GPU Temp Array" -foregroundcolor red; break }
                            }
                        }
                        "linux" {
                            switch ($global:Config.Params.HiveOS) {
                                "Yes" {
                                    for ($global:i = 0; $global:i -lt $global:Devices.Count; $global:i++) {
                                        try { $global:GPUFans.$(Global:Get-GPUs) = Global:Set-Array $NVIDIAStats.Fans (Global:Get-GPUs) }
                                        catch { Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break }
                                    }
                                    for ($global:i = 0; $global:i -lt $global:Devices.Count; $global:i++) {
                                        try { $global:GPUTemps.$(Global:Get-GPUs) = Global:Set-Array $NVIDIAStats.Temps (Global:Get-GPUs) }
                                        catch { Write-Host "Failed To Parse GPU Temp Array" -foregroundcolor red; break }
                                    }            
                                }
                                "No" {
                                    for ($global:i = 0; $global:i -lt $global:Devices.Count; $global:i++) {
                                        try { $global:GPUFans.$(Global:Get-GPUs) = Global:Set-Array $NVIDIAStats.Fans $global:Devices[$global:i] }
                                        catch { Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break }
                                    }
                                    for ($global:i = 0; $global:i -lt $global:Devices.Count; $global:i++) {
                                        try { $global:GPUTemps.$(Global:Get-GPUs) = Global:Set-Array $NVIDIAStats.Temps $global:Devices[$global:i] }
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
                                try { $global:GPUFans.$(Global:Get-GPUs) = Global:Set-Array $AMDStats.Fans $global:Devices[$global:i] }
                                catch { Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break }
                            }
                            for ($global:i = 0; $global:i -lt $global:Devices.Count; $global:i++) {
                                try { $global:GPUTemps.$(Global:Get-GPUs) = Global:Set-Array $AMDStats.Temps $global:Devices[$global:i] }
                                catch { Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break }
                            }
                        }
                        "linux" {
                            switch ($global:Config.Params.HiveOS) {
                                "Yes" {
                                    for ($global:i = 0; $global:i -lt $global:Devices.Count; $global:i++) {
                                        try { $global:GPUFans.$(Global:Get-GPUs) = Global:Set-Array $AMDStats.Fans (Global:Get-GPUs) }
                                        catch { Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break }
                                    }
                                    for ($global:i = 0; $global:i -lt $global:Devices.Count; $global:i++) {
                                        try { $global:GPUTemps.$(Global:Get-GPUs) = Global:Set-Array $AMDStats.Temps (Global:Get-GPUs) }
                                        catch { Write-Host "Failed To Parse GPU Temp Array" -foregroundcolor red; break }
                                    }
                                }
                                "No" {
                                    for ($global:i = 0; $global:i -lt $global:Devices.Count; $global:i++) {
                                        try { $global:GPUFans.$(Global:Get-GPUs) = Global:Set-Array $AMDStats.Fans $global:Devices[$global:i] }
                                        catch { Write-Host "Failed To Parse GPU Fan Array" -foregroundcolor red; break }
                                    }
                                    for ($global:i = 0; $global:i -lt $global:Devices.Count; $global:i++) {
                                        try { $global:GPUTemps.$(Global:Get-GPUs) = Global:Set-Array $AMDStats.Temps $global:Devices[$global:i] }
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
            Global:Write-MinerData1

            ## Start Calling Miner API
            switch ($global:MinerAPI) {
                'energiminer' { 
                    try { 
                        Global:Add-Module "$($(v).miners)\energiminer.psm1"; 
                        Global:Get-StatsEnergiminer;
                        Remove-Module -name "energiminer"
                    }
                    catch { Global:Get-OhNo } 
                }
                'claymore' { 
                    try { 
                        Global:Add-Module "$($(v).miners)\ethminer.psm1"; 
                        Global:Get-StatsEthminer;
                        Remove-Module -name "ethminer"
                    }
                    catch { Global:Get-OhNo } 
                }
                'excavator' {
                    try { 
                        Global:Add-Module "$($(v).miners)\excavator.psm1"; 
                        Global:Get-StatsExcavator;
                        Remove-Module -name "excavator"
                    }
                    catch { Global:Get-OhNo } 
                }
                'miniz' { 
                    try { 
                        Global:Add-Module "$($(v).miners)\miniz.psm1"; 
                        Global:Get-Statsminiz;
                        Remove-Module -name "miniz"
                    }
                    catch { Global:Get-OhNo } 
                }
                'gminer' { 
                    try { 
                        Global:Add-Module "$($(v).miners)\gminer.psm1"; 
                        Global:Get-StatsGminer;
                        Remove-Module -name "gminer"
                    }
                    catch { Global:Get-OhNo } 
                }
                'grin-miner' { 
                    try { 
                        Global:Add-Module "$($(v).miners)\grinminer.psm1"; 
                        Global:Get-StartGrinMiner;
                        Remove-Module -name "grinminer"
                    }
                    catch { Global:Get-OhNo } 
                }
                'ewbf' { 
                    try { 
                        Global:Add-Module "$($(v).miners)\ewbf.psm1"; 
                        Global:Get-Statsewbf;
                        Remove-Module -name "ewbf"
                    }
                    catch { Global:Get-OhNo } 
                }
                'ccminer' { 
                    try { 
                        Global:Add-Module "$($(v).miners)\ccminer.psm1"; 
                        Global:Get-StatsCcminer;
                        Remove-Module -name "ccminer"
                    }
                    catch { Global:Get-OhNo } 
                }
                'bminer' { 
                    try { 
                        Global:Add-Module "$($(v).miners)\bminer.psm1"; 
                        Global:Get-StatsBminer;
                        Remove-Module -name "bminer"
                    }
                    catch { Global:Get-OhNo } 
                }
                'trex' { 
                    try { 
                        Global:Add-Module "$($(v).miners)\trex.psm1"; 
                        Global:Get-StatsTrex;
                        Remove-Module -name "trex"
                    }
                    catch { Global:Get-OhNo } 
                }
                'dstm' { 
                    try { 
                        Global:Add-Module "$($(v).miners)\dstm.psm1"; 
                        Global:Get-Statsdstm;
                        Remove-Module -name "dstm"
                    }
                    catch { Global:Get-OhNo } 
                }
                'lolminer' { 
                    try { 
                        Global:Add-Module "$($(v).miners)\lolminer.psm1"; 
                        Global:Get-Statslolminer;
                        Remove-Module -name "lolminer"
                    }
                    catch { Global:Get-OhNo } 
                }
                'sgminer-gm' { 
                    try { 
                        Global:Add-Module "$($(v).miners)\sgminer.psm1"; 
                        Global:Get-StatsSgminer;
                        Remove-Module -name "sgminer"
                    }
                    catch { Global:Get-OhNo } 
                }
                'cpuminer' { 
                    try { 
                        Global:Add-Module "$($(v).miners)\cpuminer.psm1"; 
                        Global:Get-Statscpuminer;
                        Remove-Module -name "cpuminer"
                    }
                    catch { Global:Get-OhNo } 
                }
                'xmrstak' { 
                    try { 
                        Global:Add-Module "$($(v).miners)\xmrstak.psm1"; 
                        Global:Get-Statsxmrstak;
                        Remove-Module -name "xmrstak"
                    }
                    catch { Global:Get-OhNo } 
                }
                'xmrig-opt' { 
                    try { 
                        Global:Add-Module "$($(v).miners)\xmrigopt.psm1"; 
                        Global:Get-Statsxmrigopt;
                        Remove-Module -name "xmrigopt"
                    }
                    catch { Global:Get-OhNo } 
                }
                'wildrig' { 
                    try { 
                        Global:Add-Module "$($(v).miners)\wildrig.psm1"; 
                        Global:Get-Statswildrig
                        Remove-Module -name "wildrig"
                    }
                    catch { Global:Get-OhNo } 
                }
                'cgminer' { 
                    try { 
                        Global:Add-Module "$($(v).miners)\cgminer.psm1"; 
                        Global:Get-Statscgminer
                        Remove-Module -name "cgminer"
                    }
                    catch { Global:Get-OhNo } 
                }
                'nebutech' { 
                    try { 
                        Global:Add-Module "$($(v).miners)\nbminer.psm1"; 
                        Global:Get-StatsNebutech
                        Remove-Module -name "nbminer"
                    }
                    catch { Global:Get-OhNo } 
                }
                'srbminer' { 
                    try { 
                        Global:Add-Module "$($(v).miners)\srbminer.psm1"; 
                        Global:Get-Statssrbminer
                        Remove-Module -name "srbminer"
                    }
                    catch { Global:Get-OhNo } 
                }
                'multiminer' { 
                    try { 
                        Global:Add-Module "$($(v).miners)\multiminer.psm1"; 
                        Global:Get-Statsmultiminer
                        Remove-Module -name "multiminer"
                    }
                    catch { Global:Get-OhNo } 
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

    ##Select Only For Each Device Group
    $DeviceTable = @()
    if ([string]$global:Config.Params.GPUDevices1) { $DeviceTable += $global:Config.Params.GPUDevices1 }
    if ([string]$global:Config.Params.GPUDevices2) { $DeviceTable += $global:Config.Params.GPUDevices2 }
    if ([string]$global:Config.Params.GPUDevices3) { $DeviceTable += $global:Config.Params.GPUDevices3 }

    if ($DeviceTable) {
        $DeviceTable = $DeviceTable | Sort-Object
        $TempGPU = @()
        $TempFan = @()
        $TempTemp = @()
        $TempPower = @()
        for ($global:i = 0; $global:i -lt $DeviceTable.Count; $global:i++) {
            $G = $DeviceTable[$i]
            $TempGPU += $global:GPUHashTable[$G]
            $TempFan += $global:GPUFanTable[$G]
            $TempTemp += $global:GPUTempTable[$G]
            $TempPower += $global:GPUPowerTable[$G]
        }
        $global:GPUHashTable = $TempGPU
        $global:GPUFanTable = $TempFan
        $global:GPUTempTable = $TempTemp
        $global:GPUPowerTable = $TempPower
        Remove-Variable TempGPU
        Remove-Variable TempFan
        Remove-Variable TempTemp
        Remove-Variable TempPower
    }

    Remove-Variable DeviceTable

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

    ##Modify Stats to show something For Online
    if($global:DoNVIDIA -or $global:AMD){
        for($global:i=0; $global:i -lt $global:GPUHashTable.Count; $global:i++) { $global:GPUHashTable[$global:i] = $global:GPUHashTable[$global:i] -replace "0.0000","0.0001" }
        if($global:GPUKHS -eq 0){$global:GPUKHS = 0.0001}
    }

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
    $global:Stats.params = $global:config.Params

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
    
    if ($global:Websites) {
        Global:Add-Module "$($(v).web)\methods.psm1"
        Global:Add-Module "$($(v).background)\webstats.psm1"
        Global:Send-WebStats
    }

    if ($RestartTimer.Elapsed.TotalSeconds -le 5) {
        $GoToSleep = [math]::Round(5 - $RestartTimer.Elapsed.TotalSeconds)
        if ($GoToSleep -gt 0) { Start-Sleep -S $GoToSleep }
    }
    
    Get-Job -State Completed | Remove-Job
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    [GC]::Collect()    
}
