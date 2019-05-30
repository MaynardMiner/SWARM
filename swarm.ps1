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
$Global:config = [hashtable]::Synchronized(@{})

##filepath dir
$Global:Config.Add("var",@{})
$Global:Config.var.Add("dir",(Split-Path $script:MyInvocation.MyCommand.Path))

$env:Path += ";$($global:Config.var.dir)\build\cmd"
try { Get-ChildItem . -Recurse | Unblock-File } catch { }

## Exclusion Windows Defender
try { 
    if ((Get-MpPreference).ExclusionPath -notcontains (Convert-Path .)) { 
        Start-Process "powershell" -Verb runAs -ArgumentList "Add-MpPreference -ExclusionPath `'$($global:Config.var.Dir)`'" -WindowStyle Minimized 
    } 
}
catch { }

## Set Firewall Rule
try { 
    $Net = Get-NetFireWallRule 
    if ($Net) {
        try { 
            if ( -not ( $Net | Where { $_.DisplayName -like "*swarm.ps1*" } ) ) { 
                New-NetFirewallRule -DisplayName 'swarm.ps1' -Direction Inbound -Program "$($global:Config.var.dir)\swarm.ps1" -Action Allow | Out-Null
            } 
        }
        catch { }
    }
}
catch { }
$Net = $Null

if ($IsWindows) {
    Start-Process "powershell" -ArgumentList "Set-Location `'$($global:Config.var.dir)`'; .\build\powershell\scripts\icon.ps1 `'$($global:Config.var.dir)\build\apps\SWARM.ico`'" -NoNewWindow
}

## Debug Mode- Allow you to run with last known arguments or arguments.json.
$Global:Config.var.Add("debug",$false)
if ($global:config.var.debug -eq $True) {
    Start-Transcript ".\logs\debug.log"
    if (($IsWindows)) { Set-ExecutionPolicy Bypass -Scope Process }
}

## Load Modules
$global:Config.var.Add("startup","$($global:Config.var.dir)\build\powershell\startup")
$global:Config.var.Add("web","$($global:Config.var.dir)\build\powershell\web")
$global:Config.var.Add("global","$($global:Config.var.dir)\build\powershell\global")
$global:Config.var.Add("build","$($global:Config.var.dir)\build\powershell\build")
$global:Config.var.Add("pool","$($global:Config.var.dir)\build\powershell\pool")
$global:Config.var.Add("miner","$($global:Config.var.dir)\build\powershell\miner")
$global:Config.var.Add("control","$($global:Config.var.dir)\build\powershell\control")
$global:Config.var.Add("run","$($global:Config.var.dir)\build\powershell\run")
$global:Config.var.Add("benchmark","$($global:Config.var.dir)\build\powershell\benchmark")
$p = [Environment]::GetEnvironmentVariable("PSModulePath")
if ($P -notlike "*$($global:Config.var.dir)\build\powershell*") {
    $P += ";$($global:Config.var.startup)";
    $P += ";$($global:Config.var.web)";
    $P += ";$($global:Config.var.global)";
    $P += ";$($global:Config.var.build)";
    $P += ";$($global:Config.var.pool)";
    $P += ";$($global:Config.var.miner)";
    $P += ";$($global:Config.var.control)";
    $P += ";$($global:Config.var.run)";
    $P += ";$($global:Config.var.benchmark)";
    [Environment]::SetEnvironmentVariable("PSModulePath", $p)
    Write-Host "Modules Are Loaded" -ForegroundColor Green
}

Import-Module -Name "$($global:Config.var.global)\modules.psm1" -Scope Global
$global:Modules = @()

## Date Bug
$global:cultureENUS = New-Object System.Globalization.CultureInfo("en-US")

## Startup Modules
Import-Module "$($global:Config.var.global)\include.psm1" -Scope Global

##Insert Single Modules Here

## Get Parameters
Add-Module "$($global:Config.var.startup)\parameters.psm1"
Get-Parameters

