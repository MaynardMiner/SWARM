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
Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)

##filepath dir
$global:dir = (Split-Path $script:MyInvocation.MyCommand.Path)
$env:Path += ";$global:dir\build\cmd"
try { Get-ChildItem . -Recurse | Unblock-File } catch { }

## Exclusion Windows Defender
try { 
    if ((Get-MpPreference).ExclusionPath -notcontains (Convert-Path .)) { 
        Start-Process "powershell" -Verb runAs -ArgumentList "Add-MpPreference -ExclusionPath `'$($global:Dir)`'" -WindowStyle Minimized 
    } 
}
catch { }

## Remove Extra NetFirewall - Temp Fix.
if ( -not (Test-Path ".\build\fixed.txt") ) { 
    try { 
        Write-Host "Removing Previous Net Firewall Rules"; 
        Remove-NetFirewallRule -All 
    }
    catch { }
    "Fixed" | Set-Content ".\build\fixed.txt"
}

## Set Firewall Rule
try { 
    $Net = Get-NetFireWallRule 
    if ($Net) {
        try { 
            if ( -not ( $Net | Where { $_.DisplayName -like "*swarm.ps1*" } ) ) { 
                New-NetFirewallRule -DisplayName 'swarm.ps1' -Direction Inbound -Program "$global:dir\swarm.ps1" -Action Allow | Out-Null
            } 
        }
        catch { }
    }
}
catch { }
$Net = $Null

if(Test-Path "C:\") {
    Start-Process "powershell" -ArgumentList "$global:dir\build\powershell\icon.ps1 `'$global:dir\build\apps\SWARM.ico`'" -NoNewWindow
}

