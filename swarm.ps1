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
$Global:config = [hashtable]::Synchronized(@{ })
[cultureinfo]::CurrentCulture = 'en-US'

$Global:Config.Add("vars", @{ })
$Global:Config.vars.Add( "dir", (Split-Path $script:MyInvocation.MyCommand.Path) )
$Global:Config.vars.dir = $Global:Config.vars.dir -replace "/var/tmp", "/root"
Set-Location $Global:Config.vars.dir

##filepath dir
. .\build\powershell\global\modules.ps1
$env:Path += ";$($(vars).dir)\build\cmd"

## Window Security Items
if ($IsWindows) {
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
    Remove-Variable -name Net -ErrorAction Ignore

    ## Windows Icon
    Start-Process "powershell" -ArgumentList "Set-Location `'$($(vars).dir)`'; .\build\powershell\scripts\icon.ps1 `'$($(vars).dir)\build\apps\icons\SWARM.ico`'" -NoNewWindow
}

## Debug Mode- Allow you to run with last known arguments or arguments.json.
$(vars).Add("debug", $false)
if ($global:config.vars.debug -eq $True) {
    Start-Transcript ".\logs\debug.log"
    if (($IsWindows)) { Set-ExecutionPolicy Bypass -Scope Process }
}

## Load Modules
$(vars).Add("startup", "$($(vars).dir)\build\powershell\startup")
$(vars).Add("web", "$($(vars).dir)\build\api\web")
$(vars).Add("global", "$($(vars).dir)\build\powershell\global")
$(vars).Add("build", "$($(vars).dir)\build\powershell\build")
$(vars).Add("pool", "$($(vars).dir)\build\powershell\pool")
$(vars).Add("miner", "$($(vars).dir)\build\powershell\miner")
$(vars).Add("control", "$($(vars).dir)\build\powershell\control")
$(vars).Add("run", "$($(vars).dir)\build\powershell\run")
$(vars).Add("benchmark", "$($(vars).dir)\build\powershell\benchmark")

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
Remove-Variable -name P -ErrorAction Ignore

$(vars).Add("Modules", @())

## Get Parameters
Global:Add-Module "$($(vars).startup)\parameters.psm1"
Global:Get-Parameters
$(arg).TCP_Port | Out-File ".\build\txt\port.txt"

##Insert Single Modules Here

## Startup Modules
Import-Module "$($(vars).global)\stats.psm1" -Scope Global
Import-Module "$($(vars).global)\hashrates.psm1" -Scope Global
Import-Module "$($(vars).global)\gpu.psm1" -Scope Global


if ($IsWindows -and [string]$Global:config.hive_params.MINER_DELAY -ne "") {
    Write-Host "Miner Delay Specified- Sleeping for $($Global:config.hive_params.MINER_DELAY)"
    $Sleep = [Double]$Global:config.hive_params.MINER_DELAY
    Start-Sleep -S $Sleep
    Remove-Variable -Name Sleep -ErrorAction Ignore
}

## Crash Reporting
Global:Add-Module "$($(vars).startup)\crashreport.psm1"
Global:Start-CrashReporting

## Start The Log
Global:Add-Module "$($(vars).startup)\startlog.psm1"
$($(vars).dir) | Set-Content ".\build\bash\dir.sh";
$Global:log_params = [hashtable]::Synchronized(@{ })
$Global:log_params.Add("lognum", 1)
$global:log_params.Add("logname", $null)
$Global:log_params.Add( "dir", (Split-Path $script:MyInvocation.MyCommand.Path) )
$Global:log_params.dir = $Global:Config.vars.dir -replace "/var/tmp", "/root"
Global:Start-Log -Number $global:log_params.lognum;

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

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12' 

Global:Get-DateFiles
Global:Clear-Stats
Global:Get-ArgNotice
Global:Set-NewType
if ($(arg).SWARM_Mode -eq "Yes") {
    log "Sycronizing Time To Nist" -ForegroundColor Yellow
    $Sync = Global:Get-Nist
    try {
        Set-Date $Sync -ErrorAction Stop 
    }
    catch { 
        log "Failed to syncronize time- Are you root/administrator?" -ForegroundColor red; 
        Start-Sleep -S 5 
    }
}
##HiveOS Confirmation
if ( (Test-Path "/hive/miners") -or $(arg).Hive_Hash -ne "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" ) { $(arg).HiveOS = "Yes" }
log "HiveOS = $($(arg).HiveOS)"

