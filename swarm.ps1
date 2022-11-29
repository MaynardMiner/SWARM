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

## any windows version below 10 invoke full screen mode.
if ($isWindows) {
    $os_string = "$([System.Environment]::OSVersion.Version)".split(".") | Select-Object -First 1
    if ([int]$os_string -lt 10) {
        invoke-expression "mode 800"
    }
}

## Set Current Path
$Global:config = [hashtable]::Synchronized(@{ })
[cultureinfo]::CurrentCulture = 'en-US'
$Global:Config.Add("vars", @{ })
$Global:Config.vars.Add( "dir", (Split-Path $script:MyInvocation.MyCommand.Path) )
$Global:Config.vars.dir = $Global:Config.vars.dir -replace "/var/tmp", "/root"
Set-Location $Global:Config.vars.dir
if (-not (test-path ".\debug")) { New-Item -Path "debug" -ItemType Directory | Out-Null }
$Global:Version = (Get-Content ".\h-manifest.conf" | ConvertFrom-StringData).CUSTOM_VERSION;


## SWARM will log miners so users can review since they are happening in different screens.
## Some miners have spaces in the directory path like "/root/my directory/SWARM" will cause
## issues when using their argument -log /root/my directory/SWARM. This cannot be controlled,
## so a error-like warning is notated as a result.
if ($GLobal:Config.vars.dir -like "* *") {
    Write-Host "Warning: Detected File Path To Be $($Global:Config.vars.dir)" -ForegroundColor Red
    Write-Host "Because there is a space within a parent directory," -ForegroundColor Red
    Write-Host "This will cause certain logs and miners to not start." -ForegroundColor Red
    Write-Host "Due to SWARM attempting to set logging arguments in miners." -ForegroundColor Red
    Write-Host "If you would like to use all features of SWARM, do not place" -ForegroundColor Red
    Write-Host "SWARM folder in a parent directory that contains spaces." -ForegroundColor Red
    Write-Host "Miner anti-debugging and poor miner argument parsing/development make this a problem." -ForegroundColor Red
    Start-Sleep -S 10
}

if ($IsWindows) {
    ## SWARM will kill old miners if they are still running in windows- Sometimes they will
    ## ignore the original Kill app commmand on exit. It will also kill SWARM if there is an
    ## an older version running.
    Write-Host "Stopping Any Previous SWARM Instances..."
    $ID = ".\build\pid\miner_pid.txt"
    if (Test-Path $ID) { 
        $Get_SWARM = Get-Content $ID 
        if ($Get_SWARM) { 
            $SWARMID = Get-Process | Where-Object id -eq $Agent 
            if ($SWARMID) {
                $SWARMID.Kill()
            }
        }
    }
    ## Fix weird PATH issues for commands
    ## Ensure PATH is set (The environment variable)
    ## This was a problem for some users using weird mining setups
    $restart = $false
    $Target1 = [System.EnvironmentVariableTarget]::Machine
    $Target2 = [System.EnvironmentVariableTarget]::Process
    $Path = [System.Environment]::GetEnvironmentVariable('Path', $Target1)
    $Path_List = $Path.Split(';')
    ## Remove all old SWARM Paths and add current
    if ("$($Global:Config.vars.dir)\build\cmd" -notin $Path_List) {
        Write-Host "Please Wait- Setting Environment Variables..." -ForegroundColor Green
        $Path_List = $Path_List | Where-Object { $_ -notlike "*SWARM*" }
        $Path_List += "$($Global:Config.vars.dir)\build\cmd"
        $New_PATH = $Path_List -join (';')    
        [System.Environment]::SetEnvironmentVariable('Path', $New_PATH, $Target1)
        [System.Environment]::SetEnvironmentVariable('Path', $New_PATH, $Target2)
        $restart = $true
    }
    ## Set Path
    if ($Env:SWARM_DIR -ne $Global:Config.vars.dir) {
        $restart = $true
        [System.Environment]::SetEnvironmentVariable('SWARM_DIR', "$($Global:Config.vars.dir)", $Target1)
        [System.Environment]::SetEnvironmentVariable('SWARM_DIR', "$($Global:Config.vars.dir)", $Target2)
    }
    ## By stopping explorer, it restarts retroactively with path refreshed
    ## for commands.
    ## Now set env variables for process- Just in case.
    if ($restart -eq $true) {
        Stop-Process -ProcessName explorer
    }
}