## Crash Reporting
Add-Module "$($global:Config.var.startup)\crashreport.psm1"
Start-CrashReporting

## Start The Log
Add-Module "$($global:Config.var.startup)\startlog.psm1"
$global:Config.var.dir | Set-Content ".\build\bash\dir.sh";
$global:LogNum = 1;
$global:logname = $null
start-log -Number $global:LogNum;

## Initiate Update Check
Add-Module "$($global:Config.var.startup)\remoteagent.psm1"
if ($global:Config.Params.Platform -eq "Windows" -or $global:Config.Params.Update -eq "Yes") { 
    Get-Version
    start-update -Update $Getupdates
}
if ($global:Config.Params.Platform -eq "windows") { 
    Add-Module "$($global:Config.var.startup)\getconfigs.psm1"
    Start-AgentCheck 
}

## create debug/command folder
if (-not (Test-Path ".\build\txt")) { New-Item -Path ".\build" -Name "txt" -ItemType "directory" | Out-Null }

##Start Data Collection
Add-Module "$($global:Config.var.startup)\datafiles.psm1"

$AllProtocols = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12' 
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols

Get-DateFiles
Clear-Stats
Get-ArgNotice
Set-NewType
if ($global:Config.Params.SWARM_Mode -eq "Yes") {
    write-Log "Sycronizing Time Through Nist" -ForegroundColor Yellow
    $Sync = Get-Nist
    try {
        Set-Date $Sync -ErrorAction Stop 
    }
    catch { 
        write-Log "Failed to syncronize time- Are you root/administrator?" -ForegroundColor red; 
        Start-Sleep -S 5 
    }
}
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
if ($Global:Config.Params.Farm_Hash -ne "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" -or (Test-Path "/hive/miners") ) { $global:NetModules += ".\build\api\hiveos"; $global:WebSites += "HiveOS" }
#if ($Config.Params.Swarm_Hash -eq "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx") { $global:NetModules += ".\build\api\SWARM"; $global:WebSites += "SWARM" }

## Initialize
$global:GPU_Count = $null
$global:BusData = $null
switch ($global:Config.params.Platform) {
    "linux" {
        Add-Module "$($global:Config.var.startup)\linuxconfig.psm1"
        Add-Module "$($global:Config.var.startup)\sexyunixlogo.psm1"
        Start-LinuxConfig 
    }
    "windows" { 
        Add-Module "$($global:Config.var.startup)\winconfig.psm1"
        Add-Module "$($global:Config.var.startup)\sexywinlogo.psm1"
        Start-WindowsConfig 
    }
}

