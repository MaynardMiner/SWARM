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

##############################################################################
#######                      Startup                                    ######
##############################################################################

## Set Current Path
$Global:config = [hashtable]::Synchronized(@{})
$Global:Config.Add("vars",@{})
$Global:Config.vars.Add( "dir",(Split-Path $script:MyInvocation.MyCommand.Path) )
$Global:Config.vars.dir = $Global:Config.vars.dir -replace "/var/tmp","/root"
Set-Location $Global:Config.vars.dir

##filepath dir
. .\build\powershell\global\modules.ps1
$env:Path += ";$($(vars).dir)\build\cmd"

try { Get-ChildItem $($(vars).dir) -Recurse | Unblock-File } catch { }

## Exclusion Windows Defender
try { 
    if ((Get-MpPreference).ExclusionPath -notcontains (Convert-Path .)) { 
        Start-Process "powershell" -Verb runAs -ArgumentList "Add-MpPreference -ExclusionPath `'$($(vars).dir)`'" -WindowStyle Minimized 
    } 
}
catch { }

## Set Firewall Rule
try { 
    $Net = Get-NetFireWallRule 
    if ($Net) {
        try { 
            if ( -not ( $Net | Where { $_.DisplayName -like "*swarm.ps1*" } ) ) { 
                New-NetFirewallRule -DisplayName 'swarm.ps1' -Direction Inbound -Program "$($(vars).dir)\swarm.ps1" -Action Allow | Out-Null
            } 
        }
        catch { }
    }
}
catch { }
$Net = $Null

if ($IsWindows) {
    Start-Process "powershell" -ArgumentList "Set-Location `'$($(vars).dir)`'; .\build\powershell\scripts\icon.ps1 `'$($(vars).dir)\build\apps\SWARM.ico`'" -NoNewWindow
}

## Debug Mode- Allow you to run with last known arguments or arguments.json.
$(vars).Add("debug",$false)
if ($global:config.vars.debug -eq $True) {
    Start-Transcript ".\logs\debug.log"
    if (($IsWindows)) { Set-ExecutionPolicy Bypass -Scope Process }
}

## Load Modules
$(vars).Add("startup","$($(vars).dir)\build\powershell\startup")
$(vars).Add("web","$($(vars).dir)\build\api\web")
$(vars).Add("global","$($(vars).dir)\build\powershell\global")
$(vars).Add("build","$($(vars).dir)\build\powershell\build")
$(vars).Add("pool","$($(vars).dir)\build\powershell\pool")
$(vars).Add("miner","$($(vars).dir)\build\powershell\miner")
$(vars).Add("control","$($(vars).dir)\build\powershell\control")
$(vars).Add("run","$($(vars).dir)\build\powershell\run")
$(vars).Add("benchmark","$($(vars).dir)\build\powershell\benchmark")

$p = [Environment]::GetEnvironmentVariable("PSModulePath")
if ($P -notlike "*$($(vars).dir)\build\powershell*") {
    $P += ";$($(vars).startup)";
    $P += ";$($(vars).web)";
    $P += ";$($(vars).global)";
    $P += ";$($(vars).build)";
    $P += ";$($(vars).pool)";
    $P += ";$($(vars).miner)";
    $P += ";$($(vars).control)";
    $P += ";$($(vars).run)";
    $P += ";$($(vars).benchmark)";
    [Environment]::SetEnvironmentVariable("PSModulePath", $p)
    Write-Host "Modules Are Loaded" -ForegroundColor Green
}

$(vars).Add("Modules",@())

## Date Bug
$global:cultureENUS = New-Object System.Globalization.CultureInfo("en-US")

## Startup Modules
Import-Module "$($(vars).global)\include.psm1" -Scope Global

##Insert Single Modules Here

## Get Parameters
Global:Add-Module "$($(vars).startup)\parameters.psm1"
Global:Get-Parameters
$(arg).TCP_Port | Out-File ".\build\txt\port.txt"

## Crash Reporting
Global:Add-Module "$($(vars).startup)\crashreport.psm1"
Global:Start-CrashReporting

## Start The Log
Global:Add-Module "$($(vars).startup)\startlog.psm1"
$($(vars).dir) | Set-Content ".\build\bash\dir.sh";
$(vars).Add("LogNum",1)
Global:Start-Log -Number $(vars).LogNum;

