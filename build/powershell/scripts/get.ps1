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

$argument2 = $argument2.replace("cnight", "cryptonight")
$argument3 = $argument3.replace("cnight", "cryptonight")
$argument4 = $argument4.replace("cnight", "cryptonight")
$argument5 = $argument5.replace("cnight", "cryptonight")
$argument6 = $argument6.replace("cnight", "cryptonight")

[cultureinfo]::CurrentCulture = 'en-US'
$AllProtocols = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12' 
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
$dir = (Split-Path (Split-Path (Split-Path (Split-Path $script:MyInvocation.MyCommand.Path))))
$dir = $dir -replace "/var/tmp", "/root"
Set-Location $dir

. .\build\powershell\global\modules.ps1

if (-not $(vars) ) {
    $Global:Config = @{ }; $Global:Config.Add("vars", @{ }) 
}
if (-not $(vars).startup ) { $(vars).Add("startup", "$dir\build\powershell\startup") }
if (-not $(vars).global ) { $(vars).Add("global", "$dir\build\powershell\global") }
if (-not $(vars).build ) { $(vars).Add("build", "$dir\build\powershell\build") }
if (-not $(vars).pool ) { $(vars).Add("pool", "$dir\build\powershell\pool") }
if (-not $(vars).web ) { $(vars).Add("web", "$dir\build\api\web") }

$p = [Environment]::GetEnvironmentVariable("PSModulePath")
if ($P -notlike "*$dir\build\powershell*") {
    $P += ";$($(vars).startup)";
    $P += ";$($(vars).global)";
    $P += ";$($(vars).build)";
    $P += ";$($(vars).pool)";
    $P += ";$($(vars).web)";
    [Environment]::SetEnvironmentVariable("PSModulePath", $p)
}

$Get = @()
if (test-path ".\debug\get.txt") { Clear-Content ".\debug\get.txt" }

Import-Module -Name "$($(vars).global)\stats.psm1" -Scope Global

