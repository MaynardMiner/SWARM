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
    [Parameter(Position = 0, Mandatory = $false)]
    [String]$argument1 = $null,
    [Parameter(Position = 1, Mandatory = $false)]
    [String]$argument2 = $null,
    [Parameter(Position = 2, Mandatory = $false)]
    [String]$argument3 = $null,
    [Parameter(Position = 3, Mandatory = $false)]
    [String]$argument4 = $Null,
    [Parameter(Position = 4, Mandatory = $false)]
    [String]$argument5 = $null,
    [Parameter(Position = 5, Mandatory = $false)]
    [String]$argument6 = $null,
    [Parameter(Mandatory = $false)]
    [switch]$asjson
)
[cultureinfo]::CurrentCulture = 'en-US'
$AllProtocols = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12' 
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
Set-Location (Split-Path (Split-Path (Split-Path (Split-Path $script:MyInvocation.MyCommand.Path))))
$dir = (Split-Path (Split-Path (Split-Path (Split-Path $script:MyInvocation.MyCommand.Path))))

if(-not $Global:Startup){$Global:Startup = "$dir\build\powershell\startup";}
if(-not $Global:Global){$Global:Global = "$dir\build\powershell\global";}
if(-not $Global:Build){$Global:Build = "$dir\build\powershell\build";}
if(-not $Global:Pool){$Global:Pool = "$dir\build\powershell\pool";}
if(-not $Global:Startup){$Global:Startup = "$dir\build\powershell\startup";}
if(-not $Global:Web){$Global:Web = "$dir\build\powershell\web";}
$p = [Environment]::GetEnvironmentVariable("PSModulePath")
if ($P -notlike "*$dir\build\powershell*") {
    $P += ";$Global:Startup";
    $P += ";$Global:Global";
    $P += ";$Global:Build";
    $P += ";$Global:Pool";
    $P += ";$Global:Web";
    [Environment]::SetEnvironmentVariable("PSModulePath", $p)
}

$Get = @()

Import-Module -Name "$Global:Global\stats.psm1" -Scope Global
Import-Module -Name "$Global:Global\include.psm1" -Scope Global

Switch ($argument1) {
    "help" {
        $help = 
        "Swarm Remote Command Guide: get
Swarm remote commands are a safe way to get miner information via ssh. It works by aquiring various 
configuration files, logs, data, stats, and transforming them into a viewable manner.

USE:

get [item] [argument2] [argument3] [argument4] [argument5]

EXAMPLE USES:

get miners NVIDIA1 trex x16r difficulty
get miners CPU jayddee all
get screen miner
get stats
get oc NVIDIA1 aergo power 

ITEMS:

miners
 can be used to view background miner information.

    USES:
        get miners [platform] [name] [param] [sub-param1] [sub-param2]

    OPTIONS:
        
        platform
        [NVIDIA1] [NVIDIA2] [NVIDIA3] [AMD1] [CPU] [all]

        name
        name of miner, as per the names of .json in config/miners
        if you are unsure of miner name, running-

            get miners [platform]
    
        to see all miners for that platform

    params
        [prestart] [commands] [difficulty] [naming]   [oc]

        sub-param1   [algo]     [algo]      [algo]   [algo]

        sub-param2                                   [power]
                                                     [core]
                                                     [mem]
                                                     [dpm]
                                                      [v]
                                                     [mdpm]

        example uses of params:

            get miners NVIDIA1 enemy naming 
            (Will list all naming items)

            get miners NVIDIA1 enemy oc hex core 
            (Will list oc core setting for hex algorithm)


screen
    can be used to remotely view SWARM's transcripts. Great way to
    view miner remotely. Returns last 300 lines in log.

    USES:

        get screen [platform]

    OPTIONS:

        platform:
        [miner] [NVIDIA1] [NVIDIA2] [NVIDIA3] [CPU] [AMD1]


version
    used to view current version of miner.

    USES:

        get version [name]

    OPTIONS:
 
        name
            name of miner, as per the names of .json in config/miners
            if you are unsure of miner name, choose 'all' to identify.


benchmarks
    used to view current a benchmark.

    USES:

        get benchmark [name] [algo]

    OPTIONS:

        name
            name of miner, as per the names of .json in config/miners.

        algo
            the algorithm stat you wish to view.


stats
    Used to view SWARM stats screen. This will display current
    critical mining information and statistics.

    USES:

        get stats


active
    Used to view current and historical launched miners, and
    display critical information regarding their arguments
    and time running.

    USES:

        get active


power
    Used to view power benchmarks/table. This allows you to view
    either WattOMeter stats, or config/power settings depending
    on use.

    USES:

        get power [platform] [type] [algo]

    OPTIONS:

        platform
        [NVIDIA1] [NVIDIA2] [NVIDIA3] [AMD1] [CPU]

        type
        [wattometer] [stat]

        algo
        all avaiable algorithms in SWARM


paramters
    Used to view SWARM's current parameters/arguments/settings

    USES:

        get parameters [name]

    OPTIONS:

        name
            name of parameter you wish to view. If you are unsure,
            specify 'all'


wallets
    print balance sheet of your current wallet balances
   
    USES:
   
        get wallet
   
    OPTIONS: none


update 
    will perform a remote update. Currently works only for windows.
    Linux coming soon.

    USES:
   
        get update [URI]
     
    OPTIONS:

        URI
            user specified link for .zip update. Use this if you are not
            updating to the next immediate version. This technically
            does not have to be from SWARM repository, however:
            1.) Must end with SWARM.number.of.version.zip
            2.) Link cannot contain spaces
            3.) Must be using a SWARM.number.of.version file