#Startings Settings (Non User Arguments):
Global:Add-New_Variables

##Determine Net Modules
$WebArg = @("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", "")
if ($(arg).Hive_Hash -notin $WebArg -or (Test-Path "/hive/miners") ) { $(vars).NetModules += ".\build\api\hiveos"; $(vars).WebSites += "HiveOS" }
else { $(arg).HiveOS = "No" }
Remove-Variable -Name WebArg -ErrorAction Ignore
if ($Config.Params.Swarm_Hash -ne "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx") { $(vars).NetModules += ".\build\api\swarm"; $(vars).WebSites += "SWARM" }

## Initialize
$(vars).Add("GPU_Count", $Null)
$(vars).Add("BusData", $Null)
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
$(vars).add("AMDPlatform", 0)
if ($(arg).Type -like "*AMD*") {
    if ([string]$(arg).CLPlatform) { $(vars).AMDPlatform = [string]$(arg).CLPlatform }
    else {
        log "Getting AMD OPENCL Platform. Note: If SWARM doesn't continue, a GPU has crashed on rig." -ForeGroundColor Yellow
        Global:Add-Module "$($(vars).startup)\cl.psm1"
        [string]$(vars).AMDPlatform = Global:Get-AMDPlatform
        log "AMD OpenCL Platform is $($(vars).AMDPlatform)"
    }
}

##GPU-Count- Parse the hashtable between devices.
if ($(arg).Type -like "*NVIDIA*" -or $(arg).Type -like "*AMD*" -or $(arg).Type -like "*CPU*") {
    if (Test-Path ".\build\txt\nvidiapower.txt") { Remove-Item ".\build\txt\nvidiapower.txt" -Force }
    if (Test-Path ".\build\txt\amdpower.txt") { Remove-Item ".\build\txt\amdpower.txt" -Force }
    if ($(vars).GPU_Count -eq 0) { $Device_Count = $(arg).CPUThreads }
    else { $Device_Count = $(vars).GPU_Count }
    log "Device Count = $Device_Count" -foregroundcolor green
    Remove-Variable -Name Device_Count -ErrorAction Ignore
    Start-Sleep -S 2

   
    if ([string]$(arg).GPUDevices1) {
        $(vars).Add("NVIDIADevices1", ([String]$(arg).GPUDevices1 -replace " ", ","))
        $(vars).Add("AMDDevices1", ([String]$(arg).GPUDevices1 -replace " ", ","))
    }
    else { 
        $(vars).Add("NVIDIADevices1", "none")
        $(vars).Add("AMDDevices1", "none")
    }
    if ([string]$(arg).GPUDevices2) { $(vars).Add("NVIDIADevices2", ([String]$(arg).GPUDevices2 -replace " ", ",")) } else { $(vars).Add("NVIDIADevices2", "none") }
    if ([string]$(arg).GPUDevices3) { $(vars).Add("NVIDIADevices3", ([String]$(arg).GPUDevices3 -replace " ", ",")) } else { $(vars).Add("NVIDIADevices3", "none") }

    $(vars).Add("GCount", (Get-Content ".\build\txt\devicelist.txt" | ConvertFrom-Json))
    $(vars).Add("NVIDIATypes", @()); if ($(arg).Type -like "*NVIDIA*") { $(arg).Type | Where { $_ -like "*NVIDIA*" } | % { $(vars).NVIDIATypes += $_ } }
    $(vars).Add("CPUTypes", @()); if ($(arg).Type -like "*CPU*") { $(arg).Type | Where { $_ -like "*CPU*" } | % { $(vars).CPUTypes += $_ } }
    $(vars).Add("AMDTypes", @()); if ($(arg).Type -like "*AMD*") { $(arg).Type | Where { $_ -like "*AMD*" } | % { $(vars).AMDTypes += $_ } }
}


##Start New Agent
Global:Add-Module "$($(vars).startup)\getconfigs.psm1"
log "Starting New Background Agent" -ForegroundColor Cyan
if ($(arg).Platform -eq "windows") { Global:Start-Background }
elseif ($(arg).Platform -eq "linux") { $Proc = Start-Process ".\build\bash\background.sh" -ArgumentList "background $($($(vars).dir))" -PassThru; $Proc | Wait-Process }