## Check Powershell version. Output warning.
## In most cases it will not cause issue, but notating they
## may be using a version that will.
if ($PSVersionTable.PSVersion -ne "7.2.7") {
    Write-Host "WARNING: Powershell Core Version is $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    Write-Host "Currently supported version for SWARM is 7.2.7" -ForegroundColor Yellow
    Write-Host "SWARM will continue anyways- It may cause issues." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Link for Powershell:" -ForegroundColor Yellow
    Write-Host "https://github.com/PowerShell/PowerShell/releases/tag/v7.2.7" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Windows: Microsoft Visual C++ Redistributable for Visual Studio (2012) (2013) (2015,2017 and 2019)" -ForegroundColor Yellow
    Write-Host "Link For download:" -ForegroundColor Yellow
    Write-Host "https://support.microsoft.com/en-us/help/2977003/the-latest-supported-visual-c-downloads" -ForegroundColor Yellow
    ## Create a pause in case window is scrolling too fast.
    Start-Sleep -S 5
}

## Install AngleParse For Future Implementation
if ($null -eq (Get-InstalledModule | Where-Object { $_.Name -eq "AngleParse" })) {
    Install-Package AngleParse -force
}


##filepath dir
. .\build\powershell\global\modules.ps1
$env:Path += ";$($(vars).dir)\build\cmd"

## Window Security Items
## This attempts to prevent Windows Defender from trying to 
## stop apps from running. This is no gurantee it will actually
## work, because Windows.
if ($IsWindows) {
    $Host.UI.RawUI.BackgroundColor = 'Black'
    $Host.UI.RawUI.ForegroundColor = 'White'
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
                if ( -not ( $Net | Where-Object { $_.DisplayName -like "*swarm.ps1*" } ) ) { 
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
    ## Add .dll
    Add-Type -Path ".\build\apps\launchcode.dll"
}

## This loads MegaAPI into SWARM, for miner downloads on Mega.nz
Add-Type -Path ".\build\apps\device\MegaApiClient.dll"

## Debug Mode- Allow you to run with last known arguments or commandline.json.
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
$(vars).Add("api", "$($(vars).dir)\build\api")

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
    $P += ";$($(vars).api)"
    [Environment]::SetEnvironmentVariable("PSModulePath", $p)
    Write-Host "Modules Are Loaded" -ForegroundColor Green
}
Remove-Variable -name P -ErrorAction Ignore

$(vars).Add("Modules", @())

## Get Parameters
Global:Add-Module "$($(vars).startup)\parameters.psm1"
Global:Get-Parameters
$(arg).TCP_Port | Out-File ".\debug\port.txt"

##Insert Single Modules Here

## Startup Modules
Import-Module "$($(vars).global)\stats.psm1" -Scope Global
Import-Module "$($(vars).global)\hashrates.psm1" -Scope Global
Import-Module "$($(vars).global)\gpu.psm1" -Scope Global
. .\build\powershell\global\classes.ps1

if ($IsWindows -and [string]$Global:config.hive_params.MINER_DELAY -ne "") {
    Write-Host "Miner Delay Specified- Sleeping for $($Global:config.hive_params.MINER_DELAY)"
    $Sleep = [Double]$Global:config.hive_params.MINER_DELAY
    Start-Sleep -S $Sleep
    Remove-Variable -Name Sleep -ErrorAction Ignore
}

## Start The Log
if (-not (Test-Path "logs")) { New-Item "logs" -ItemType "directory" | Out-Null; Start-Sleep -S 1 }
$($(vars).dir) | Set-Content ".\build\bash\dir.sh";
$Global:log_params = [hashtable]::Synchronized(@{ })
$Global:log_params.Add("lognum", 0)
$global:log_params.Add("logname", (Join-Path $($(vars).dir) "logs\swarm__$(Get-Date -Format "HH_mm__dd__MM__yyyy").log"))
$Global:log_params.Add( "dir", (Split-Path $script:MyInvocation.MyCommand.Path) )
log "Logging has started- Logfile is $($global:log_params.logname)";