Switch ($argument1) {
    "help" {
        $help = 
        "Swarm Remote Command Guide: get
Swarm remote commands are a safe way to get miner information via ssh. It works by aquiring various 
configuration files, logs, data, stats, and transforming them into a viewable manner.

USE:

get [item] [argument2] [argument3] [argument4] [argument5]

EXAMPLE USES:

get screen miner
get stats
get oc NVIDIA1 aergo power 

ITEMS:

benchmarks
    used to view current a benchmark.

    USES:

        get benchmark [name] [algo]

    OPTIONS:

        name
            name of miner, as per the names of .json in config/miners.

        algo
            the algorithm stat you wish to view.

###################################################################
###################################################################

stats
    Used to view SWARM stats screen. This will display current
    critical mining information and statistics.

    USES:

        get stats

###################################################################
###################################################################

active
    Used to view current and historical launched miners, and
    display critical information regarding their arguments
    and time running.

    USES:

        get active

###################################################################
###################################################################
        
paramters
    Used to view SWARM's current parameters/arguments/settings

    USES:

        get parameters [name]

    OPTIONS:

        name
            name of parameter you wish to view. If you are unsure,
            specify 'all'

###################################################################
###################################################################

wallets
    print balance sheet of your current wallet balances
   
    USES:
   
        get wallet
   
    OPTIONS: none

###################################################################
###################################################################

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

###################################################################
###################################################################


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

###################################################################
###################################################################

charts
    Gets a visual bar chart break down of stats, instead of a table.

###################################################################
###################################################################

                    End all get commands.

###################################################################
###################################################################


OTHER USEFUL COMMANDS that are not part of get, but work for SWARM:

###################################################################
###################################################################

clear_profits
        Clears all stat files for pools

###################################################################
###################################################################
        
clear_watts
        Clears all watt files
        Resets power.json

###################################################################
###################################################################
        
bench
    Resets a ban or benchmark for a miner, algorithm, miner/algorithm.

        USAGE:

            [miner] [name]
            [miner] [name] [algorithm]
            [algorithm] [name]
            [timeout]

        EXAMPLES:

            bench miner [name] 
                will clear all benchmarks for that miner
            bench algorithm [name] 
                will clear all benchmarks for that algorithm
            bench miner [name] [algoritm]
                will clear algorithm benchmark for the miner.
            bench bans
                will clear all bans

###################################################################
###################################################################                

nview
    Allows the ability to run a command listed here in a loop
    every -n seconds.

        USAGE:
            [-n] [-onchange]

        EXAMPLES:

            nview get stats -n 30 
                Will run command get stats every thirty seconds

            nview get stats -n 10 -Onchange
                Will run get stats command every 10 seconds
                Will only refresh screen if data has changed.
            
###################################################################
###################################################################                

version
    used to view current version of miner, as well as update miners.
    
    USAGE:
        [query] 
        [update] [miner] [version] [link]
            
        EXAMPLE:
            version query
            version update gminer-1 1.2.2 https://github.com/gminerreleases/tag/v.1.2.4/gminer.1.2.2.zip
            
        OPTIONS:
            
            query:
                returns a list of all miners and their versions.
                    
            update:
                update a miner. version update is proceeded
                by miner name, version, and link. Ensure that
                you specify the groups gminer-1 would be for
                NVIDIA1, gminer-2 would be for NVIDIA2.
            

###################################################################
###################################################################                
                
to see all available SWARM commands, go to:

https://github.com/MaynardMiner/SWARM/wiki/HiveOS-management
"
        $help
        $help | out-file ".\debug\get.txt"
    }

    "asic" {
        Import-Module -Name "$($(vars).global)\hashrates.psm1"
        if (Test-Path ".\debug\bestminers.txt") { $BestMiners = Get-Content ".\debug\bestminers.txt" | ConvertFrom-Json }
        else { $Get += "No miners running" }
        $ASIC = $BestMiners | Where-Object Type -eq $argument2
        if ($ASIC) {
            $Get += "Miner Name: $($ASIC.MinerName)"
            $Get += "Miner Currently Mining: $($ASIC.Symbol)"
            $command = @{command = "pools"; parameter = "0" } | ConvertTo-Json -Compress
            $request = Global:Get-TCP -Port $ASIC.Port -Server $ASIC.Server -Message $Command -Timeout 5
            if ($request) {
                $response = $request | ConvertFrom-Json
                $PoolDetails = $response.POOLS | Where-Object Pool -eq 1
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
    }


    "benchmarks" {

        Import-Module -Name "$($(vars).global)\hashrates.psm1" -Scope Global

        if (Test-path ".\stats") {
            if ($argument2) {
                switch ($argument2) {
                    "all" {
                        $StatNames = Get-ChildItem ".\stats" | Where-Object Name -LIKE "*hashrate*"
                        $StatNames = $StatNames.Name -replace ".txt", ""
                        $Stats = [PSCustomObject]@{ }
                        if (Test-Path "stats") { Get-ChildItemContent "stats" | ForEach { $Stats | Add-Member $_.Name $_.Content } }
                    }
                    default {
                        $Stats = [PSCustomObject]@{ }
                        $StatNames = Get-ChildItem ".\stats" | Where-Object Name -like "*$argument2*"
                        $StatNames = $StatNames.Name -replace ".txt", ""
                        if (Test-Path "stats") { Get-ChildItemContent "stats" | ForEach { $Stats | Add-Member $_.Name $_.Content } }
                    }
                } 
            }
            else {
                $StatNames = Get-ChildItem ".\stats" | Where-Object Name -LIKE "*hashrate*"
                $StatNames = $StatNames.Name -replace ".txt", ""
                $Stats = [PSCustomObject]@{ }
                if (Test-Path "stats") { Get-ChildItemContent "stats" | ForEach { $Stats | Add-Member $_.Name $_.Content } }
            }
            $BenchTable = @()
            $StatNames | Foreach {
                $BenchTable += [PSCustomObject]@{
                    Miner      = $_ -split "_" | Select -First 1; 
                    Algo       = $_ -split "_" | Select -Skip 1 -First 1; 
                    HashRates  = $Stats."$($_)".Hour | Global:ConvertTo-Hash; 
                    Raw        = $Stats."$($_)".Hour
                    Rejections = $Stats."$($_)".Rejections
                }
            }
            function Global:Get-BenchTable {
                $BenchTable | Sort-Object -Property Algo -Descending | Format-Table (
                    @{Label = "Miner"; Expression = { $($_.Miner) } },
                    @{Label = "Algorithm"; Expression = { $($_.Algo) } },
                    @{Label = "Speed"; Expression = { $($_.HashRates) } },    
                    @{Label = "Rejection Avg."; Expression = { if ($_.Rejections) { "$($_.Rejections.ToString("N2"))`%" }else { "0`%" } } }
                )
            }
            if ($asjson) {
                $Get += $BenchTable | ConvertTo-Json
            }
            else { $Get += Get-BenchTable }
            Get-BenchTable | Out-File ".\debug\get.txt"
        }
        else { $Get += "No Stats Found" }
    }

    "wallets" {
        Import-Module "$($(vars).global)\wallettable.psm1" -Scope Global
        if ($asjson) {
            $Get = Global:Get-WalletTable -asjson
        }
        else { $Get += Global:Get-WalletTable }
        Remove-Module "wallettable"
    }
    "stats" {
        Import-Module -Name "$($(vars).global)\hashrates.psm1" -Scope Global
        if ($Argument2 -eq "lite") {
            if ($Argument3) {
                $Total = [int]$Argument3 + 1
                if (Test-Path ".\debug\minerstatslite.txt") {
                    $Get += Get-Content ".\debug\minerstatslite.txt"
                }
                else { $Get += "No Stats History Found" }    
            }
            else {
                if (Test-Path ".\debug\minerstatslite.txt") { $Get += Get-Content ".\debug\minerstatslite.txt" }
                else { $Get += "No Stats History Found" }
            }
        }
        else {
            if (test-path ".\debug\profittable.txt") { $Stat_Table = Get-Content ".\debug\profittable.txt" | ConvertFrom-Json }
            else { $Get += "No Stats History Found" }
            if ($Stat_Table) {
                $me = [char]27;
                $white = "37";
                $blue = "94";
                $yellow = "33";
                $green = "32";
                $cyan = "36";
                $red = "31";
                $gray = "90";
                $orange = "93"
                $magenta = "35";
                $pink = "95";
                if (test-Path ".\debug\rates.txt") { $Rates = Get-Content ".\debug\rates.txt" | ConvertFrom-Json }
                $WattTable = $false
                $ShareTable = $false
                $VolumeTable = $false
                $Stat_Table | ForEach-Object { if ([Double]$_.Power_Day -gt 0) { $WattTable = $True } }
                $Stat_Table | ForEach-Object { if ([Double]$_.Shares -gt 0) { $ShareTable = $True } }
                $Stat_Table | ForEach-Object { if ([Double]$_.Volume -gt 0) { $VolumeTable = $True } }            
                $Type = $Stat_table.Type | Select -Unique
                $Test = "$me[${white}mMiner${me}[0m"
                $Type | Sort-Object | ForEach-Object {
                    $Miner_Table = $Stat_Table | Where-Object Type -eq $_
                    if ($Argument2) { $Miner_Table = $Miner_Table | Sort-Object -Property Profit -Descending | Select -First ([int]$Argument2) }
                    $global:index = 1
                    if ($WattTable -and $ShareTable -and $VolumeTable) {
                        $Get += $Miner_Table | Sort-Object -Property Profit -Descending | Format-Table -GroupBy Type (
                            @{Label = "Miner`|Coin"; Expression = { "$me[${white}m$($global:index) $($_.Name)${me}[0m`|$me[${green}m$($_.ScreenName.replace("cryptonight","cn").replace("cnight","cn"))${me}[0m"; $global:index += 1 }; Align = 'left' },
                            @{Label = "Speed`|Watt/Day"; Expression = { "$me[${white}m$($($_.HashRates) | ForEach-Object { if ($null -ne $_) { "$($_ | Global:ConvertTo-Hash)/s" }else { "Bench" } })${me}[0 m`| $me[${green}m$($($_.Power_Day) | ForEach-Object { if ($null -ne $_) { ($_ * $Rates.Rate).ToString("N2") }else { "Bench" } })${me}[0m" }; Align = 'left' },
                            @{Label = "BTC`|$($Rates.Coin)`|$($Rates.Currency)/Day"; Expression = { "$me[${white}m$($($_.Profit) | ForEach-Object { if ($null -ne $_) { $_.ToString("N5") }else { "Bench" } })${me}[0m`|$me[${cyan}m$($($_.Profit) | ForEach-Object { if ($null -ne $_) { ($_ / $Rates.Exchange).ToString("N5") }else { "Bench" } } )${me}[0m`|$me[${green}m$($($_.Profit) | ForEach-Object { if ($null -ne $_) { ($_ * $Rates.Rate).ToString("N2") }else { "Bench" } })${me}[0m" }; Align = 'center' },
                            @{Label = "Pool"; Expression = { 
                                    "$(
                                        $Pool = $_.MinerPool
                                        switch ($Pool) {
                                    "nicehash" { "$me[${yellow}m$($Pool)${me}[0m" }
                                    "zergpool" { "$me[${green}m$($Pool)${me}[0m" }
                                    "nlpool" { "$me[${blue}m$($Pool)${me}[0m" }
                                    "blazepool" { "$me[${red}m$($Pool)${me}[0m" }
                                    "ahashpool" { "$me[${orange}m$($Pool)${me}[0m" }
                                    "blockmasters" { "$me[${cyan}m$($Pool)${me}[0m" }
                                    "fairpool" { "$me[${white}m$($Pool)${me}[0m" }
                                    "hasrefinery" { "$me[${magenta}m$($Pool)${me}[0m" }
                                    "zpool" { "$me[${gray}m$($Pool)${me}[0m" }
                                    "whalesburg" { "$me[${pink}m$($Pool)${me}[0m" }
                                    "hashrent" { "$me[${white}m$($Pool)${me}[0m" }
                                    "mph" { "$me[${orange}m$($Pool)${me}[0m" }
                                })"
                                }; 
                                Align = 'center'
                            },
                            @{Label = "Shares"; Expression = { $($_.Shares -as [Decimal]).ToString("N2") }; Align = 'center' },
                            @{Label = "Vol."; Expression = { $($_.Volume) | ForEach-Object { if ($null -ne $_) { "$([math]::Round(100 - $_,0).ToString())`%" }else { "Bench" } } }; Align = 'left' }
                        )
                    }
                    elseif ($WattTable -and $ShareTable) {
                        $Get += $Miner_Table | Sort-Object -Property Profit -Descending | Format-Table -GroupBy Type (
                            @{Label = "Miner`|Coin"; Expression = { "$me[${white}m$($global:index) $($_.Name)${me}[0m`|$me[${green}m$($_.ScreenName.replace("cryptonight","cn").replace("cnight","cn"))${me}[0m"; $global:index += 1 }; Align = 'left' },
                            @{Label = "Speed`|Watt/Day"; Expression = { "$me[${white}m$($($_.HashRates) | ForEach-Object { if ($null -ne $_) { "$($_ | Global:ConvertTo-Hash)/s" }else { "Bench" } })${me}[0m`|$me[${green}m$($($_.Power_Day) | ForEach-Object { if ($null -ne $_) { ($_ * $Rates.Rate).ToString("N2") }else { "Bench" } })${me}[0m" }; Align = 'left' },
                            @{Label = "BTC`|$($Rates.Coin)`|$($Rates.Currency)/Day"; Expression = { "$me[${white}m$($($_.Profit) | ForEach-Object { if ($null -ne $_) { $_.ToString("N5") }else { "Bench" } })${me}[0m`|$me[${cyan}m$($($_.Profit) | ForEach-Object { if ($null -ne $_) { ($_ / $Rates.Exchange).ToString("N5") }else { "Bench" } } )${me}[0m`|$me[${green}m$($($_.Profit) | ForEach-Object { if ($null -ne $_) { ($_ * $Rates.Rate).ToString("N2") }else { "Bench" } })${me}[0m" }; Align = 'center' },
                            @{Label = "Pool"; Expression = { 
                                    "$(
                                    $Pool = $_.MinerPool
                                    switch ($Pool) {
                                "nicehash" { "$me[${yellow}m$($Pool)${me}[0m" }
                                "zergpool" { "$me[${green}m$($Pool)${me}[0m" }
                                "nlpool" { "$me[${blue}m$($Pool)${me}[0m" }
                                "blazepool" { "$me[${red}m$($Pool)${me}[0m" }
                                "ahashpool" { "$me[${orange}m$($Pool)${me}[0m" }
                                "blockmasters" { "$me[${cyan}m$($Pool)${me}[0m" }
                                "fairpool" { "$me[${white}m$($Pool)${me}[0m" }
                                "hasrefinery" { "$me[${magenta}m$($Pool)${me}[0m" }
                                "zpool" { "$me[${gray}m$($Pool)${me}[0m" }
                                "whalesburg" { "$me[${pink}m$($Pool)${me}[0m" }
                                "hashrent" { "$me[${white}m$($Pool)${me}[0m" }
                                "mph" { "$me[${orange}m$($Pool)${me}[0m" }
                            })"
                                }; 
                                Align = 'center'
                            },
                            @{Label = "Shares"; Expression = { $($_.Shares -as [Decimal]).ToString("N2") }; Align = 'center' }
                        )
                    }
                    elseif ($WattTable -and $VolumeTable) {
                        $Get += $Miner_Table | Sort-Object -Property Profit -Descending | Format-Table -GroupBy Type (
                            @{Label = "Miner`|Coin"; Expression = { "$me[${white};m$($global:index) $($_.Name)${me}[0m`|$me[${green};m$($_.ScreenName.replace("cryptonight","cn").replace("cnight","cn"))${me}[0m"; $global:index += 1 }; Align = 'left' },
                            @{Label = "Speed`|Watt/Day"; Expression = { "$me[${white};m$($($_.HashRates) | ForEach-Object { if ($null -ne $_) { "$($_ | Global:ConvertTo-Hash)/s" }else { "Bench" } })${me}[0m`|$me[${green};m$($($_.Power_Day) | ForEach-Object { if ($null -ne $_) { ($_ * $Rates.Rate).ToString("N2") }else { "Bench" } })${me}[0m" }; Align = 'left' },
                            @{Label = "BTC`|$($Rates.Coin)`|$($Rates.Currency)/Day"; Expression = { "$me[${white}m$($($_.Profit) | ForEach-Object { if ($null -ne $_) { $_.ToString("N5") }else { "Bench" } })${me}[0m`|$me[${cyan}m$($($_.Profit) | ForEach-Object { if ($null -ne $_) { ($_ / $Rates.Exchange).ToString("N5") }else { "Bench" } } )${me}[0m`|$me[${green}m$($($_.Profit) | ForEach-Object { if ($null -ne $_) { ($_ * $Rates.Rate).ToString("N2") }else { "Bench" } })${me}[0m" }; Align = 'center' },
                            @{Label = "Pool"; Expression = { 
                                    "$(
                                    $Pool = $_.MinerPool
                                    switch ($Pool) {
                                "nicehash" { "$me[${yellow}m$($Pool)${me}[0m" }
                                "zergpool" { "$me[${green}m$($Pool)${me}[0m" }
                                "nlpool" { "$me[${blue}m$($Pool)${me}[0m" }
                                "blazepool" { "$me[${red}m$($Pool)${me}[0m" }
                                "ahashpool" { "$me[${orange}m$($Pool)${me}[0m" }
                                "blockmasters" { "$me[${cyan}m$($Pool)${me}[0m" }
                                "fairpool" { "$me[${white}m$($Pool)${me}[0m" }
                                "hasrefinery" { "$me[${magenta}m$($Pool)${me}[0m" }
                                "zpool" { "$me[${gray}m$($Pool)${me}[0m" }
                                "whalesburg" { "$me[${pink}m$($Pool)${me}[0m" }
                                "hashrent" { "$me[${white}m$($Pool)${me}[0m" }
                                "mph" { "$me[${orange}m$($Pool)${me}[0m" }
                            })"
                                }; 
                                Align = 'center'
                            },
                            @{Label = "Vol."; Expression = { $($_.Volume) | ForEach-Object { if ($null -ne $_) { "$([math]::Round(100 - $_,0).ToString())`%" }else { "Bench" } } }; Align = 'left' }
                        )
                    }
                    elseif ($WattTable) {
                        $Get += $Miner_Table | Sort-Object -Property Profit -Descending | Format-Table -GroupBy Type (
                            @{Label = "Miner`|Coin"; Expression = { "$me[${white}m$($global:index) $($_.Name)${me}[0m`|$me[${green}m$($_.ScreenName.replace("cryptonight","cn").replace("cnight","cn"))${me}[0m"; $global:index += 1 }; Align = 'left' },
                            @{Label = "Speed`|Watt/Day"; Expression = { "$me[${white}m$($($_.HashRates) | ForEach-Object { if ($null -ne $_) { "$($_ | Global:ConvertTo-Hash)/s" }else { "Bench" } })${me}[0m`|$me[${green}m$($($_.Power_Day) | ForEach-Object { if ($null -ne $_) { ($_ * $Rates.Rate).ToString("N2") }else { "Bench" } })${me}[0m" }; Align = 'left' },
                            @{Label = "BTC`|$($Rates.Coin)`|$($Rates.Currency)/Day"; Expression = { "$me[${white}m$($($_.Profit) | ForEach-Object { if ($null -ne $_) { $_.ToString("N5") }else { "Bench" } })${me}[0m`|$me[${cyan}m$($($_.Profit) | ForEach-Object { if ($null -ne $_) { ($_ / $Rates.Exchange).ToString("N5") }else { "Bench" } } )${me}[0m`|$me[${green}m$($($_.Profit) | ForEach-Object { if ($null -ne $_) { ($_ * $Rates.Rate).ToString("N2") }else { "Bench" } })${me}[0m" }; Align = 'center' },
                            @{Label = "Pool"; Expression = { 
                                    "$(
                                    $Pool = $_.MinerPool
                                    switch ($Pool) {
                                "nicehash" { "$me[${yellow}m$($Pool)${me}[0m" }
                                "zergpool" { "$me[${green}m$($Pool)${me}[0m" }
                                "nlpool" { "$me[${blue}m$($Pool)${me}[0m" }
                                "blazepool" { "$me[${red}m$($Pool)${me}[0m" }
                                "ahashpool" { "$me[${orange}m$($Pool)${me}[0m" }
                                "blockmasters" { "$me[${cyan}m$($Pool)${me}[0m" }
                                "fairpool" { "$me[${white}m$($Pool)${me}[0m" }
                                "hasrefinery" { "$me[${magenta}m$($Pool)${me}[0m" }
                                "zpool" { "$me[${gray}m$($Pool)${me}[0m" }
                                "whalesburg" { "$me[${pink}m$($Pool)${me}[0m" }
                                "hashrent" { "$me[${white}m$($Pool)${me}[0m" }
                                "mph" { "$me[${orange}m$($Pool)${me}[0m" }
                            })"
                                }; 
                                Align = 'center'
                            }
                        )
                    }
                    elseif ($ShareTable -and $VolumeTable) {
                        $Get += $Miner_Table | Sort-Object -Property Profit -Descending | Format-Table -GroupBy Type (
                            @{Label = "Miner`|Coin"; Expression = { "$me[${white}m$($global:index) $($_.Name)${me}[0m`|$me[${green}m$($_.ScreenName.replace("cryptonight","cn").replace("cnight","cn"))${me}[0m"; $global:index += 1 }; Align = 'left' },
                            @{Label = "Speed"; Expression = { $($_.HashRates) | ForEach-Object { if ($null -ne $_) { "$me[${white}m$($_ | Global:ConvertTo-Hash)/s${me}[0m" }else { "$me[${white}mBench${me}[0m" } } }; Align = 'left' },
                            @{Label = "BTC`|$($Rates.Coin)`|$($Rates.Currency)/Day"; Expression = { "$me[${white}m$($($_.Profit) | ForEach-Object { if ($null -ne $_) { $_.ToString("N5") }else { "Bench" } })${me}[0m`|$me[${cyan}m$($($_.Profit) | ForEach-Object { if ($null -ne $_) { ($_ / $Rates.Exchange).ToString("N5") }else { "Bench" } } )${me}[0m`|$me[${green}m$($($_.Profit) | ForEach-Object { if ($null -ne $_) { ($_ * $Rates.Rate).ToString("N2") }else { "Bench" } })${me}[0m" }; Align = 'center' },
                            @{Label = "Pool"; Expression = { 
                                    "$(
                                    $Pool = $_.MinerPool
                                    switch ($Pool) {
                                "nicehash" { "$me[${yellow}m$($Pool)${me}[0m" }
                                "zergpool" { "$me[${green}m$($Pool)${me}[0m" }
                                "nlpool" { "$me[${blue}m$($Pool)${me}[0m" }
                                "blazepool" { "$me[${red}m$($Pool)${me}[0m" }
                                "ahashpool" { "$me[${orange}m$($Pool)${me}[0m" }
                                "blockmasters" { "$me[${cyan}m$($Pool)${me}[0m" }
                                "fairpool" { "$me[${white}m$($Pool)${me}[0m" }
                                "hasrefinery" { "$me[${magenta}m$($Pool)${me}[0m" }
                                "zpool" { "$me[${gray}m$($Pool)${me}[0m" }
                                "whalesburg" { "$me[${pink}m$($Pool)${me}[0m" }
                                "hashrent" { "$me[${white}m$($Pool)${me}[0m" }
                                "mph" { "$me[${orange}m$($Pool)${me}[0m" }
                            })"
                                }; 
                                Align = 'center'
                            },
                            @{Label = "Shares"; Expression = { $($_.Shares -as [Decimal]).ToString("N2") }; Align = 'center' },
                            @{Label = "Vol."; Expression = { $($_.Volume) | ForEach-Object { if ($null -ne $_) { "$([math]::Round(100 - $_,0).ToString())`%" }else { "Bench" } } }; Align = 'left' }
                        )
                    }
                    elseif ($ShareTable) {
                        $Get += $Miner_Table | Sort-Object -Property Profit -Descending | Format-Table -GroupBy Type (
                            @{Label = "Miner`|Coin"; Expression = { "$me[${white}m$($global:index) $($_.Name)${me}[0m`|$me[${green}m$($_.ScreenName.replace("cryptonight","cn").replace("cnight","cn"))${me}[0m"; $global:index += 1 }; Align = 'left' },
                            @{Label = "Speed"; Expression = { $($_.HashRates) | ForEach-Object { if ($null -ne $_) { "$me[${white}m$($_ | Global:ConvertTo-Hash)/s${me}[0m" }else { "$me[${white}mBench${me}[0m" } } }; Align = 'left' },
                            @{Label = "BTC`|$($Rates.Coin)`|$($Rates.Currency)/Day"; Expression = { "$me[${white}m$($($_.Profit) | ForEach-Object { if ($null -ne $_) { $_.ToString("N5") }else { "Bench" } })${me}[0m`|$me[${cyan}m$($($_.Profit) | ForEach-Object { if ($null -ne $_) { ($_ / $Rates.Exchange).ToString("N5") }else { "Bench" } } )${me}[0m`|$me[${green}m$($($_.Profit) | ForEach-Object { if ($null -ne $_) { ($_ * $Rates.Rate).ToString("N2") }else { "Bench" } })${me}[0m" }; Align = 'center' },
                            @{Label = "Pool"; Expression = { 
                                    "$(
                                    $Pool = $_.MinerPool
                                    switch ($Pool) {
                                "nicehash" { "$me[${yellow}m$($Pool)${me}[0m" }
                                "zergpool" { "$me[${green}m$($Pool)${me}[0m" }
                                "nlpool" { "$me[${blue}m$($Pool)${me}[0m" }
                                "blazepool" { "$me[${red}m$($Pool)${me}[0m" }
                                "ahashpool" { "$me[${orange}m$($Pool)${me}[0m" }
                                "blockmasters" { "$me[${cyan}m$($Pool)${me}[0m" }
                                "fairpool" { "$me[${white}m$($Pool)${me}[0m" }
                                "hasrefinery" { "$me[${magenta}m$($Pool)${me}[0m" }
                                "zpool" { "$me[${gray}m$($Pool)${me}[0m" }
                                "whalesburg" { "$me[${pink}m$($Pool)${me}[0m" }
                                "hashrent" { "$me[${white}m$($Pool)${me}[0m" }
                                "mph" { "$me[${orange}m$($Pool)${me}[0m" }
                            })"
                                }; 
                                Align = 'center'
                            },
                            @{Label = "Shares"; Expression = { $($_.Shares -as [Decimal]).ToString("N2") }; Align = 'center' }
                        )
                    }
                    elseif ($VolumeTable) {
                        $Get += $Miner_Table | Sort-Object -Property Profit -Descending | Format-Table -GroupBy Type (
                            @{Label = "Miner`|Coin"; Expression = { "$me[${white}m$($global:index) $($_.Name)${me}[0m`|$me[${green}m$($_.ScreenName.replace("cryptonight","cn").replace("cnight","cn"))${me}[0m"; $global:index += 1 }; Align = 'left' },
                            @{Label = "Speed"; Expression = { $($_.HashRates) | ForEach-Object { if ($null -ne $_) { "$me[${white}m$($_ | Global:ConvertTo-Hash)/s${me}[0m" }else { "$me[${white}mBench${me}[0m" } } }; Align = 'left' },
                            @{Label = "BTC`|$($Rates.Coin)`|$($Rates.Currency)/Day"; Expression = { "$me[${white}m$($($_.Profit) | ForEach-Object { if ($null -ne $_) { $_.ToString("N5") }else { "Bench" } })${me}[0m`|$me[${cyan}m$($($_.Profit) | ForEach-Object { if ($null -ne $_) { ($_ / $Rates.Exchange).ToString("N5") }else { "Bench" } } )${me}[0m`|$me[${green}m$($($_.Profit) | ForEach-Object { if ($null -ne $_) { ($_ * $Rates.Rate).ToString("N2") }else { "Bench" } })${me}[0m" }; Align = 'center' },
                            @{Label = "Pool"; Expression = { 
                                    "$(
                                    $Pool = $_.MinerPool
                                    switch ($Pool) {
                                "nicehash" { "$me[${yellow}m$($Pool)${me}[0m" }
                                "zergpool" { "$me[${green}m$($Pool)${me}[0m" }
                                "nlpool" { "$me[${blue}m$($Pool)${me}[0m" }
                                "blazepool" { "$me[${red}m$($Pool)${me}[0m" }
                                "ahashpool" { "$me[${orange}m$($Pool)${me}[0m" }
                                "blockmasters" { "$me[${cyan}m$($Pool)${me}[0m" }
                                "fairpool" { "$me[${white}m$($Pool)${me}[0m" }
                                "hasrefinery" { "$me[${magenta}m$($Pool)${me}[0m" }
                                "zpool" { "$me[${gray}m$($Pool)${me}[0m" }
                                "whalesburg" { "$me[${pink}m$($Pool)${me}[0m" }
                                "hashrent" { "$me[${white}m$($Pool)${me}[0m" }
                                "mph" { "$me[${orange}m$($Pool)${me}[0m" }
                            })"
                                }; 
                                Align = 'center'
                            },
                            @{Label = "Vol."; Expression = { $($_.Volume) | ForEach-Object { if ($null -ne $_) { "$([math]::Round(100 - $_,0).ToString())`%" }else { "Bench" } } }; Align = 'left' }
                        )
                    }
                    else {
                        $Get += $Miner_Table | Sort-Object -Property Profit -Descending | Format-Table -GroupBy Type (
                            @{Label = "Miner`| Coin"; Expression = { "$me[${white}m$($global:index) $($_.Name)${me}[0m`|$me[${green}m$($_.ScreenName.replace("cryptonight","cn").replace("cnight","cn"))${me}[0m"; $global:index += 1 }; Align = 'left' },
                            @{Label = "Speed"; Expression = { $($_.HashRates) | ForEach-Object { if ($null -ne $_) { "$me[${white}m$($_ | Global:ConvertTo-Hash)/s${me}[0m" }else { "$me[${white}mBench${me}[0m" } } }; Align = 'left' },
                            @{Label = "BTC`|$($Rates.Coin)`|$($Rates.Currency)/Day"; Expression = { "$me[${white}m$($($_.Profit) | ForEach-Object { if ($null -ne $_) { $_.ToString("N5") }else { "Bench" } })${me}[0m`|$me[${cyan}m$($($_.Profit) | ForEach-Object { if ($null -ne $_) { ($_ / $Rates.Exchange).ToString("N5") }else { "Bench" } } )${me}[0m`|$me[${green}m$($($_.Profit) | ForEach-Object { if ($null -ne $_) { ($_ * $Rates.Rate).ToString("N2") }else { "Bench" } })${me}[0m" }; Align = 'center' },
                            @{Label = "Pool"; Expression = { 
                                    "$(
                                    $Pool = $_.MinerPool
                                    switch ($Pool) {
                                "nicehash" { "$me[${yellow}m$($Pool)${me}[0m" }
                                "zergpool" { "$me[${green}m$($Pool)${me}[0m" }
                                "nlpool" { "$me[${blue}m$($Pool)${me}[0m" }
                                "blazepool" { "$me[${red}m$($Pool)${me}[0m" }
                                "ahashpool" { "$me[${orange}m$($Pool)${me}[0m" }
                                "blockmasters" { "$me[${cyan}m$($Pool)${me}[0m" }
                                "fairpool" { "$me[${white}m$($Pool)${me}[0m" }
                                "hasrefinery" { "$me[${magenta}m$($Pool)${me}[0m" }
                                "zpool" { "$me[${gray}m$($Pool)${me}[0m" }
                                "whalesburg" { "$me[${pink}m$($Pool)${me}[0m" }
                                "hashrent" { "$me[${white}m$($Pool)${me}[0m" }
                                "mph" { "$me[${orange}m$($Pool)${me}[0m" }
                            })"
                                }; 
                                Align = 'center'
                            }
                        )
                    }
                }
            }
        }
        $MSFile = ".\debug\minerstats.txt"
        if (test-Path ".\debug\minerstats.txt") { $Get += Get-Content ".\debug\minerstats.txt" }
        Remove-Module "hashrates"
        $Get += ""
        $Get += "If you would like to have this to continue to refresh every 30 seconds- Use 'nview get stats -n 30'"
    }
    "charts" { if (Test-Path ".\debug\charts.txt") { $Get += Get-Content ".\debug\charts.txt" } }
    "active" {
        if (Test-Path ".\debug\mineractive.txt") { $Get += Get-Content ".\debug\mineractive.txt" }
        else { $Get += "No Miner History Found" }
    }
    "parameters" {
        if (Test-Path ".\config\parameters\newarguments.json") { $FilePath = ".\config\parameters\newarguments.json" }
        else { $FilePath = ".\config\parameters\commandline.json" }
        if (Test-Path $FilePath) {
            $SwarmParameters = @()
            $MinerArgs = Get-Content $FilePath | ConvertFrom-Json
            $MinerArgs | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | Foreach { $SwarmParameters += "$($_): $($MinerArgs.$_)" }
        }
        else { $SwarmParameters += "No Parameters For SWARM found" }
        if ($argument2 -eq "json") {
            if ($argument3 -eq "decompress") {
                $Get += $MinerArgs | ConvertTo-Json -Depth 5
            }
            else {
                $Get += $MinerArgs | Convertto-Json -Depth 5 -Compress
            }
        }
        else {
            $Get += $SwarmParameters
        }
    }
    "oc" {
        if (Test-Path ".\debug\oc-settings.txt") { $Get += Get-Content ".\debug\oc-settings.txt" }
        else { $Get += "No oc settings found" }
    }
    "miners" {
        $GetJsons = Get-ChildItem ".\config\miners" | Where-Object Extension -ne ".md"
        $ConvertJsons = [PSCustomObject]@{ }
        $GetJsons.Name | foreach { $Getfile = Get-Content ".\config\miners\$($_)" | ConvertFrom-Json; $ConvertJsons | Add-Member $Getfile.Name $Getfile -Force }
        if ($argument2) {
            $Get += "Current $Argument2 Miner List:"
            $Get += " "   
            $ConvertJsons.PSObject.Properties.Name | Where-Object { $ConvertJsons.$_.$Argument2 } | foreach { $Get += "$($_)" }
            $Selected = $ConvertJsons.PSObject.Properties.Name | Where-Object { $_ -eq $Argument3 } | % { $ConvertJsons.$_ }
            if ($Selected) {
                $Platform = Get-Content ".\debug\os.txt"
                if ($argument2 -like "*NVIDIA*") {
                    $Number = $argument2 -Replace "NVIDIA", ""
                    if ($Platform -eq "linux") {
                        $UpdateJson = Get-Content ".\config\update\nvidia-linux.json" | ConvertFrom-Json
                    }
                    else { $UpdateJson = Get-Content ".\config\update\nvidia-win.json" | ConvertFrom-JSon }
                }
                if ($argument2 -like "*AMD*") {
                    $Number = $argument2 -Replace "AMD", ""
                    switch ($Platform) {
                        "linux" { $UpdateJson = Get-Content ".\config\update\amd-linux.json" | ConvertFrom-Json }
                        "windows" { $UpdateJson = Get-Content ".\config\update\amd-win.json" | ConvertFrom-Json }
                    }
                }
                if ($argument2 -like "*CPU*") {
                    $Number = 1
                    switch ($Platform) {  
                        "linux" { $UpdateJson = Get-Content ".\config\update\cpu-linux.json" | ConvertFrom-Json }
                        "windows" { $UpdateJson = Get-Content ".\config\update\cpu-win.json" | ConvertFrom-Json }
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
        $Dir = Convert-Path "."
        Write-Host "Starting Update Request"
        Write-Host "Note, this process can take over a minute. Be patient and await output..."
        if ($IsWindows) {
            $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
            $Check = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        }
        elseif ($IsLinux) {
            if ($IsLinux) { $Global:EUID = (Invoke-Expression "bash -c set" | Where {$_ -like "*EUID*"} | ConvertFrom-StringData).EUID }
            $Check = $EUID -eq 0;
        }
        
        if ($Check -ne $false) {
            ## Stop Autofan
            $ID = ".\build\pid\autofan.txt"
            if (Test-Path $ID) { $Agent = Get-Content $ID }
            if ($Agent) { $BackGroundID = Get-Process | Where id -eq $Agent }
            if ($BackGroundID.name -eq "pwsh") { Stop-Process $BackGroundID | Out-Null }                   

            $Failed = $false;
            $Endlink = $null;
            $Dir = Convert-Path "."
        
            ## Get Current Version
            $Current = (Get-Content ".\h-manifest.conf" | ConvertFrom-StringData).CUSTOM_VERSION;
        
            ## Find next version
            $version_number = $Current -replace "SWARM.", "";
            $version1 = $version_number[4];
            $version1 = $version1 | % { iex $_ };
            $version1 = $version1 + 1;
            $version2 = $version_number[2];
            $version3 = $version_number[0];
            if ($version1 -eq 10) {
                $version1 = 0; 
                $version2 = $version2 | % { iex $_ };
                $version2 = $version2 + 1;
            }
            if ($version2 -eq 10) {
                $version2 = 0; 
                $version3 = $version3 | % { iex $_ };
                $version3 = $version3 + 1;
            }
            $version_number = "$version3.$version2.$version1"
            if ($IsWindows) { $New = "SWARM.$version_number.windows.zip" }
            elseif ($IsLinux) { $New = "SWARM.$version_number.linux.tar.gz" }
        
            ## If user supplied argument, then we use that instead
            if ($argument2) {
                $EndLink = split-path $argument2 -Leaf        
                if ($EndLink -like "*SWARM*") {
                    $version_number = $EndLink.Replace("SWARM.", "")
                    $version_number = $version_number.Replace(".windows.zip", "")
                    $version_number = $version_number.Replace(".linux.tar.gz", "")
                }
                else {
                    $Failed = $true
                    $Get += "Detected link supplied did not end with SWARM"
                    break
                }
            }
        
            if ($IsWindows) { $New = "SWARM.$version_number.windows.zip" }
            elseif ($IsLinux) { $New = "SWARM.$version_number.linux.tar.gz" }
        
            $Get += "Current Version of SWARM is $Current"
            $Get += "User requested version of swarm is $New" 
        
            $Base_Dir = (Split-Path $Dir)
            $Get += "Main Working Directory is $Base_Dir"
        
            ## Make x64 directory if there is none
            if (-not (test-path "x64")) {
                New-Item "x64" -ItemType Directory | Out-Null
            }
        
            $Extract = $new.Replace('.zip', '')
            $Extract = $Extract.Replace('.tar.gz', '')
        
            $Download_File = Join-Path "$Dir" "x64\$New"
            $Extract_Path = Join-Path "$Dir" "x64\$Extract"
            $URI = "https://github.com/MaynardMiner/SWARM/releases/download/v$version_number/$new"
        
            $Get += "SWARM update will be downloaded to $Download_File"
            $Get += "SWARM update will be extracted to $Extract_Path"
            $Get += "Contacting $URI for download. Timeout For Download is 60 seconds...."
        
            ## Remove old attempts, if they exist.
            if (Test-Path $Download_File) {
                Remove-Item $Download_File -Force -Recurse
            }
            if (Test-Path $Extract_Path) {
                Remove-Item $Extract_Path -Recurse -Force
            }
        
            ## Attempt to download SWARM
            try { 
                Invoke-WebRequest $URI -OutFile $Download_File -SkipCertificateCheck -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop 
            }
            catch [System.Net.WebException] { 
                $Failed = $true; 
                $Get += "Failed To Contact Github For Download! Must Do So Manually"
                $statusCodeInt = [int]$response.BaseResponse.StatusCode
                $Get += "$statusCodeInt`: $($_.Exception.Message)"
                $Get += "$($_.Exception.Response)"
            }
        
            ## Place a pause, as it was found that it can be slow to write file
            $Get += "Waiting 5 seconds for file to save."
            Start-Sleep -S 5
        
            ## Extract The FIles.
            ## Test if they were Successful.
            ## Find Actual File Path to SWARM root directory.
            if ($Failed -eq $false) {
                if ($New -like "*.zip*") {
                    $Get += "Using 7z to extract .zip file.."
                    $Proc = Start-Process "$Dir\build\apps\7z\7z.exe" "x `"$($Download_File)`" -o`"$($Extract_Path)`" -y" -PassThru -WindowStyle Minimized
                    $Proc | Wait-Process
                    Start-Sleep -S 3
                }
                elseif ($New -like "*.tar.gz*") {
                    $Proc = Start-Process "tar" -ArgumentList "-xzvf x64/$Download_File -C x64/$Extract_Path" -PassThru; 
                    $Proc | Wait-Process
                    Start-Sleep -S 3
                }
                $test = [IO.Directory]::Exists($Extract_Path)
                if ($Test) {
                    $Search = Get-ChildItem -Path "$Extract_Path" -Filter "SWARM.bat" -Recurse -ErrorAction SilentlyContinue
                    if ($Search) {
                        $Final_Extract_Path = Split-Path($Search.FullName);
                    }
                    else {
                        $Failed = $true
                        $Get += "SWARM extracted to $Extract_Path, but SWARM.bat was missing."
                    }
                }
                else {
                    $Failed = $true
                    $Get += "Failed To Extract $New"
                }
            }
            else {
                $Get += "SWARM Failed To Download. Please Wait Some Time And Try Again."
            }
        
            if ($Failed -eq $False) {
                ## Remove compressed file- No longer needed.
                $Get += "Removing $Download_File"
                if (Test-Path $Download_File) { Remove-Item $Download_File -Recurse -Force }
        
                ## Now we need to stop miner to prevent any read access issues.
                if (Test-Path "$Dir\build\pid\miner_pid.txt") {
                    $MinerFile = Get-Content "$Dir\build\pid\miner_pid.txt"
                    if ($MinerFile) { $MinerId = Get-Process | Where-Object Id -eq $MinerFile }
                    if ($MinerID) { Stop-Process $MinerId -Force }
                    $Get += "Stopping Old Miner and waiting 5 seconds`n"
                    Start-Sleep -S 5
                }
                
                ## stop miner if linux.
                if ($ISLinux) { Invoke-Expression "miner stop" }
        
                $Get += "Downloaded and extracted SWARM Successfully. Attempting to move file to $Base_Dir"
        
                ## Check SWARM.bat For new change.
                $Bat_file = Get-Content (Join-Path $Dir "SWARM.bat")
                if ($Bat_file) {
                    if ($Bat_file[1] -ne "cd `/D `%`~dp0") {
                        $Get += "Appending old bat file."
                        $Bat_file[1] = "cd `/D `%`~dp0"
                    }
                    $Bat_file.replace("pwsh-preview -executionpolicy Bypass","pwsh -executionpolicy Bypass")
                }
                $Bat_file | Set-Content "$Dir\SWARM.bat"

                if (test-path (Join-Path $Dir "SWARM Terminal.bat")) {
                    $Bat_file = Get-Content (Join-Path $Dir "SWARM Terminal.bat")
                    if ($Bat_file) {
                        if ($Bat_file[1] -ne "cd `/D `%`~dp0") {
                            $Get += "Appending old bat file."
                            $Bat_file[1] = "cd `/D `%`~dp0"
                        }
                    }
                    $Bat_file | Set-Content "$Dir\SWARM Terminal.bat"
                    Copy-Item "$Dir\SWARM Terminal.bat" -Destination $Final_Extract_Path -Force
                }
        
                ## Move .bat file into extracted path
                Copy-Item "$Dir\SWARM.bat" -Destination $Final_Extract_Path -Force
        
                ## Move parameters into extracted path
                $Params = Join-Path $Final_Extract_Path "config\parameters"
                if (Test-Path ".\config\parameters\newarguments.json") { $New_Params = ".\config\parameters\newarguments.json" }
                else { $New_Params = ".\config\parameters\commandline.json" }
        
                Copy-Item $New_Params -Destination $Params -Force
                $Get += "Copied $New_Params to new SWARM version"
        
                ## Copy Preivious Running PIDs
                if (test-path "$Dir\build\pid") { Copy-Item "$Dir\build\pid" -Destination "$Final_Extract_Path\build\pid" -recurse -Force }
                $Get += "Copied Previous Process Data To SWARM."
        
                ## Move to base directory
                ## Delete if it exists already
                $New_Path = Join-Path $Base_Dir $Extract
                $New_Bat = Join-Path $New_Path "SWARM.bat"
                if (test-path $New_Path) { Remove-Item $New_Path -Recurse -Force | Out-Null }
                Move-Item $Final_Extract_Path -Destination $Base_Dir -Force | Out-Null
                if (Test-Path $Extract_Path) { Remove-Item $Extract_path -recurse -Force | Out-Null }
        
                if (Test-Path $New_Path) {
                    $Get += "Successfully moved old data into new version and to base directory"
                    $Get += "Removed $Extract_Path.."
                }
                else {
                    $Get += "failed to move old data into new version and move to base directory"
                    $Get += "Removed $Extract_Path.."
                    break
                }
        
                ## If windows, we start the bat.
                ## In linux, we run install_linux, then start the bat.
                $Get += "Setting new SWARM_PATH environment variable to dir $New_Path."
                $Target1 = [System.EnvironmentVariableTarget]::Machine
                $Target2 = [System.EnvironmentVariableTarget]::Process
                [System.Environment]::SetEnvironmentVariable('SWARM_DIR', $New_Path, $Target1)
                [System.Environment]::SetEnvironmentVariable('SWARM_DIR', $New_Path, $Target2)
        
                ## By stopping explorer, it restarts retroactively with path refreshed
                ## for commands.
                Stop-Process -ProcessName explorer
        
                if ($IsWindows) {
                    ## Update icons
                    $Exec_Shortcut = [IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "SWARM.lnk")
                    $Term_Shortcut = [IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "SWARM terminal.lnk")
                                
                    if (test-Path $Exec_Shortcut) { Remove-Item $Exec_Shortcut -Force | Out-Null }
                    if (test-Path $Term_Shortcut) { Remove-Item $Term_Shortcut -Force | Out-Null }

                    $WshShell = New-Object -comObject WScript.Shell

                    $Shortcut = $WshShell.CreateShortcut($Exec_Shortcut)
                    $Shortcut.TargetPath = $New_Bat
                    $Shortcut.WorkingDirectory = $New_Path
                    $Shortcut.IconLocation = Join-Path $New_Path "build\apps\icons\SWARM.ico"
                    $Shortcut.Description = "Shortcut For SWARM.bat. You can right-click -> edit this shortcut"
                    $Shortcut.Save()
                
                    $Shortcut = $WshShell.CreateShortcut($Term_Shortcut)
                    $Shortcut.TargetPath = join-path $New_Path "SWARM Terminal.bat"
                    $Shortcut.WorkingDirectory = $New_Path
                    $Shortcut.IconLocation = Join-Path $New_Path "build\apps\icons\comb.ico"
                    $Shortcut.Description = "Shortcut To Open Terminal For SWARM. Will Run As Administrator"
                    $Shortcut.Save()

                    $bytes = [System.IO.File]::ReadAllBytes($Exec_Shortcut)
                    $bytes[0x15] = $bytes[0x15] -bor 0x20
                    [System.IO.File]::WriteAllBytes($Exec_Shortcut, $bytes)
                
                    $bytes = [System.IO.File]::ReadAllBytes($Term_Shortcut)
                    $bytes[0x15] = $bytes[0x15] -bor 0x20
                    [System.IO.File]::WriteAllBytes($Term_Shortcut, $bytes)                
                                
                    $Get += "Icons On Desktop Were Updated"
                    Start-Process $New_Bat
                    $Get += "Started $New_Bat"
                }
                elseif ($IsLinux) {
                    $Proc = Start-Process "$New_Path\install_linux" -PassThru;
                    $Proc | Wait-Process;
                    $Get += "Ran $New_Path\install_Linux"
                    invoke-expression "miner start"
                }
            }
        }
        else {
            $Get += "Could not perform update- Access Denied. Are you administrator/root user?"
        }
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