asic
    Will que ASIC connect to swarm to get further information
    regarding what it is mining.

    USES:
        get asic [ASIC]
    
    OPTIONS:

        [ASIC]
            This is the ASIC group you wish to contact.

                example:
                
                    get asic ASIC1
                    get asic ASIC2

                    etc.


to see all available SWARM commands, go to:

https://github.com/MaynardMiner/SWARM/wiki/HiveOS-management
"
        $help
        $help | out-file ".\build\txt\get.txt"
    }

    "asic" {
        Import-Module -Name "$Global:Global\hashrates.psm1"
        if (Test-Path ".\build\txt\bestminers.txt") { $BestMiners = Get-Content ".\build\txt\bestminers.txt" | ConvertFrom-Json }
        else { $Get += "No miners running" }
        $ASIC = $BestMiners | Where Type -eq $argument2
        if ($ASIC) {
            $Get += "Miner Name: $($ASIC.MinerName)"
            $Get += "Miner Currently Mining: $($ASIC.Symbol)"
            $command = @{command = "pools"; parameter = "0" } | ConvertTo-Json -Compress
            $request = Get-TCP -Port $ASIC.Port -Server $ASIC.Server -Message $Command -Timeout 5
            if ($request) {
                $response = $request | ConvertFrom-Json
                $PoolDetails = $response.POOLS | Where Pool -eq 1
                if ($PoolDetails) {
                    if ($PoolDetails[-1] -notmatch "}") { $PoolDetails = $PoolDetails.Substring(0, $PoolDetails.Length - 1) }
                    $PoolDetails | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | % {
                        $Get += "Active Pool $($_) = $($PoolDetails.$_)"
                    }
                }
                else { $Get += "contacted $($ASIC.MinerName), but no active pool was found" }
            }
            else { $Get += "Failed to contact miner on $($ASIC.Server) $($ASIC.Port) to get details" }
        }
        else { $Get += "No ASIC miners running" }
        remove-module -Name "hashrates"
    }


    "benchmarks" {

        Import-Module -Name "$Global:Global\hashrates.psm1"

        if (Test-path ".\stats") {
            if ($argument2) {
                switch ($argument2) {
                    "all" {
                        $StatNames = Get-ChildItem ".\stats" | Where Name -LIKE "*hashrate*"
                        $StatNames = $StatNames.Name -replace ".txt", ""
                        $Stats = [PSCustomObject]@{ }
                        if (Test-Path "stats") { Get-ChildItemContent "stats" | ForEach { $Stats | Add-Member $_.Name $_.Content } }
                    }
                    default {
                        $Stats = [PSCustomObject]@{ }
                        $StatNames = Get-ChildItem ".\stats" | Where Name -like "*$argument2*"
                        $StatNames = $StatNames.Name -replace ".txt", ""
                        if (Test-Path "stats") { Get-ChildItemContent "stats" | ForEach { $Stats | Add-Member $_.Name $_.Content } }
                    }
                } 
            }
            else {
                $StatNames = Get-ChildItem ".\stats" | Where Name -LIKE "*hashrate*"
                $StatNames = $StatNames.Name -replace ".txt", ""
                $Stats = [PSCustomObject]@{ }
                if (Test-Path "stats") { Get-ChildItemContent "stats" | ForEach { $Stats | Add-Member $_.Name $_.Content } }
            }
            $BenchTable = @()
            $StatNames | Foreach {
                $BenchTable += [PSCustomObject]@{
                    Miner     = $_ -split "_" | Select -First 1; 
                    Algo      = $_ -split "_" | Select -Skip 1 -First 1; 
                    HashRates = $Stats."$($_)".Hour | ConvertTo-Hash; 
                    Raw       = $Stats."$($_)".Hour
                }
            }
            function Get-BenchTable {
                $BenchTable | Sort-Object -Property Algo -Descending | Format-Table (
                    @{Label = "Miner"; Expression = { $($_.Miner) } },
                    @{Label = "Algorithm"; Expression = { $($_.Algo) } },
                    @{Label = "Speed"; Expression = { $($_.HashRates) } }    
                )
            }
            if ($asjson) {
                $Get += $BenchTable | ConvertTo-Json
            }
            else { $Get += Get-BenchTable }
            Get-BenchTable | Out-File ".\build\txt\get.txt"
        }
        else { $Get += "No Stats Found" }

        Remove-Module -Name "hashrates"
    }

    "wallets" {
        Import-Module "$global:Global\wallettable.psm1" -Scope Global
        if($asjson){
        $Get = Get-WalletTable -asjson
        } else {$Get += Get-WalletTable}
        Remove-Module "wallettable"
    }
    "stats" {
        if ($Argument2 -eq "lite") {
            if ($Argument3) {
                $Total = [int]$Argument3 + 1
                if (Test-Path ".\build\txt\minerstatslite.txt") {
                    $Get += Get-Content ".\build\txt\minerstatslite.txt"
                }
                else { $Get += "No Stats History Found" }    
            }
            else {
                if (Test-Path ".\build\txt\minerstatslite.txt") { $Get += Get-Content ".\build\txt\minerstatslite.txt" }
                else { $Get += "No Stats History Found" }
            }
        }
        else {
            if ($Argument2) {
                $Total = [int]$Argument2 + 1
                if (Test-Path ".\build\txt\minerstats.txt") {
                    $Get += Get-Content ".\build\txt\minerstats.txt"
                    $Get += $Get | % { $Number = 0; if ($_ -ne "") { $Number = $_.SubString(0, 2); $Number = $Number -replace " ", ""; try { $Number = [int]$Number }catch { $Number = 0 } }; if ($Number -lt $Total) { $_ } }
                }
                else { $Get += "No Stats History Found" }    

            }
            else {
                if (Test-Path ".\build\txt\minerstats.txt") { $Get += Get-Content ".\build\txt\minerstats.txt" }
                else { $Get += "No Stats History Found" }
            }
        }
    }
    "charts" { if (Test-Path ".\build\txt\charts.txt") { $Get += Get-Content ".\build\txt\charts.txt" } }
    "active" {
        if (Test-Path ".\build\txt\mineractive.txt") { $Get += Get-Content ".\build\txt\mineractive.txt" }
        else { $Get += "No Miner History Found" }
    }
    "parameters" {
        if (Test-Path ".\config\parameters\newarguments.json") {$FilePath = ".\config\parameters\arguments.json"}
        else {$FilePath = ".\config\parameters\arguments.json"}
        if(Test-Path $FilePath) {
            $SwarmParameters = @()
            $MinerArgs = Get-Content $FilePath | ConvertFrom-Json
            $MinerArgs | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | Foreach { $SwarmParameters += "$($_): $($MinerArgs.$_)" }
        }
        else { $SwarmParameters += "No Parameters For SWARM found" }
        $Get += $SwarmParameters
    }
    "screen" {
        if (Test-Path ".\logs\$($argument2).log") { $Get += Get-Content ".\logs\$($argument2).log" }
        if ($argument2 -eq "miner") { if (Test-Path ".\logs\*active*") { $Get += Get-Content ".\logs\*active.log*" } }
        $Get += $Get | Select -Last 300
    }
    "oc" {
        if (Test-Path ".\build\txt\oc-settings.txt") { $Get += Get-Content ".\build\txt\oc-settings.txt" }
        else { $Get += "No oc settings found" }
    }
    "miners" {
        $GetJsons = Get-ChildItem ".\config\miners"
        $ConvertJsons = [PSCustomObject]@{ }
        $GetJsons.Name | foreach { $Getfile = Get-Content ".\config\miners\$($_)" | ConvertFrom-Json; $ConvertJsons | Add-Member $Getfile.Name $Getfile -Force }
        if ($argument2) {
            $Get += "Current $Argument2 Miner List:"
            $Get += " "   
            $ConvertJsons.PSObject.Properties.Name | Where { $ConvertJsons.$_.$Argument2 } | foreach { $Get += "$($_)" }
            $Selected = $ConvertJsons.PSObject.Properties.Name | Where { $_ -eq $Argument3 } | % { $ConvertJsons.$_ }
            if ($Selected) {
                $Cuda = Get-Content ".\build\txt\cuda.txt"
                $Platform = Get-Content ".\build\txt\os.txt"
                if ($argument2 -like "*NVIDIA*") {
                    $Number = $argument2 -Replace "NVIDIA", ""
                    if ($Platform -eq "linux") {
                        switch ($Cuda) {
                            "9.2" { $UpdateJson = Get-Content ".\config\update\nvidia9.2-linux.json" | ConvertFrom-Json }
                            "10" { $UpdateJson = Get-Content ".\config\update\nvidia10-linux.json" | ConvertFrom-Json }
                        }
                    }
                    else { $UpdateJson = Get-Content ".\config\update\nvidia-win.json" | ConvertFrom-JSon }
                }
                if ($argument2 -like "*AMD*") {
                    $Number = $argument2 -Replace "AMD", ""
                    switch ($Platform) {
                        "linux" { $UpdateJson = Get-Content ".\config\update\amd-linux.json" | ConvertFrom-Json }
                        "windows" { $UpdateJson = Get-Content ".\config\update\amd-windows.json" | ConvertFrom-Json }
                    }
                }
                if ($argument2 -like "*CPU*") {
                    $Number = 1
                    switch ($Platform) {  
                        "linux" { $UpdateJson = Get-Content ".\config\update\cpu-linux.json" | ConvertFrom-Json }
                        "windows" { $UpdateJson = Get-Content ".\config\update\cpu-windows.json" | ConvertFrom-Json }
                    }
                }
                $getpath = "path$($Number)"
                $Get += " "
                $Get += "Miner Update Information:"
                $Get += " "
                $Get += "Miner Name: $($UpdateJson.$Argument3.name)"
                $Get += "Miner Path: $($UpdateJson.$Argument3.$getpath)"
                $Get += "Miner executable $($UpdateJson.$Argument3.minername)"
                $Get += "Miner version $($UpdateJson.$Argument3.version)"
                $Get += "Miner URI $($UpdateJson.$Argument3.uri)"
                $Get += " "
                $Get += "User Seletected $Argument3"
                if ($Argument4) {
                    if ($argument5) {
                        $Get += " "
                        $Get += "Getting: $Argument1 $Argument2 $Argument3 $Argument4 $Argument5"
                        $Get += " "
                        $Get += if ($selected.$argument2.$argument4.$argument5) { $selected.$argument2.$argument4.$argument5 }else { "none" }
                    }
                    elseif ($argument6) {
                        $Get += " "
                        $Get += "Getting: $Argument1 $Argument2 $Argument3 $Argument4 $Argument5 $Argument6"
                        $Get += " "
                        $Get += if ($selected.$argument2.$argument4.$argument5.$Arguement6) { $selected.$argument2.$argument4.$argument5.$Arguement6 }else { "none" }
                    }
                    else {
                        $Get += " "
                        $Get += "Getting: $Argument1 $Argument2 $Argument3 $Argument4"
                        $Get += " "
                        $Get += if ($selected.$argument2.$argument4) { $selected.$argument2.$argument4 }else { "none" }
                    }
                }  
            }
        }
        else { $Get += "No Platforms Selected: Please choose a platform NVIDIA1,NVIDIA2,NVIDIA3,AMD1,CPU" }
    }
    "update" {
        if (Test-Path "C:\") {
            $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
            if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -ne $false) {
                $version = Get-Content ".\build\txt\version.txt"
                $versionnumber = $version -replace "SWARM.", ""
                $version1 = $versionnumber[4]
                $version1 = $version1 | % { iex $_ }
                $version1 = $version1 + 1
                $version2 = $versionnumber[2]
                $version3 = $versionnumber[0]
                if ($version1 -eq 10) {
                    $version1 = 0; 
                    $version2 = $version2 | % { iex $_ }
                    $version2 = $version2 + 1
                }
                if ($version2 -eq 10) {
                    $version2 = 0; 
                    $version3 = $version3 | % { iex $_ }
                    $version3 = $version3 + 1
                }
                $versionnumber = "$version3.$version2.$version1"    
                $Failed = $false
                Write-Host "Operating System Is Windows: Updating via 'get' is possible`n"
                if ($argument2) {
                    $EndLink = split-path $argument2 -Leaf
                    if ($EndLink -match "SWARM.") {
                        $URI = $argument2
                    }
                    else {
                        $Failed = $true
                        $line += "Detected link supplied did not end with SWARM"
                        Write-Host "Detected link supplied did not end with SWARM" -ForegroundColor Red
                        $URI = $null
                    }
                }
                else {
                    $line += "Detected New Version Should Be $VersionNumber`n"
                    Write-Host "Detected New Version Should Be $VersionNumber"    
                    $URI = "https://github.com/MaynardMiner/SWARM/releases/download/v$VersionNumber/SWARM.$VersionNumber.zip"
                }
                Write-Host "Main Directory is $Location`n"
                $line += "Main Directory is $Location`n"
                $NewLocation = Join-Path (Split-Path $Dir) "SWARM.$VersionNumber"
                $line += "New Location is $NewLocation"
                Write-Host "New Location is $NewLocation"
                $FileName = join-path ".\x64" "SWARM.$VersionNumber.zip"
                Write-Host "New"
                $DLFileName = Join-Path "$Dir" "x64\SWARM.$VersionNumber.zip"
                $line += "Extraction Path is $DLFileName"
                Write-Host "Extraction Path is $DLFileName"
                $URI = "https://github.com/MaynardMiner/SWARM/releases/download/v$versionNumber/SWARM.$VersionNumber.zip"
                try { Invoke-WebRequest $URI -OutFile $FileName -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop }catch { $Failed = $true; Write-Host "Failed To Contact Github For Download! Must Do So Manually" }
                Start-Sleep -S 5
                if ($Failed -eq $false) {
                    Get-Location | Out-Host
                    Start-Process ".\build\apps\7z.exe" "x `"$($DLFileName)`" -o`"$($Location)`" -y" -Wait -WindowStyle Minimized
                    Start-Sleep -S 3
                    Write-Host "Config Command Initiated- Restarting SWARM`n"
                    $MinerFile = ".\build\pid\miner_pid.txt"
                    if (Test-Path $MinerFile) { $MinerId = Get-Process -Id (Get-Content $MinerFile) -ErrorAction SilentlyContinue }
                    Stop-Process $MinerId -Force
                    Write-Host "Stopping Old Miner`n"
                    Start-Sleep -S 5
                    Write-Host "Attempting to start new SWARM verison at $NewLocation\SWARM.bat"
                    Write-Host "Downloaded and extracted SWARM successfully`n"
                    Copy-Item ".\SWARM.bat" -Destination $NewLocation -Force
                    Copy-Item ".\config\parameters\newarguments.json" -Destination "$NewLocation\config\parameters" -Force
                    New-Item -Name "pid" -Path "$NewLocation\build" -ItemType "Directory"
                    Copy-Item ".\build\pid\background_pid.txt" -Destination "$NewLocation\build\pid" -Force
                    Set-Location $NewLocation
                    Start-Process "SWARM.bat"
                    Set-Location $Dir
                }
            }
            else { $Get += "Cannot update. Are you administrator?" }
        }
        else { $Get += "get update can only run in windows currently..." }
    }

    default {
        $Get +=
        "item not found or specified. use:

get help

to see a list of availble items.
"
    }
}

    $Get
    $Get | Set-Content ".\build\txt\get.txt"


Remove-Module -Name "stats"
Remove-Module -Name "include"