## Initiate Update Check
Global:Add-Module "$($(vars).startup)\remoteagent.psm1"
if ($(arg).Platform -eq "Windows" -or $(arg).Update -eq "Yes") {
    Global:Get-Version
    Global:Start-Update -Update $Getupdates
}
if ($(arg).Platform -eq "windows") { 
    Global:Add-Module "$($(vars).startup)\getconfigs.psm1"
    Global:Start-AgentCheck 
}

## create debug/command folder
if (-not (Test-Path ".\build\txt")) { New-Item -Path ".\build" -Name "txt" -ItemType "directory" | Out-Null }

##Start Data Collection
Global:Add-Module "$($(vars).startup)\datafiles.psm1"

$AllProtocols = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12' 
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols

Global:Get-DateFiles
Global:Clear-Stats
Global:Get-ArgNotice
Global:Set-NewType
if ($(arg).SWARM_Mode -eq "Yes") {
    Global:Write-Log "Sycronizing Time To Nist" -ForegroundColor Yellow
    $Sync = Global:Get-Nist
    try {
        Set-Date $Sync -ErrorAction Stop 
    }
    catch { 
        Global:Write-Log "Failed to syncronize time- Are you root/administrator?" -ForegroundColor red; 
        Start-Sleep -S 5 
    }
}
##HiveOS Confirmation
if( (Test-Path "/hive/miners") -or $(arg).Hive_Hash -ne "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" ) { $(arg).HiveOS = "Yes" }
Global:Write-Log "HiveOS = $($(arg).HiveOS)"

#Startings Settings (Non User Arguments):
$(vars).Add("Instance",1)
$(vars).Add("ActiveMinerPrograms",@())
$(vars).Add("DWallet",$null)
$(vars).Add("DCheck",$false)
$(vars).Add("Warnings",@())
$(vars).Add("Pool_Hashrates",@{})
$(vars).Add("Watts",$Null)
if ($(arg).Timeout) { $(vars).ADD("TimeoutTime",[Double]$(arg).Timeout * 3600) }
else { $(vars).Add("TimeoutTime",10000000000) }
$(vars).Add("TimeoutTimer",(New-Object -TypeName System.Diagnostics.Stopwatch))
$(vars).TimeoutTimer.Start()
$(vars).Add("logtimer",(New-Object -TypeName System.Diagnostics.Stopwatch))
$(vars).logtimer.Start()
$(vars).Add("QuickTimer",(New-Object -TypeName System.Diagnostics.Stopwatch))
$(vars).Add("MinerWatch",(New-Object -TypeName System.Diagnostics.Stopwatch))
$(vars).Add("WattEx",$Null)
$(vars).Add("Rates",$Null)
$(vars).Add("BestActiveMiners",$Null)
$(vars).Add("BTCExchangeRate",$Null)

##Determine Net Modules
$(vars).Add("NetModules",@())
$(vars).Add("WebSites",@())
if ($(arg).Hive_Hash -ne "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" -or (Test-Path "/hive/miners") ) { $(vars).NetModules += ".\build\api\hiveos"; $(vars).WebSites += "HiveOS" }
##if ($Config.Params.Swarm_Hash -ne "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx") { $(vars).NetModules += ".\build\api\swarm"; $(vars).WebSites += "SWARM" }

## Initialize
$(vars).Add("GPU_Count",$Null)
$(vars).Add("BusData",$Null)
switch ($(arg).Platform) {
    "linux" {
        Global:Add-Module "$($(vars).startup)\linuxconfig.psm1"
        Global:Add-Module "$($(vars).startup)\sexyunixlogo.psm1"
        Global:Start-LinuxConfig 
    }
    "windows" { 
        Global:Add-Module "$($(vars).startup)\winconfig.psm1"
        Global:Add-Module "$($(vars).startup)\sexywinlogo.psm1"
        Global:Start-WindowsConfig 
    }
}

## Determine AMD platform
if ($(arg).Type -like "*AMD*") {
    if ([string]$(arg).CLPlatform) { $(vars).amdPlatform = [string]$(arg).CLPlatform }
    else {
        Global:Write-Log "Getting AMD OPENCL Platform. Note: If SWARM doesn't continue, a GPU has crashed on rig." -ForeGroundColor Yellow
        Global:Add-Module "$($(vars).startup)\cl.psm1"
        [string]$(vars).amdPlatform = Global:Get-AMDPlatform
        Global:Write-Log "AMD OpenCL Platform is $(vars).amdPlatform"
    }
}