## Parse Wallet Configs
Global:Add-Module "$($(vars).build)\wallets.psm1"
$(vars).Add("All_AltWallets", $Null)
Global:Get-Wallets
if ([String]$(arg).Admin_Fee -eq 0) { if (test-Path ".\admin") { Remove-Item ".\admin" -Recurse -Force | Out-Null } }

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

        ## Basic Variable Control:
        ## 'create' will add a new variable to the variable hashtable (vars)
        ## 'remove' will either remove the variable specified, or all varibles if 'all' is specified.
        ## 'create' will add the the (Vars)."Active_Variables" list as well as add the vars to $(vars)
        ## 'remove' will remove the name from the "Active_Variables" array.
        ## 'check' checks if variable currently exists- $true if does, $false if it doesn't
        ##  This allows the abililty to remove/add variables to both, as well as clear them all with a single command.
        ##  These are all global values- It can be used with user-created modules.

        create Algorithm @()
        create BanHammer @()
        create ASICTypes @()
        create ASICS @{ }
        create All_AltWalltes $null
        create SWARMAlgorithm $(arg).Algorithm

        ##Insert Build Single Modules Here

        ##Insert Build Looping Modules Here

        #Get Miner Config Files
        Global:Add-Module "$($(vars).build)\miners.psm1"
        if ($(arg).Type -like "*CPU*") { create cpu (Global:Get-minerfiles -Types "CPU") }
        if ($(arg).Type -like "*NVIDIA*") { create nvidia (Global:Get-minerfiles -Types "NVIDIA" -Cudas $(arg).Cuda) }
        if ($(arg).Type -like "*AMD*") { create amd (Global:Get-minerfiles -Types "AMD") }

        ## Check to see if wallet is present:
        if (-not $(arg).Wallet1) { 
            log "missing wallet1 argument, exiting in 5 seconds" -ForeGroundColor Red; 
            Start-Sleep -S 5; 
            exit 
        }

        ## Load Miner Configurations
        Global:Add-Module "$($(vars).build)\configs.psm1"
        Global:Get-MinerConfigs
        $global:Config.Pool_Algos = Get-Content ".\config\pools\pool-algos.json" | ConvertFrom-Json
        Global:Add-ASICS
        create oc_default (Get-Content ".\config\oc\oc-defaults.json" | ConvertFrom-Json)
        create oc_algos (Get-Content ".\config\oc\oc-algos.json" | ConvertFrom-Json)

        ##Manage Pool Bans
        Global:Add-Module "$($(vars).build)\poolbans.psm1"
        Global:Start-PoolBans


        ## Handle Wallet Stuff / Bans
        Global:Add-Module "$($(vars).build)\wallets.psm1"
        Global:Set-Donation
        Global:Get-Wallets
        if ([String]$(arg).Admin_Fee -eq 0) { if (test-Path ".\admin") { Remove-Item ".\admin" -Recurse -Force | Out-Null } }
        . .\build\powershell\scripts\bans.ps1 "add" $(arg).Bans "process" | Out-Null
        Global:Add-Algorithms
        Global:Set-Donation
        if ($(arg).Coin.Count -eq 1 -and $(arg).Coin -ne "") { $(arg).Auto_Coin = "No" }

        # Pricing and Clearing Timeouts 
        Global:Add-Module "$($(vars).build)\pricing.psm1"
        Global:Get-Watts
        Global:Get-TimeCheck
        Global:Get-Pricing
        Global:Clear-Timeouts

        ## Phase Clean up
        ## Remove variables that were added from external run of a SWARM command.
        Remove-Variable -Name BanDir -ErrorAction Ignore
        Remove-Variable -Name Screen -ErrorAction Ignore
        Remove-Variable -Name Value -ErrorAction Ignore
        Remove-Variable -Name Item -ErrorAction Ignore
        Remove-Variable -Name JsonBanHammer -ErrorAction Ignore
        Remove-Variable -Name Launch -ErrorAction Ignore
        Remove-Variable -Name BanChange -ErrorAction Ignore
        Remove-Variable -Name PoolDir -ErrorAction Ignore
        Remove-Variable -Name PoolChange -ErrorAction Ignore
        Remove-Variable -Name BanJson -ErrorAction Ignore
        Remove-Variable -Name Action -ErrorAction Ignore
        Global:Remove-Modules

        ##############################################################################
        #######                         END PHASE 1                             ######
        ##############################################################################



        ##############################################################################
        #######                        PHASE 2: POOLS                           ######
        ##############################################################################

        ## Build Initial Pool Hash Tables
        create Coins $false
        create FeeTable @{ }
        create DivisorTable @{ }
        create SingleMode @{ }
        create AlgoPools 1
        create CoinPools 1
        create Pool_Hashrates @{ }
        if($(arg).Mode -eq "Easy") { create Cut_Items @{ } }

        ##Insert Pools Single Modules Here

        ##Insert Pools Looping Modules Here

        Global:Add-Module "$($(vars).pool)\initial.psm1"
        Global:Get-PoolTables
        Global:Remove-BanHashrates
        if($(vars).Options -eq 1){
            . .\build\data\json.ps1
            Global:Get-Message
        }

        create Miner_HashTable (Global:Get-MinerHashTable)

        ##Add Global Modules - They Get Removed in Above Function
        Global:Remove-Modules
        . .\build\powershell\global\modules.ps1

        ##Get Algorithm Pools
        Global:Add-Module "$($(vars).pool)\gather.psm1"
        Global:Get-AlgoPools
        Global:Get-CoinPools
        Global:Remove-Modules

        ## Phase Clean up
        ## Remove variables no longer needed.
        remove FeeTable
        remove DivisorTable

        ##############################################################################
        #######                         END PHASE 2                             ######
        ##############################################################################


        
        ##############################################################################
        #######                        PHASE 3: Miners                          ######
        ##############################################################################

        create Thresholds @()
        create Miners (New-Object System.Collections.ArrayList)
        create PreviousMinerPorts @{AMD1 = ""; NVIDIA1 = ""; NVIDIA2 = ""; NVIDIA3 = ""; CPU = "" }

        ##Insert Miners Single Modules Here

        ##Insert Miners Looping Modules Here

        ##Load The Miners
        Global:Add-Module "$($(vars).miner)\gather.psm1"
        Global:Get-AlgoMiners
        Global:Get-CoinMiners

        ##Send error if no miners found
        if ($(vars).Miners.Count -eq 0) {
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
                    catch { log "WARNING: Failed To Notify $($Sel)" -ForeGroundColor Yellow } 
                    Global:Remove-WebModules $sel
                }
            }
            log "$HiveMessage" -ForegroundColor Red
            Remove-Variable -Name HiveMessage -ErrorAction Ignore
            Remove-Variable -Name HiveWarning -ErrorAction Ignore
            Remove-Variable -Name Sel -ErrorAction Ignore

            ## Go to sleep for interval
            start-sleep $(arg).Interval;

            ## Check How many times it occurred.
            ## If it occurred more than 10 times-
            ## Remove all current hashrates, and migrate backup hashrates
            ## to stats folder. Then Restart Computer.
            $(vars).No_Miners++
            Global:Confirm-Backup

            ##remove all active parameters, Then restart loop
            remove all
            continue  
        }

        ##Sort The Miners
        Global:Add-Module "$($(vars).miner)\sorting.psm1"
        if ($(arg).Volume -eq "Yes") { Get-Volume }
        Global:Start-MinerDownloads
        $CutMiners = Global:Start-MinerReduction
        $CutMiners | ForEach-Object { $(vars).Miners.Remove($_) } | Out-Null;
        Remove-Variable -Name CutMiners -ErrorAction Ignore
        $(vars).Miners | ForEach-Object { $_.Symbol = $_.Symbol -replace "-Algo", ""; $_.Symbol = $_.Symbol -replace "-Coin", "" }
        Global:Start-Sorting
        Global:Add-SwitchingThreshold

        ##Choose The Best Miners
        Global:Add-Module "$($(vars).miner)\choose.psm1"
        Remove-BadMiners
        create Miners_Combo (Global:Get-BestMiners)
        $(vars).bestminers_combo = Global:Get-Conservative
        log "Most Ideal Choice Is $($(vars).bestminers_combo.Symbol) on $($(vars).bestminers_combo.MinerPool)" -foregroundcolor green

        ## Phase Clean up
        Global:Remove-Modules
        $(vars).Watts = $null
        remove CoinPools 
        remove AlgoPools 
        remove amd 
        remove nvidia 
        remove cpu 
        remove SWARMAlgorithm
        remove BanHammer
        remove ASICTypes
        remove Algorithm
        remove Coins
        remove SingleMode
        remove Miner_HashTable
        remove Miners_Combo
        remove Pool_HashRates

        #########################################################1#####################
        #######                        End Phase 3                             ######
        ############################################################################## 

        ##############################################################################
        #######                        Phase 4: Control                         ######
        ##############################################################################

        ## Build the Current Active Miners
        create Restart $false
        create NoMiners $false
        create SWARM_IT $false
        create MinerInterval $null
        create MinerStatInt $null
        create ModeCheck 0
        create Share_Table @{ }
        create oc_groups @()
        
        ##Insert Control Single Modules Here

        ##Insert Control Looping Modules Here

        ## Add New Miners- Download if neccessary
        ## Ammend Their Pricing
        Global:Add-Module "$($(vars).control)\config.psm1"
        Global:Add-Module "$($(vars).control)\initial.psm1"
        Global:Get-ActiveMiners
        Global:Get-BestActiveMiners
        Global:Get-ActivePricing

        ## Start / Stop / Restart Miners
        ## Handle OC
        Global:Add-Module "$($(vars).control)\run.psm1"
        Global:Add-Module "$($(vars).control)\launchcode.psm1"
        Global:Add-Module "$($(vars).control)\config.psm1"
        Global:Stop-ActiveMiners
        Global:Start-NewMiners -Reason "Launch"

        ## Determing Interval
        Global:Add-Module "$($(vars).control)\notify.psm1"
        Global:Get-LaunchNotification
        Global:Get-Interval
        ## Get Shares
        log "Getting Coin Tracking From Pool" -foregroundColor Cyan
        if ($glbal:Config.params.Track_Shares -eq "Yes") { Global:Get-CoinShares }

        ## Phase Clean up
        Global:Remove-Modules
        remove oc_algos
        remove oc_default
        remove oc_groups
        remove PreviousMinerPorts
        remove Restart
        remove NoMiners

        ##############################################################################
        #######                        End Phase 4                              ######
        ##############################################################################


        ##############################################################################
        #######                        Phase 5: Run                             ######
        #############################################################################

        ##Insert Run Single Modules Here

        ##Insert Run Looping Modules Here

        ## Clear Old Commands Data
        Global:Add-Module "$($(vars).run)\initial.psm1"
        Global:Get-ExchangeRate
        Global:Get-ScreenName
        $(vars).Miners | ConvertTo-Json -Depth 4 | Set-Content ".\build\txt\profittable.txt"
        Global:Clear-Commands
        Get-Date | Out-File ".\build\txt\minerstats.txt"
        Get-Date | Out-File ".\build\txt\charts.txt"
        Global:Get-MinerStatus | Out-File ".\build\txt\minerstats.txt" -Append
        Global:Get-Charts | Out-File ".\build\txt\charts.txt" -Append

        ## Refreshing Pricing Data
        Global:Add-Module "$($(vars).run)\commands.psm1"
        Global:Get-PriceMessage
        Global:Get-Commands
        remove Miners
        Global:Get-Logo
        Global:Update-Logging
        Get-Date | Out-File ".\build\txt\mineractive.txt"
        Global:Get-MinerActive | Out-File ".\build\txt\mineractive.txt" -Append

        ##Start SWARM Loop
        Global:Add-Module "$($(vars).run)\loop.psm1"
        Global:Start-MinerLoop

        ## Phase Clean up
        Global:Remove-Modules
        remove Thresholds
        remove SWARM_IT
        remove MinerInterval
        remove ASICS
        remove Share_Table
        remove ModeCheck

        ##############################################################################
        #######                        End Phase 5                              ######
        ##############################################################################

        ##############################################################################
        #######                       Phase 6: Benchmark                        ######
        ##############################################################################

        Global:Add-Module "$($(vars).benchmark)\attempt.psm1"

        ##Insert Benchmark Single Modules Here

        ##Insert Benchmark Looping Modules Here

        ## Start WattOMeter function
        if ($(arg).WattOMeter -eq "Yes") { Global:Start-WattOMeter }

        ##Try To Benchmark
        Global:Start-Benchmark

        ##############################################################################
        #######                       End Phase 6                               ######
        ##############################################################################

        ## Remaining Clean up
        remove all
        Global:Remove-Modules
        Get-Job -State Completed | Remove-Job
        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()
        [GC]::Collect()    
        Clear-History

    }until($Error.Count -gt 0)
    Global:Add-LogErrors
    Global:Remove-Modules
    continue;
}