## Determine AMD platform
if ($global:Config.Params.Type -like "*AMD*") {
    if ([string]$global:Config.Params.CLPlatform) { $Global:AMDPlatform = [string]$global:Config.Params.CLPlatform }
    else {
        Add-Module "$($global:Config.var.startup)\cl.psm1"
        [string]$global:AMDPlatform = get-AMDPlatform
        write-Log "AMD OpenCL Platform is $Global:AMDPlatform"
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


##Start New Agent
Add-Module "$($global:Config.var.startup)\getconfigs.psm1"
write-Log "Starting New Background Agent" -ForegroundColor Cyan
if ($global:Config.Params.Platform -eq "windows") { Start-Background }
elseif ($global:Config.Params.Platform -eq "linux") { Start-Process ".\build\bash\background.sh" -ArgumentList "background $($($global:Config.var.dir))" -Wait }

Add-LogErrors
Remove-Modules

$global:BusData = $Null
$global:CPUCount = $Null
$global:GPUCount = $Null
$Version = $Null
$global:GPU_Count = $Null
$Device_Count = $Null 

##############################################################################
#######                      End Startup                                ######
##############################################################################

While ($true) {

    do {

        ##Insert Looping Modules Here

        ##############################################################################
        #######                     PHASE 1: Build                              ######
        ##############################################################################
        $global:Algorithm = @()
        $global:BanHammer = @()
        $Global:ASICTypes = @(); 
        $global:ASICS = @{ }
        $global:All_AltWallets = $null
        $global:SWARMAlgorithm = $Config.Params.Algorithm

        ##Build Modules
        Add-Module "$($global:Config.var.global)\include.psm1"
        Add-Module "$($global:Config.var.global)\stats.psm1"

        #Get Miner Config Files
        Add-Module "$($global:Config.var.build)\miners.psm1"
        if ($global:Config.Params.Type -like "*CPU*") { $Global:cpu = get-minerfiles -Types "CPU" }
        if ($global:Config.Params.Type -like "*NVIDIA*") { $Global:nvidia = get-minerfiles -Types "NVIDIA" -Cudas $global:Config.Params.Cuda }
        if ($global:Config.Params.Type -like "*AMD*") { $Global:amd = get-minerfiles -Types "AMD" }

        ## Check to see if wallet is present:
        if (-not $global:Config.Params.Wallet1) { 
            write-Log "missing wallet1 argument, exiting in 5 seconds" -ForeGroundColor Red; 
            Start-Sleep -S 5; 
            exit 
        }

        ## Load Miner Configurations
        Add-Module "$($global:Config.var.build)\configs.psm1"
        Get-MinerConfigs
        $global:Config.Pool_Algos = Get-Content ".\config\pools\pool-algos.json" | ConvertFrom-Json
        Add-ASICS
        $global:oc_default = Get-Content ".\config\oc\oc-defaults.json" | ConvertFrom-Json
        $global:oc_algos = Get-Content ".\config\oc\oc-algos.json" | ConvertFrom-Json

        ##Manage Pool Bans
        Add-Module "$($global:Config.var.build)\poolbans.psm1"
        Start-PoolBans


        ## Handle Wallet Stuff / Bans
        Add-Module "$($global:Config.var.build)\wallets.psm1"
        Set-Donation
        Get-Wallets
        . .\build\powershell\scripts\bans.ps1 "add" $global:Config.Params.Bans "process" | Out-Null
        Add-Algorithms
        Set-Donation
        if ($global:Config.Params.Coin.Count -eq 1 -and $global:Config.Params.Coin -ne "") { $global:Config.Params.Auto_Coin = "No" }

        # Pricing and Clearing Timeouts 
        Add-Module "$($global:Config.var.build)\pricing.psm1"
        Get-Watts
        Get-Pricing
        Clear-Timeouts

        Remove-Modules
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
        [GC]::Collect()

        ##############################################################################
        #######                         END PHASE 1                             ######
        ##############################################################################



        ##############################################################################
        #######                        PHASE 2: POOLS                           ######
        ##############################################################################

        ##Pool Modules
        Add-Module "$($global:Config.var.global)\include.psm1"
        Add-Module "$($global:Config.var.global)\stats.psm1"

        ## Build Initial Pool Hash Tables
        $global:Coins = $false
        $global:FeeTable = @{ }
        $global:divisortable = @{ }
        $global:SingleMode = $false
        $global:AlgoPools = $Null
        $global:CoinPools = $null
        $global:Pool_Hashrates = @{ }


        Add-Module "$($global:Config.var.pool)\initial.psm1"
        Get-PoolTables
        Remove-BanHashrates
        $global:Miner_HashTable = Get-MinerHashTable
        ##Add Global Modules - They Get Removed in Above Function
        Remove-Modules
        Import-Module -Name "$($global:Config.var.global)\include.psm1" -Scope Global
        Add-Module "$($global:Config.var.global)\stats.psm1"

        ##Get Algorithm Pools
        Add-Module "$($global:Config.var.pool)\gather.psm1"
        Get-AlgoPools
        Get-CoinPools
        Remove-Modules
        Clear-Variable -Name "FeeTable" -ErrorAction Ignore -Scope Global
        Clear-Variable -Name "divisortable" -ErrorAction Ignore -Scope Global
        Clear-Variable -Name "All_AltWallets" -ErrorAction Ignore -Scope Global
        Clear-Variable -Name "Wallets" -ErrorAction Ignore -Scope Global
		[GC]::Collect()

        ##############################################################################
        #######                         END PHASE 2                             ######
        ##############################################################################


        
        ##############################################################################
        #######                        PHASE 3: Miners                          ######
        ##############################################################################

        ##Miners Modules
        Add-Module "$($global:Config.var.global)\include.psm1"
        Add-Module "$($global:Config.var.global)\stats.psm1"

        $global:Miner_HashTable = $Null
        $Global:Miners = New-Object System.Collections.ArrayList

        ##Load The Miners
        Add-Module "$($global:Config.var.miner)\gather.psm1"
        Get-AlgoMiners
        Get-CoinMiners

        ##Send error if no miners found
        if ($Global:Miners.Count -eq 0) {
            $HiveMessage = "No Miners Found! Check Arguments/Net Connection"
            $HiveWarning = @{result = @{command = "timeout" } }
            if ($global:Websites) {
                $global:Websites | ForEach-Object {
                    $Sel = $_
                    try {
                        Add-Module "$($global:Config.var.web)\methods.psm1"
                        Get-WebModules $Sel
                        $SendToHive = Start-webcommand -command $HiveWarning -swarm_message $HiveMessage -Website "$($Sel)"
                    }
                    catch { Write-Log "WARNING: Failed To Notify $($Sel)" -ForeGroundColor Yellow } 
                    Remove-WebModules $sel
                }
            }
            Write-Log "$HiveMessage" -ForegroundColor Red
            start-sleep $global:Config.Params.Interval;
            continue  
        }

        ##Sort The Miners
        Add-Module "$($global:Config.var.miner)\sorting.psm1"
        if ($global:Config.Params.Volume -eq "Yes") { Get-Volume }
        $CutMiners = Start-MinerReduction -SortMiners $Global:Miners -WattCalc $global:WattEX
        $CutMiners | ForEach-Object { $Global:Miners.Remove($_) } | Out-Null;
        $Global:Miners | ForEach-Object { $_.Symbol = $_.Symbol -replace "-Algo", ""; $_.Symbol = $_.Symbol -replace "-Coin", "" }
        start-minersorting -SortMiners $Global:Miners -WattCalc $global:WattEX
        Add-SwitchingThreshold

        ##Choose The Best Miners
        Add-Module "$($global:Config.var.miner)\choose.psm1"
        Remove-BadMiners
        $global:Miners_Combo = Get-BestMiners
        $global:bestminers_combo = Get-Conservative
        $BestMiners_Selected = $global:bestminers_combo.Symbol
        $BestPool_Selected = $global:bestminers_combo.MinerPool
        write-Log "Most Ideal Choice Is $($BestMiners_Selected) on $($BestPool_Selected)" -foregroundcolor green

        Remove-Modules
        $global:Algorithm = $null
        $CutMiners = $null
        $global:Miners_Combo = $null
        $BestMiners_Selected = $null
        $BestPool_Selected = $null
        $Global:amd = $null
        $Global:nvidia = $null
        $Global:cpu = $null
        $global:Pool_Hashrates = $null
        $global:Miner_HashTable = $null
        $global:Watts = $null
		[GC]::Collect()

        ##############################################################################
        #######                        End Phase 3                             ######
        ############################################################################## 

        ##############################################################################
        #######                        Phase 4: Control                         ######
        ##############################################################################

        ## Build the Current Active Miners
        $global:Restart = $false
        $global:NoMiners = $false
        $Global:BestActiveMIners = @()
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

        Add-Module "$($global:Config.var.global)\include.psm1"
        Add-Module "$($global:Config.var.global)\stats.psm1"
        if ($Global:Config.params.Type -like "*ASIC*") { Add-Module "$($global:Config.var.global)\hashrates.psm1" }
        Add-Module "$($global:Config.var.control)\config.psm1"

        ## Add New Miners- Download if neccessary
        ## Ammend Their Pricing
        Add-Module "$($global:Config.var.control)\initial.psm1"
        Start-MinerDownloads
        Get-ActiveMiners $global:bestminers_combo
        Get-BestActiveMiners
        Get-ActivePricing

        ##Start / Stop / Restart Miners
        ##Handle OC
        Add-Module "$($global:Config.var.control)\run.psm1"
        Add-Module "$($global:Config.var.control)\launchcode.psm1"
        Add-Module "$($global:Config.var.control)\config.psm1"
        Stop-ActiveMiners
        Start-NewMiners -Reason "Launch"

        ##Determing Interval
        Add-Module "$($global:Config.var.control)\notify.psm1"
        Get-LaunchNotification
        Get-Interval
        ##Get Shares
        write-Log "Getting Coin Tracking From Pool" -foregroundColor Cyan
        if ($global:Config.params.Track_Shares -eq "Yes") { Get-CoinShares }

        Remove-Modules
        $global:oc_algos = $null
        $global:oc_default = $null
        $global:PreviousMinerPorts = $null
        $global:Restart = $null
        $global:NoMiners = $null
        $global:ClearedOC = $null
        $Global:HiveOCTune = $null
		[GC]::Collect()

        ##############################################################################
        #######                        End Phase 4                              ######
        ##############################################################################


        ##############################################################################
        #######                        Phase 5: Run                             ######
        #############################################################################


        Add-Module "$($global:Config.var.global)\include.psm1"
        Add-Module "$($global:Config.var.global)\stats.psm1"
        Add-Module "$($global:Config.var.global)\hashrates.psm1"

        ## Clear Old Commands Data
        Add-Module "$($global:Config.var.run)\initial.psm1"
        Get-ExchangeRate
        Get-ScreenName
        $Global:Miners | ConvertTo-Json -Depth 4 | Set-Content ".\build\txt\profittable.txt"
        Clear-Commands
        Get-Date | Out-File ".\build\txt\minerstats.txt"
        Get-Date | Out-File ".\build\txt\charts.txt"
        Get-MinerStatus | Out-File ".\build\txt\minerstats.txt" -Append
        Get-Charts | Out-File ".\build\txt\charts.txt" -Append

        ## Refreshing Pricing Data
        Add-Module "$($global:Config.var.run)\commands.psm1"
        Get-PriceMessage
        Get-Commands
        $Global:Miners.Clear()
        Get-Logo
        Update-Logging
        Get-Date | Out-File ".\build\txt\mineractive.txt"
        Get-MinerActive | Out-File ".\build\txt\mineractive.txt" -Append

        ##Start SWARM Loop
        Add-Module "$($global:Config.var.run)\loop.psm1"
        Start-MinerLoop

        Remove-Modules
        [GC]::Collect()

        ##############################################################################
        #######                        End Phase 5                              ######
        ##############################################################################

        ##############################################################################
        #######                       Phase 6: Benchmark                        ######
        ##############################################################################

        Add-Module "$($global:Config.var.global)\include.psm1"
        Add-Module "$($global:Config.var.global)\stats.psm1"
        Add-Module "$($global:Config.var.global)\gpu.psm1"
        Add-Module "$($global:Config.var.global)\hashrates.psm1"
        Add-Module "$($global:Config.var.benchmark)\attempt.psm1"

        ## Start WattOMeter function
        if ($global:Config.Params.WattOMeter -eq "Yes") { Start-WattOMeter }
        $global:ActiveSymbol = @()

        ##Try To Benchmark
        Start-Benchmark

        ##############################################################################
        #######                       End Phase 6                               ######
        ##############################################################################
        Remove-Modules
		[GC]::Collect()

    }until($Error.Count -gt 0)
    Import-Module "$($global:Config.var.global)\include.psm1" -Scope Global
    Add-LogErrors
    Remove-Modules
    continue;
}