##GPU-Count- Parse the hashtable between devices.
if ($(arg).Type -like "*NVIDIA*" -or $(arg).Type -like "*AMD*" -or $(arg).Type -like "*CPU*") {
    if (Test-Path ".\build\txt\nvidiapower.txt") { Remove-Item ".\build\txt\nvidiapower.txt" -Force }
    if (Test-Path ".\build\txt\amdpower.txt") { Remove-Item ".\build\txt\amdpower.txt" -Force }
    if ($(vars).GPU_Count -eq 0) { $Device_Count = $(arg).CPUThreads }
    else { $Device_Count = $(vars).GPU_Count }
    Global:Write-Log "Device Count = $Device_Count" -foregroundcolor green
    Remove-Variable -Name Device_Count
    Start-Sleep -S 2

   
    if ([string]$(arg).GPUDevices1) {
        $(vars).Add("NVIDIADevices1",([String]$(arg).GPUDevices1 -replace " ", ","))
        $(vars).Add("AMDDevices1",([String]$(arg).GPUDevices1 -replace " ", ","))
    }
    else { 
        $(vars).Add("NVIDIADevices1","none")
        $(vars).Add("AMDDevices1","none")
    }
    if ([string]$(arg).GPUDevices2) { $(vars).Add("NVIDIADevices2",([String]$(arg).GPUDevices2 -replace " ", ",")) } else { $(vars).Add("NVIDIADevices2","none") }
    if ([string]$(arg).GPUDevices3) { $(vars).Add("NVIDIADevices3",([String]$(arg).GPUDevices3 -replace " ", ",")) } else { $(vars).Add("NVIDIADevices3","none") }

    $(vars).Add("GCount",(Get-Content ".\build\txt\devicelist.txt" | ConvertFrom-Json))
    $(vars).Add("NVIDIATypes",@()); if ($(arg).Type -like "*NVIDIA*") { $(arg).Type | Where { $_ -like "*NVIDIA*" } | % { $(vars).NVIDIATypes += $_ } }
    $(vars).Add("CPUTypes",@()); if ($(arg).Type -like "*CPU*") { $(arg).Type | Where { $_ -like "*CPU*" } | % { $(vars).CPUTypes += $_ } }
    $(vars).Add("AMDTypes",@()); if ($(arg).Type -like "*AMD*") { $(arg).Type | Where { $_ -like "*AMD*" } | % { $(vars).AMDTypes += $_ } }
}


##Start New Agent
Global:Add-Module "$($(vars).startup)\getconfigs.psm1"
Global:Write-Log "Starting New Background Agent" -ForegroundColor Cyan
if ($(arg).Platform -eq "windows") { Global:Start-Background }
elseif ($(arg).Platform -eq "linux") { Start-Process ".\build\bash\background.sh" -ArgumentList "background $($($(vars).dir))" -Wait }

##Get Optional Miners
Global:Get-Optional
Global:Add-LogErrors
Global:Remove-Modules

$(vars).Remove("BusData")
$(vars).Remove("GPU_Count")

##############################################################################
#######                      End Startup                                ######
##############################################################################