$start = $true
While ($start) {
    $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop;
    trap { 
        log "
$($_.Exception.Message)
$($_.InvocationInfo.PositionMessage)
    | Category: $($_.CategoryInfo.Category) | Activity: $($_.CategoryInfo.Activity)
    | Reason: $($_.CategoryInfo.Reason) 
    | Target Name: $($_.CategoryInfo.TargetName) | Target Type: $($_.CategoryInfo.TargetType)
" -ForeGround Red; 
        continue;
    }
    
    ## Initiate Update Check
    Global:Add-Module "$($(vars).startup)\remoteagent.psm1"
    if ($(arg).Update -eq "Yes") {
        Global:Start-Update
    }
    if ($(arg).Platform -eq "windows") { 
        Global:Add-Module "$($(vars).startup)\getconfigs.psm1"
        Global:Start-AgentCheck 
    }

    ## create debug/command folder
    if (-not (Test-Path ".\debug")) { New-Item -Path ".\build" -Name "txt" -ItemType "directory" | Out-Null }

    ##Start Data Collection
    Global:Add-Module "$($(vars).startup)\datafiles.psm1"

    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12' 

    Global:Get-DateFiles
    Global:Clear-Stats
    Global:Get-ArgNotice
    ## Make sure all -TYPE values are upper case.
    if ($(arg).Type.Count -gt 0) {
        $(arg).Type = $(arg).Type.ToUpper()
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
    $(vars).Add("types", @())
    $(vars).Add("threads", $null)
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
            if ([string]$(vars).AMDPlatform -eq "") {
                log "Failed to get OpenCL plaform. Use -CLPlatform." -ForegroundColor Red 
                log "Using default 0 for AMD OpenCL platform"
                $(vars).AMDPlatform = "0"
            }
        }
    }

    ##GPU-Count- Parse the hashtable between devices.
    if ($(arg).Type -like "*NVIDIA*" -or $(arg).Type -like "*AMD*" -or $(arg).Type -like "*CPU*") {
        if (Test-Path ".\debug\nvidiapower.txt") { Remove-Item ".\debug\nvidiapower.txt" -Force }
        if (Test-Path ".\debug\amdpower.txt") { Remove-Item ".\debug\amdpower.txt" -Force }
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

        $(vars).Add("GCount", (Get-Content ".\debug\devicelist.txt" | ConvertFrom-Json))
        $(vars).Add("NVIDIATypes", @()); if ($(arg).Type -like "*NVIDIA*") { $(arg).Type | Where-Object { $_ -like "*NVIDIA*" } | Foreach-Object { $(vars).NVIDIATypes += $_ } }
        $(vars).Add("CPUTypes", @()); if ($(arg).Type -like "*CPU*") { $(arg).Type | Where-Object { $_ -like "*CPU*" } | Foreach-Object { $(vars).CPUTypes += $_ } }
        $(vars).Add("AMDTypes", @()); if ($(arg).Type -like "*AMD*") { $(arg).Type | Where-Object { $_ -like "*AMD*" } | Foreach-Object { $(vars).AMDTypes += $_ } }
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

    ## Stop stray miners from previous run before loop
    Global:Add-Module "$($(vars).control)\stray.psm1"
    if ($IsWindows) { Global:Stop-StrayMiners -Startup }

    ##Get Optional Miners
    Global:Get-Optional
    Global:Remove-Modules
    $(vars).Remove("BusData")
    $(vars).Remove("GPU_Count")
    $(vars).Add("Check_Interval", (Get-Date).ToUniversalTime());
    $(vars).Add("switch", $true);
    $(vars).Add("ETH_exchange", 0);
    $(vars).Add("Load_Timer", (Get-Date).ToUniversalTime());
    $(vars).Add("Hashtable", @{});
    $(vars).Add("Downloads", $false);
    $(vars).Add("InConserve", $false);
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    [GC]::Collect()    

    if ($(arg).Throttle -eq 0) {
        $(arg).Throttle = ([Environment]::ProcessorCount + 1)
    }

    ## Make stats folder if it doesn't exist
    if (-not (test-path ".\stats")) {
        new-item "stats" -ItemType Directory | Out-Null
    }
    $start = $false;
}