## Debug Mode- Allow you to run with last known arguments or arguments.json.
$Global:Debug = $false
if ($Global:Debug -eq $True) {
    Start-Transcript ".\logs\debug.log"
    if ((Test-Path "C:\")) { Set-ExecutionPolicy Bypass -Scope Process }
}

## Load Modules
$global:Startup = "$Global:Dir\build\powershell\startup";
$global:Web = "$Global:Dir\build\api\web";
$global:global = "$Global:Dir\build\powershell\global";
$global:Build = "$Global:Dir\build\powershell\build";
$global:Pool = "$Global:Dir\build\powershell\pool";
$global:MinerP = "$Global:Dir\build\powershell\miner";
$global:Control = "$Global:Dir\build\powershell\control";
$global:Run = "$Global:Dir\build\powershell\run";
$global:benchmark = "$Global:Dir\build\powershell\benchmark";
$p = [Environment]::GetEnvironmentVariable("PSModulePath")
if ($P -notlike "*$Global:Dir\build\powershell*") {
    $P += ";$global:Startup";
    $P += ";$global:Web";
    $P += ";$global:global";
    $P += ";$global:Build";
    $P += ";$global:Pool";
    $P += ";$global:MinerP";
    $P += ";$global:Control";
    $P += ";$global:Run";
    $P += ";$global:benchmark";
    [Environment]::SetEnvironmentVariable("PSModulePath", $p)
    Write-Host "Modules Are Loaded" -ForegroundColor Green
}

## Date Bug
$global:cultureENUS = New-Object System.Globalization.CultureInfo("en-US")
[cultureinfo]::CurrentCulture = 'en-US'

## Global Modules
Import-Module -Name "$global:global\include.psm1"

## Get Parameters
$Global:config = @{ }
Import-Module -Name "$global:Startup\parameters.psm1"
Get-Parameters
Remove-Module -Name "parameters"

## Crash Reporting
Import-Module -Name "$global:Startup\crashreport.psm1"
Start-CrashReporting
Remove-Module -Name "crashreport"

## Start The Log
$global:dir | Set-Content ".\build\bash\dir.sh";
$global:LogNum = 1;
$global:logname = $null
Import-Module -Name "$global:Startup\startlog.psm1"
start-log -Number $global:LogNum;
Remove-Module -Name "startlog"

## Initiate Update Check
if ($global:Config.Params.Platform -eq "Windows" -or $global:Config.Params.Update -eq "Yes") { 
    Import-Module -Name "$global:Startup\remoteagent.psm1"
    Get-Version
    start-update -Update $Getupdates
}
if ($global:Config.Params.Platform -eq "windows") { Start-AgentCheck }
Remove-Module -Name "remoteagent"

## create debug/command folder
if (-not (Test-Path ".\build\txt")) { New-Item -Path ".\build" -Name "txt" -ItemType "directory" | Out-Null }

##Start Data Collection
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12, [Net.SecurityProtocolType]::Tls11, [Net.SecurityProtocolType]::tls
Import-Module -Name "$global:Startup\datafiles.psm1"
Get-DateFiles
Clear-Stats
Get-ArgNotice
Set-NewType
write-Log "Sycronizing Time Through Nist" -ForegroundColor Yellow
$Sync = Get-Nist
try {
    Set-Date $Sync -ErrorAction Stop 
}
catch { 
    write-Log "Failed to syncronize time- Are you root/administrator?" -ForegroundColor red; 
    Start-Sleep -S 5 
}
Remove-Module -Name "datafiles"

##HiveOS Confirmation
write-Log "HiveOS = $($global:Config.Params.HiveOS)"

#Startings Settings (Non User Arguments):
$global:Instance = 1
$WalletDonate = "1DRxiWx6yuZfN9hrEJa3BDXWVJ9yyJU36i"
$NicehashDonate = "3JfBiUZZV17DTjAFCnZb97UpBgtLPLLDop"
$UserDonate = "MaynardVII"
$WorkerDonate = "Rig1"
$Global:ActiveMinerPrograms = @()
$Global:DWallet = $null
$global:DCheck = $false
$DonationMode = $false
$Global:Warnings = @()
$global:Pool_Hashrates = @{ }
$global:Watts = $Null
if ($global:Config.Params.Timeout) { $global:TimeoutTime = [Double]$global:Config.Params.Timeout * 3600 }
else { $global:TimeoutTime = 10000000000 }
$global:TimeoutTimer = New-Object -TypeName System.Diagnostics.Stopwatch
$global:TimeoutTimer.Start()
$global:logtimer = New-Object -TypeName System.Diagnostics.Stopwatch
$global:logtimer.Start()
$global:QuickTimer = New-Object -TypeName System.Diagnostics.Stopwatch
$global:MinerWatch = New-Object -TypeName System.Diagnostics.Stopwatch
$global:WattEx = $Null
$global:Rates = $Null
$Global:BestActiveMIners = $Null
$global:BTCExchangeRate = $Null

##Determine Net Modules
$global:NetModules = @()
$global:WebSites = @()
if ($Config.Params.Farm_Hash -ne "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx") { $global:NetModules += ".\build\api\hiveos"; $global:WebSites += "HiveOS" }
if ($Config.Params.Swarm_Hash -eq "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx") { $global:NetModules += ".\build\api\SWARM"; $global:WebSites += "SWARM" }

## Initialize
$global:GPU_Count = $null
$global:BusData = $null
switch ($global:Config.params.Platform) {
    "linux" {
        Import-Module "$global:Startup\linuxconfig.psm1"
        Import-Module -Name "$global:Startup\sexyunixlogo.psm1"
        Start-LinuxConfig 
        Remove-Module "linuxconfig" 
        Remove-Module "sexyunixlogo" 
    }
    "windows" { 
        Import-Module "$global:Startup\winconfig.psm1"
        Import-Module -Name "$global:Startup\sexywinlogo.psm1"
        Start-WindowsConfig 
        Remove-Module "winconfig" 
        Remove-Module "sexywinlogo" 
    }
}

## Determine AMD platform
if ($global:Config.Params.Type -like "*AMD*") {
    if ([string]$global:Config.Params.CLPlatform) { $AMDPlatform = [string]$global:Config.Params.CLPlatform }
    else {
        Import-Module "$global:Startup\cl.psm1"
        [string]$AMDPlatform = get-AMDPlatform
        write-Log "AMD OpenCL Platform is $AMDPlatform"
        Remove-Module "cl"
    }
}

##GPU-Count- Parse the hashtable between devices.
if ($global:Config.Params.Type -like "*NVIDIA*" -or $global:Config.Params.Type -like "*AMD*" -or $global:Config.Params.Type -like "*CPU*") {
    if (Test-Path ".\build\txt\nvidiapower.txt") { Remove-Item ".\build\txt\nvidiapower.txt" -Force }
    if (Test-Path ".\build\txt\amdpower.txt") { Remove-Item ".\build\txt\amdpower.txt" -Force }
    if ($global:GPU_Count -ne 0) { $Global:GPUCount = @(); for ($i = 0; $i -lt $Global:GPU_Count; $i++) { [string]$Global:GPUCount += "$i," } }
    if ($global:Config.Params.CPUThreads -ne 0) { $CPUCount = @(); for ($i = 0; $i -lt $global:Config.Params.CPUThreads; $i++) { [string]$CPUCount += "$i," } }
    if ($Global:GPU_Count -eq 0) { $Device_Count = $global:Config.Params.CPUThreads }
    else { $Device_Count = $Global:GPU_Count }
    write-Log "Device Count = $Device_Count" -foregroundcolor green
    Start-Sleep -S 2

    if ([string]$global:Config.Params.GPUDevices1) {
        $Global:NVIDIADevices1 = [String]$global:Config.Params.GPUDevices1 -replace " ", ","; 
        $Global:AMDDevices1 = [String]$global:Config.Params.GPUDevices1 -replace " ", "," 
    }
    else { 
        $Global:NVIDIADevices1 = "none"; 
        $Global:AMDDevices1 = "none" 
    }
    if ([string]$global:Config.Params.GPUDevices2) { $Global:NVIDIADevices2 = [String]$global:Config.Params.GPUDevices2 -replace " ", "," } else { $Global:NVIDIADevices2 = "none" }
    if ([string]$global:Config.Params.GPUDevices3) { $Global:NVIDIADevices3 = [String]$global:Config.Params.GPUDevices3 -replace " ", "," } else { $Global:NVIDIADevices3 = "none" }

    $Global:GCount = Get-Content ".\build\txt\devicelist.txt" | ConvertFrom-Json
    $Global:NVIDIATypes = @(); if ($global:Config.Params.Type -like "*NVIDIA*") { $global:Config.Params.Type | Where { $_ -like "*NVIDIA*" } | % { $Global:NVIDIATypes += $_ } }
    $Global:CPUTypes = @(); if ($global:Config.Params.Type -like "*CPU*") { $global:Config.Params.Type | Where { $_ -like "*CPU*" } | % { $Global:CPUTypes += $_ } }
    $Global:AMDTypes = @(); if ($global:Config.Params.Type -like "*AMD*") { $global:Config.Params.Type | Where { $_ -like "*AMD*" } | % { $Global:AMDTypes += $_ } }
}

#Get Miner Config Files
Import-Module "$global:Startup\getconfigs.psm1"
if ($global:Config.Params.Type -like "*CPU*") { $Global:cpu = get-minerfiles -Types "CPU" }
if ($global:Config.Params.Type -like "*NVIDIA*") { $Global:nvidia = get-minerfiles -Types "NVIDIA" -Cudas $global:Config.Params.Cuda }
if ($global:Config.Params.Type -like "*AMD*") { $Global:amd = get-minerfiles -Types "AMD" }

##Start New Agent
write-Log "Starting New Background Agent" -ForegroundColor Cyan
if ($global:Config.Params.Platform -eq "windows") { Start-Background }
elseif ($global:Config.Params.Platform -eq "linux") { Start-Process ".\build\bash\background.sh" -ArgumentList "background $($global:Dir)" -Wait }
Remove-Module "getconfigs"

Add-LogErrors

##############################################################################
#######                      End Startup                                ######
##############################################################################

While ($true) {

    do {

        ##############################################################################
        #######                     PHASE 1: Build                              ######
        ##############################################################################

        ## Check to see if wallet is present:
        if (-not $global:Config.Params.Wallet1) { 
            write-Log "missing wallet1 argument, exiting in 5 seconds" -ForeGroundColor Red; 
            Start-Sleep -S 5; 
            exit 
        }


        ## Load Miner Configurations
        $Global:ASICTypes = @(); $global:ASICS = @{ }
        Import-Module -Name "$Build\configs.psm1"
        Get-MinerConfigs
        $global:Config.Pool_Algos = Get-Content ".\config\pools\pool-algos.json" | ConvertFrom-Json
        Add-ASICS
        $global:oc_default = Get-Content ".\config\oc\oc-defaults.json" | ConvertFrom-Json
        $global:oc_algos = Get-Content ".\config\oc\oc-algos.json" | ConvertFrom-Json
        Remove-Module -Name "configs"


        ##Manage Pool Bans
        Import-Module "$Build\poolbans.psm1"
        Start-PoolBans
        $global:All_AltWallets = $null
        $SWARMAlgorithm = $Config.Params.Algorithm;
        Remove-Module -Name "poolbans"


        ## Handle Wallet Stuff / Bans
        Import-Module "$Build\wallets.psm1"
        Set-Donation
        Get-Wallets
        $global:Algorithm = @()
        $global:BanHammer = @()
        . .\build\powershell\bans.ps1 "add" $global:Config.Params.Bans "process" | Out-Null
        Add-Algorithms
        Set-Donation
        if ($global:Config.Params.Coin.Count -eq 1 -and $global:Config.Params.Coin -ne "") { $global:Config.Params.Auto_Coin = "No" }
        Remove-Module "wallets"


        # Pricing and Clearing Timeouts 
        Import-Module "$Build\pricing.psm1"
        Get-Watts
        Get-Pricing
        Clear-Timeouts
        Remove-Module "pricing"


        ##############################################################################
        #######                         END PHASE 1                             ######
        ##############################################################################



        ##############################################################################
        #######                        PHASE 2: POOLS                           ######
        ##############################################################################

        ##Stats Is needed for remaining Phases
        #Import-Module -Name "$global:dir\build\powershell\stats.psm1"
        #mport-Module -Name "$global:dir\build\powershell\phasepool.psm1"

        ## Build Initial Pool Hash Tables
        $global:Coins = $false
        $global:FeeTable = @{ }
        $global:divisortable = @{ }
        $global:SingleMode = $false
        $global:AlgoPools = $Null
        $global:CoinPools = $null


        Import-Module -Name "$Pool\initial.psm1"
        Import-Module -Name "$global\stats.psm1"
        Get-PoolTables
        Remove-BanHashrates
        $global:Miner_HashTable = Get-MinerHashTable
        Remove-Module -Name "initial"


        ##Get Algorithm Pools
        Import-Module -Name "$Pool\gather.psm1"
        Get-AlgoPools
        Get-CoinPools
        Remove-Module -Name "gather"

        $global:FeeTable = $Null
        $global:DivisorTable = $Null

        ##############################################################################
        #######                         END PHASE 2                             ######
        ##############################################################################


        
        ##############################################################################
        #######                        PHASE 3: Miners                          ######
        ##############################################################################

        $global:AlgoMiners = $Null
        $global:CoinMiners = $Null
        $Global:Miners = New-Object System.Collections.ArrayList
        

        Import-Module -Name "$global:MinerP\gather.psm1"
        Get-AlgoMiners
        Get-CoinMiners
        Remove-Module -Name "gather"
        $global:Miner_HashTable = $Null


        if ($Global:Miners.Count -eq 0) {
            $WebMessage = "No Miners Found! Check Arguments/Net Connection"
            Send-Warning $WebMessage
            start-sleep $global:Config.Params.Interval;
            continue  
        }


        ## If Volume is specified, gather pool vol.
        ## Sort The Miners
        ## Add Switching_Threshold
        Import-Module -Name "$global:MinerP\sorting.psm1"
        if ($global:Config.Params.Volume -eq "Yes") { Get-Volume }
        $CutMiners = Start-MinerReduction -SortMiners $Global:Miners -WattCalc $global:WattEX
        $CutMiners | ForEach-Object { $Global:Miners.Remove($_) } | Out-Null;
        $CuTminers = $Null
        $Global:Miners | ForEach-Object { $_.Symbol = $_.Symbol -replace "-Algo", ""; $_.Symbol = $_.Symbol -replace "-Coin", "" }
        start-minersorting -SortMiners $Global:Miners -WattCalc $global:WattEX
        $global:Pool_Hashrates = @{ }
        Add-SwitchingThreshold
        Remove-Module -Name "sorting"


        ## Remove Bad Miners
        ## Get The Best Miners|
        Import-Module -Name "$global:MinerP\choose.psm1"
        Remove-BadMiners
        $global:Miners_Combo = Get-BestMiners
        $global:bestminers_combo = Get-Conservative
        Remove-Module "choose"

        ##Write On Screen Best Choice  
        $BestMiners_Selected = $global:bestminers_combo.Symbol
        $BestPool_Selected = $global:bestminers_combo.MinerPool
        write-Log "Most Ideal Choice Is $($BestMiners_Selected) on $($BestPool_Selected)" -foregroundcolor green
        
        ##############################################################################
        #######                        End Phase 3                             ######
        ############################################################################## 

        ##############################################################################
        #######                        Phase 4: Control                         ######
        ##############################################################################
        
        ## Build the Current Active Miners
        $global:Restart = $false
        $global:NoMiners = $false
        $ConserveMessage = @()
        $Global:BestActiveMIners = @()


        ## Add New Miners- Download if neccessary
        Import-Module -Name "$global:Control\initial.psm1"
        Start-MinerDownloads
        Get-ActiveMiners $global:bestminers_combo
        Get-BestActiveMiners
        Remove-Module -Name "initial"


        ##Modify Princing For API / Screen
        ##Stop Miners if Conserver -Yes flaq qualifies
        Import-Module -Name "$global:Control\modify.psm1"
        Get-ActivePricing
        $PreviousMinerPorts = @{AMD1 = ""; NVIDIA1 = ""; NVIDIA2 = ""; NVIDIA3 = ""; CPU = "" }
        $global:ClearedOC = $false; $global:ClearedHash = $false; $Global:HiveOCTune = $false
        $global:NoMiners = $false;
        Remove-Module -Name "modify"


        ##Start / Stop / Restart Miners
        ##Handle OC
        Import-Module "$global:Control\run.psm1"
        Stop-ActiveMiners
        Start-NewMiners -Reason "Launch"
        Remove-Module -Name "run"


        Import-Module -Name "$global:Control\notify.psm1"
        $global:BenchmarkMode = $false
        $global:BestActiveMiners | ForEach-Object {
            $StatAlgo = $_.Algo -replace "`_","`-"        
            if (-not (Test-Path ".\stats\$($_.Name)_$($StatAlgo)_hashrate.txt")) { 
                $global:BenchmarkMode = $true; 
            }
        }
        $global:SWARM_IT = $false
        $global:MinerInterval = $null
        $global:MinerStatInt = $Null
        $ModeCheck = 0
        Get-LaunchNotification
        Get-Interval
        ##Get Shares
        $global:Share_Table = @{ }
        write-Log "Getting Coin Tracking From Pool" -foregroundColor Cyan
        if ($global:Config.params.Track_Shares -eq "Yes") { Get-CoinShares }
        Remove-Module -Name "notify"

        ##############################################################################
        #######                        End Phase 4                              ######
        ##############################################################################


        ##############################################################################
        #######                        Phase 5: Run                             ######
        ##############################################################################

        Import-Module -Name "$global:Run\initial.psm1"
        Import-Module -Name "$global:global\hashrates.psm1"
        Get-ScreenName
        $Global:Miners | ConvertTo-Json -Depth 4 | Set-Content ".\build\txt\profittable.txt"
        Clear-Commands
        Get-Date | Out-File ".\build\txt\minerstats.txt"
        Get-Date | Out-File ".\build\txt\charts.txt"
        Get-MinerStatus | Out-File ".\build\txt\minerstats.txt" -Append
        Get-Charts | Out-File ".\build\txt\charts.txt" -Append
        Get-ExchangeRate
        Remove-Module -Name "initial"


        Import-Module -name "$global:Run\commands.psm1"
        Get-PriceMessage
        Get-Commands
        $Global:Miners = $Null
        Get-Logo
        Update-Logging
        Get-Date | Out-File ".\build\txt\mineractive.txt"
        Get-MinerActive | Out-File ".\build\txt\mineractive.txt" -Append
        Remove-Module -Name "commands"


        Import-Module -name "$global:Run\loop.psm1"
        Start-MinerLoop
        Remove-Module -name "loop"

        
        ##############################################################################
        #######                        End Phase 5                              ######
        ##############################################################################

        ##############################################################################
        #######                       Phase 6: Benchmark                        ######
        ##############################################################################

        Import-Module -Name "$global:benchmark\attempt.psm1"

        ## Start WattOMeter function
        if ($global:Config.Params.WattOMeter -eq "Yes") { Start-WattOMeter }
        $global:ActiveSymbol = @()

        ##Try To Benchmark
        Start-Benchmark

        ##############################################################################
        #######                       End Phase 6                               ######
        ##############################################################################

        Remove-Module -Name "hashrates"
        Remove-Module -Name "stats"
        
    }until($Error.Count -gt 0)
    Add-LogErrors
    continue;
}