While ($true) {

    do {

        ##Insert Looping Modules Here

        ##############################################################################
        #######                     PHASE 1: Build                              ######
        ##############################################################################
        $(vars).Add("Algorithm",@())
        $(vars).Add("BanHammer",@())
        $Global:ASICTypes = @(); 
        $global:ASICS = @{ }
        $global:All_AltWallets = $null
        $global:SWARMAlgorithm = $Config.Params.Algorithm

        ##Insert Build Single Modules Here

        ##Insert Build Looping Modules Here

        ##Build Modules
        Global:Add-Module "$($(vars).global)\include.psm1"
        Global:Add-Module "$($(vars).global)\stats.psm1"

        #Get Miner Config Files
        Global:Add-Module "$($(vars).build)\miners.psm1"
        if ($(arg).Type -like "*CPU*") { $(vars).Add("cpu",(Global:Get-minerfiles -Types "CPU")) }
        if ($(arg).Type -like "*NVIDIA*") { $(vars).Add("nvidia",(Global:Get-minerfiles -Types "NVIDIA" -Cudas $(arg).Cuda)) }
        if ($(arg).Type -like "*AMD*") { $(vars).Add("amd",(Global:Get-minerfiles -Types "AMD")) }

        ## Check to see if wallet is present:
        if (-not $(arg).Wallet1) { 
            Global:Write-Log "missing wallet1 argument, exiting in 5 seconds" -ForeGroundColor Red; 
            Start-Sleep -S 5; 
            exit 
        }

        ## Load Miner Configurations
        Global:Add-Module "$($(vars).build)\configs.psm1"
        Global:Get-MinerConfigs
        $global:Config.Pool_Algos = Get-Content ".\config\pools\pool-algos.json" | ConvertFrom-Json
        Global:Add-ASICS
        $global:oc_default = Get-Content ".\config\oc\oc-defaults.json" | ConvertFrom-Json
        $global:oc_algos = Get-Content ".\config\oc\oc-algos.json" | ConvertFrom-Json

        ##Manage Pool Bans
        Global:Add-Module "$($(vars).build)\poolbans.psm1"
        Global:Start-PoolBans


        ## Handle Wallet Stuff / Bans
        Global:Add-Module "$($(vars).build)\wallets.psm1"
        Global:Set-Donation
        Global:Get-Wallets
        . .\build\powershell\scripts\bans.ps1 "add" $(arg).Bans "process" | Out-Null
        Global:Add-Algorithms
        Global:Set-Donation
        if ($(arg).Coin.Count -eq 1 -and $(arg).Coin -ne "") { $(arg).Auto_Coin = "No" }

        # Pricing and Clearing Timeouts 
        Global:Add-Module "$($(vars).build)\pricing.psm1"
        Global:Get-Watts
        Global:Get-Pricing
        Global:Clear-Timeouts

        Global:Remove-Modules
        $Screen = $null
        $Value = $null
        $Item = $null
        $JsonBanHammer = $null
        $Launch = $null
        $PoolJson = $null
        $BanChange = $null
        $BanDir = $null
        $PoolDir = $null
        $PoolChange = $Null

        ##############################################################################
        #######                         END PHASE 1                             ######
        ##############################################################################



        ##############################################################################
        #######                        PHASE 2: POOLS                           ######
        ##############################################################################

        ##Pool Modules
        Global:Add-Module "$($(vars).global)\include.psm1"
        Global:Add-Module "$($(vars).global)\stats.psm1"

        ## Build Initial Pool Hash Tables
        $global:Coins = $false
        $global:FeeTable = @{ }
        $global:divisortable = @{ }
        $global:SingleMode = $false
        $global:AlgoPools = $Null
        $global:CoinPools = $Null
        $(vars).Pool_Hashrates = @{ }

        ##Insert Pools Single Modules Here

        ##Insert Pools Looping Modules Here

        Global:Add-Module "$($(vars).pool)\initial.psm1"
        Global:Get-PoolTables
        Global:Remove-BanHashrates
        $global:Miner_HashTable = Global:Get-MinerHashTable
        ##Add Global Modules - They Get Removed in Above Function
        Global:Remove-Modules
        . .\build\powershell\global\modules.ps1
        Import-Module -Name "$($(vars).global)\include.psm1" -Scope Global
        Global:Add-Module "$($(vars).global)\stats.psm1"

        ##Get Algorithm Pools
        Global:Add-Module "$($(vars).pool)\gather.psm1"
        Global:Get-AlgoPools
        Global:Get-CoinPools
        Global:Remove-Modules
        Clear-Variable -Name "FeeTable" -ErrorAction Ignore -Scope Global
        Clear-Variable -Name "divisortable" -ErrorAction Ignore -Scope Global
        Clear-Variable -Name "All_AltWallets" -ErrorAction Ignore -Scope Global
        Clear-Variable -Name "Wallets" -ErrorAction Ignore -Scope Global

        ##############################################################################
        #######                         END PHASE 2                             ######
        ##############################################################################


        
        ##############################################################################
        #######                        PHASE 3: Miners                          ######
        ##############################################################################

        ##Miners Modules
        Global:Add-Module "$($(vars).global)\include.psm1"
        Global:Add-Module "$($(vars).global)\stats.psm1"

        $global:Miner_HashTable = $Null
        $(vars).Add( "Thresholds", @() )
        $Global:Miners = New-Object System.Collections.ArrayList

        ##Insert Miners Single Modules Here

        ##Insert Miners Looping Modules Here


        ##Load The Miners
        Global:Add-Module "$($(vars).miner)\gather.psm1"
        Global:Get-AlgoMiners
        Global:Get-CoinMiners

        ##Send error if no miners found
        if ($Global:Miners.Count -eq 0) {
            $HiveMessage = "No Miners Found! Check Arguments/Net Connection"
            $HiveWarning = @{result = @{command = "timeout" } }
            if ($(vars).WebSites) {
                $(vars).WebSites | ForEach-Object {
                    $Sel = $_
                    try {
                        Global:Add-Module "$($(vars).web)\methods.psm1"
                        Global:Get-WebModules $Sel
                        $SendToHive = Global:Start-webcommand -command $HiveWarning -swarm_message $HiveMessage -Website "$($Sel)"
                    }
                    catch { Global:Write-Log "WARNING: Failed To Notify $($Sel)" -ForeGroundColor Yellow } 
                    Global:Remove-WebModules $sel
                }
            }
            Global:Write-Log "$HiveMessage" -ForegroundColor Red
            start-sleep $(arg).Interval;
            continue  
        }

        ##Sort The Miners
        Global:Add-Module "$($(vars).miner)\sorting.psm1"
        if ($(arg).Volume -eq "Yes") { Get-Volume }
        $CutMiners = Global:Start-MinerReduction
        $CutMiners | ForEach-Object { $Global:Miners.Remove($_) } | Out-Null;
        $Global:Miners | ForEach-Object { $_.Symbol = $_.Symbol -replace "-Algo", ""; $_.Symbol = $_.Symbol -replace "-Coin", "" }
        Global:Start-Sorting
        Global:Add-SwitchingThreshold

        ##Choose The Best Miners
        Global:Add-Module "$($(vars).miner)\choose.psm1"
        Remove-BadMiners
        $global:Miners_Combo = Global:Get-BestMiners
        $global:bestminers_combo = Global:Get-Conservative
        $BestMiners_Selected = $global:bestminers_combo.Symbol
        $BestPool_Selected = $global:bestminers_combo.MinerPool
        Global:Write-Log "Most Ideal Choice Is $($BestMiners_Selected) on $($BestPool_Selected)" -foregroundcolor green

        Global:Remove-Modules
        $(vars).Remove("Algorithm")
        $(vars).Remove("BanHammer")
        $CutMiners = $null
        $global:Miners_Combo = $null
        $BestMiners_Selected = $null
        $BestPool_Selected = $null
        $(vars).Remove("amd")
        $(vars).Remove("nvidia")
        $(vars).Remove("cpu")
        $(vars).Pool_Hashrates = $null
        $global:Miner_HashTable = $null
        $(vars).Watts = $null

        ##############################################################################
        #######                        End Phase 3                             ######
        ############################################################################## 

        ##############################################################################
        #######                        Phase 4: Control                         ######
        ##############################################################################

        ## Build the Current Active Miners
        $global:Restart = $false
        $global:NoMiners = $false
        $(vars).BestActiveMIners = @()
        $global:PreviousMinerPorts = @{AMD1 = ""; NVIDIA1 = ""; NVIDIA2 = ""; NVIDIA3 = ""; CPU = "" }
        $global:ClearedOC = $false; 
        $global:ClearedHash = $false; 
        $Global:HiveOCTune = $false
        $global:SWARM_IT = $false
        $global:MinerInterval = $null
        $global:MinerStatInt = $Null
        $global:ModeCheck = 0
        $global:BenchmarkMode = $false
        $global:Share_Table = @{ }

        ##Insert Control Single Modules Here

        ##Insert Control Looping Modules Here


        Global:Add-Module "$($(vars).global)\include.psm1"
        Global:Add-Module "$($(vars).global)\stats.psm1"
        if ($(arg).Type -like "*ASIC*") { Global:Add-Module "$($(vars).global)\hashrates.psm1" }
        Global:Add-Module "$($(vars).control)\config.psm1"

        ## Add New Miners- Download if neccessary
        ## Ammend Their Pricing
        Global:Add-Module "$($(vars).control)\initial.psm1"
        Global:Start-MinerDownloads
        Global:Get-ActiveMiners $global:bestminers_combo
        Global:Get-BestActiveMiners
        Global:Get-ActivePricing

        ##Start / Stop / Restart Miners
        ##Handle OC
        Global:Add-Module "$($(vars).control)\run.psm1"
        Global:Add-Module "$($(vars).control)\launchcode.psm1"
        Global:Add-Module "$($(vars).control)\config.psm1"
        Global:Stop-ActiveMiners
        Global:Start-NewMiners -Reason "Launch"

        ##Determing Interval
        Global:Add-Module "$($(vars).control)\notify.psm1"
        Global:Get-LaunchNotification
        Global:Get-Interval
        ##Get Shares
        Global:Write-Log "Getting Coin Tracking From Pool" -foregroundColor Cyan
        if ($glbal:Config.params.Track_Shares -eq "Yes") { Global:Get-CoinShares }

        Global:Remove-Modules
        $global:oc_algos = $null
        $global:oc_default = $null
        $global:PreviousMinerPorts = $null
        $global:Restart = $null
        $global:NoMiners = $null
        $global:ClearedOC = $null
        $Global:HiveOCTune = $null

        ##############################################################################
        #######                        End Phase 4                              ######
        ##############################################################################


        ##############################################################################
        #######                        Phase 5: Run                             ######
        #############################################################################


        Global:Add-Module "$($(vars).global)\include.psm1"
        Global:Add-Module "$($(vars).global)\stats.psm1"
        Global:Add-Module "$($(vars).global)\hashrates.psm1"

        ##Insert Run Single Modules Here

        ##Insert Run Looping Modules Here

        ## Clear Old Commands Data
        Global:Add-Module "$($(vars).run)\initial.psm1"
        Global:Get-ExchangeRate
        Global:Get-ScreenName
        $Global:Miners | ConvertTo-Json -Depth 4 | Set-Content ".\build\txt\profittable.txt"
        Global:Clear-Commands
        Get-Date | Out-File ".\build\txt\minerstats.txt"
        Get-Date | Out-File ".\build\txt\charts.txt"
        Global:Get-MinerStatus | Out-File ".\build\txt\minerstats.txt" -Append
        Global:Get-Charts | Out-File ".\build\txt\charts.txt" -Append

        ## Refreshing Pricing Data
        Global:Add-Module "$($(vars).run)\commands.psm1"
        Global:Get-PriceMessage
        Global:Get-Commands
        $Global:Miners.Clear()
        Global:Get-Logo
        Global:Update-Logging
        Get-Date | Out-File ".\build\txt\mineractive.txt"
        Global:Get-MinerActive | Out-File ".\build\txt\mineractive.txt" -Append

        ##Start SWARM Loop
        Global:Add-Module "$($(vars).run)\loop.psm1"
        Global:Start-MinerLoop

        Global:Remove-Modules
        $(vars).Remove("Thresholds")

        ##############################################################################
        #######                        End Phase 5                              ######
        ##############################################################################

        ##############################################################################
        #######                       Phase 6: Benchmark                        ######
        ##############################################################################

        Global:Add-Module "$($(vars).global)\include.psm1"
        Global:Add-Module "$($(vars).global)\stats.psm1"
        Global:Add-Module "$($(vars).global)\gpu.psm1"
        Global:Add-Module "$($(vars).global)\hashrates.psm1"
        Global:Add-Module "$($(vars).benchmark)\attempt.psm1"
        $global:ActiveSymbol = @()

        ##Insert Benchmark Single Modules Here

        ##Insert Benchmark Looping Modules Here

        ## Start WattOMeter function
        if ($(arg).WattOMeter -eq "Yes") { Global:Start-WattOMeter }

        ##Try To Benchmark
        Global:Start-Benchmark

        ##############################################################################
        #######                       End Phase 6                               ######
        ##############################################################################

        Global:Remove-Modules
        Get-Job -State Completed | Remove-Job
        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()
        [GC]::Collect()    
        Clear-History
    }until($Error.Count -gt 0)
    Import-Module "$($(vars).global)\include.psm1" -Scope Global
    Global:Add-LogErrors
    Global:Remove-Modules
    continue;
}