##############################################################################
#######                      End Startup                                ######
##############################################################################
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop;

While ($true) {


    ## This will catch all errors, and log them as they happen since we are using
    ## our own custom logging.
    trap { 
        log "
$($_.Exception.Message)
$($_.InvocationInfo.PositionMessage)
    | Category: $($_.CategoryInfo.Category) | Activity: $($_.CategoryInfo.Activity)
    | Reason: $($_.CategoryInfo.Reason) 
    | Target Name: $($_.CategoryInfo.TargetName) | Target Type: $($_.CategoryInfo.TargetType)
    | Invocation: $($_.InvocationInfo | Format-List -Force | Out-String)
" -ForeGround Red; 
        continue;
    }
    
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


    ## SWARM runs its loop every 5 minutes. Miners will run for at least your time- If you took
    ## 3 minutes to calculate your data, and miner ran for only two minutes: SWARM will not switch off that miner and
    ## wait until at least 5 minutes runtime has happened.
    if (
        $(vars).switch -ne $true -and 
        [math]::Round(((Get-Date).ToUniversalTime() - $(vars).Check_Interval).TotalSeconds) -ge $(300)
    ) {
        $(vars).switch = $true
        $(vars).Check_Interval = (Get-Date).ToUniversalTime()
    }
    $(vars).Load_Timer = (Get-Date).ToUniversalTime()

    create Algorithm @()
    create GPUAlgorithm1 @()
    create GPUAlgorithm2 @()
    create GPUAlgorithm3 @()
    create CPUAlgorithm @()

    create BanHammer @()
    create ASICTypes @()
    create ASICS @{ }
    create All_AltWalltes $null
    $(vars).ETH_exchange = 0;

    Global:Add-Module "$($(vars).build)\logging.psm1"
    Global:Update-Log
    
    ##Insert Build Single Modules Here

    ##Insert Build Looping Modules Here

    #Get Miner Config Files
    Global:Add-Module "$($(vars).build)\miners.psm1"
    if ($(arg).Type -like "*CPU*") { create cpu (Global:Get-minerfiles -Types "CPU") }
    if ($(arg).Type -like "*NVIDIA*") { create nvidia (Global:Get-minerfiles -Types "NVIDIA") }
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
    $global:Config.Pool_Coins = [PSCustomObject]@{}
    if (test-path ".\config\pools\pool-coins.json") {
        $global:Config.Pool_Coins = Get-Content ".\config\pools\pool-coins.json" | ConvertFrom-Json;
    }
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
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    [GC]::Collect()    

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

    ##Insert Pools Single Modules Here

    ##Insert Pools Looping Modules Here

    Global:Add-Module "$($(vars).pool)\initial.psm1"
    Global:Get-PoolTables
    Global:Remove-BanHashrates
    if ($(vars).Options -eq 1) {
        . .\build\data\json.ps1
        Global:Get-Message
    }

    ##Add Global Modules - They Get Removed in Above Function
    Global:Remove-Modules
    . .\build\powershell\global\modules.ps1

    ##Get Algorithm Pools
    Global:Add-Module "$($(vars).pool)\gather.psm1"
    Global:Get-AlgoPools
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    [GC]::Collect()    
    Global:Get-CoinPools
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    [GC]::Collect()    
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
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    [GC]::Collect()    
    Global:Get-CoinMiners
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    [GC]::Collect()    

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
                    $null = Global:Start-webcommand -command $HiveWarning -swarm_message $HiveMessage -Website "$($Sel)"
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
        start-sleep -S ([math]::Round(((Get-Date).ToUniversalTime() - $(vars).Load_Timer).TotalSeconds))
        $(vars).switch = $true;

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
    $(vars).Miners | ForEach-Object { $_.Symbol = $_.Symbol -replace "-Algo", ""; $_.Symbol = $_.Symbol -replace "-Coins", "" }
    Global:Start-Sorting
    Global:Add-SwitchingThreshold

    ##Choose The Best Miners
    Global:Add-Module "$($(vars).miner)\choose.psm1"
    Global:Add-Module "$($(vars).miner)\conserve.psm1"
    Remove-BadMiners
    create Miners_Combo (Global:Get-BestMiners)
    $(vars).bestminers_combo = Global:Get-Conservative

    ## Trim miners for stats screen
    $CutMiners = Global:Start-MinerReduction	
    $CutMiners | ForEach-Object { $(vars).Miners.Remove($_) } | Out-Null;	
    Remove-Variable -Name CutMiners -ErrorAction Ignore	
    
    if ($(arg).Conserve -eq "Yes" -and $(vars).bestminers_combo.Count -eq 0) {
        log "Most Ideal Choice Is To Conserve" -foregroundcolor green
        if($(vars).InConserve -eq $false) {
            Global:Start-OCConserve
            $(vars).InConserve = $true
        }
    }
    else {
        log "Most Ideal Choice Is $($(vars).bestminers_combo.Symbol) on $($(vars).bestminers_combo.MinerPool)" -foregroundcolor green
        $(vars).InConserve = $false
    }

    ## Phase Clean up
    Global:Remove-Modules
    $(vars).Watts = $null
    remove CoinPools 
    remove AlgoPools 
    remove BanHammer
    remove ASICTypes
    remove Algorithm
    remove Coins
    remove SingleMode
    remove Miners_Combo
    remove Pool_HashRates
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    [GC]::Collect()    

    ##############################################################################
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

    ## Start / Stop / Restart Miners - Load Modules
    Global:Add-Module "$($(vars).control)\run.psm1"
    Global:Add-Module "$($(vars).control)\launchcode.psm1"
    Global:Add-Module "$($(vars).control)\config.psm1"
    Global:Add-Module "$($(vars).control)\stray.psm1"
    Global:Add-Module "$($(vars).control)\hugepage.psm1"

    ## Stop miners that need to be stopped
    Global:Stop-ActiveMiners
        
    ## Attack Stray Miners, if they are running
    if ($IsWindows) { Global:Stop-StrayMiners }

    ## Randomx Hugepages Before starting miners
    ## Not longer needed and may cause issues.
    ## Global:Start-HugePage_Check

    ## Start New Miners
    Global:Start-NewMiners -Reason "Launch"

    ## Determing Interval
    Global:Add-Module "$($(vars).control)\notify.psm1"
    Global:Get-LaunchNotification
    Global:Get-Interval

    ## Update Tagging
    Global:Add-Module "$($(vars).api)\hiveos\tagging.psm1"
    Global:Update-HiveTagging

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
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    [GC]::Collect()    

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
    $(vars).Miners | ConvertTo-Json -Depth 4 | Set-Content ".\debug\profittable.txt"
    Global:Clear-Commands
    Get-Date | Out-File ".\debug\minerstats.txt"
    Get-Date | Out-File ".\debug\charts.txt"
    Global:Get-Charts | Out-File ".\debug\charts.txt" -Append

    ## Refreshing Pricing Data
    Global:Add-Module "$($(vars).run)\commands.psm1"
    Global:Get-PriceMessage
    Global:Get-Commands
    remove Miners
    Global:Get-Logo
    Get-Date | Out-File ".\debug\mineractive.txt"
    Global:Get-MinerActive | Out-File ".\debug\mineractive.txt" -Append

    ##Start SWARM Loop
    Global:Add-Module "$($(vars).run)\loop.psm1"
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    [GC]::Collect() 
        
    ## Before starting miner loop- build data table for
    ## Hashrates and Power sampling.
    Global:Build-Hashtable
    Global:Start-MinerLoop

    $(vars).Add_Time = 0;

    ## Phase Clean up
    Global:Remove-Modules
    remove Thresholds
    remove SWARM_IT
    remove MinerInterval
    remove ASICS
    remove Share_Table
    remove ModeCheck
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    [GC]::Collect()    

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
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    [GC]::Collect()    

    ##############################################################################
    #######                       End Phase 6                               ######
    ##############################################################################

    ## Remaining Clean up
    remove all
    Global:Remove-Modules
    Get-Job -State Completed | Remove-Job
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    Clear-History

}