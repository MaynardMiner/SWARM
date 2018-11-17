param(
        [Parameter(Position=0,Mandatory=$false)]
        [String]$argument1,
        [Parameter(Position=1, Mandatory=$false)]
        [String]$argument2,
        [Parameter(Position=2,Mandatory=$false)]
        [String]$argument3,
        [Parameter(Position=3, Mandatory=$false)]
        [String]$argument4,
        [Parameter(Position=4,Mandatory=$false)]
        [String]$argument5,
        [Parameter(Position=5, Mandatory=$false)]
        [String]$argument6
     )

Set-Location (Split-Path (Split-Path (Split-Path $script:MyInvocation.MyCommand.Path)))

 Switch($argument1)
  {
   "help"
    {
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

    name:
    name of miner, as per the names of .json in config/miners
    if you are unsure of miner name, choose 'all' to identify

    param:
    [prestart] [commands] [difficulty] [naming]   [oc]   [all]

    sub-param1   [algo]     [algo]      [algo]   [algo]  [all]

    sub-param2                                   [power] [all]
                                                 [core]
                                                 [mem]
                                                 [dpm]
                                                  [v]
                                                 [mdpm]

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
 
    name:
    name of miner, as per the names of .json in config/miners
    if you are unsure of miner name, choose 'all' to identify.

benchmarks
 used to view current a benchmark.

    USES:

    get benchmark [name] [algo]

    OPTIONS:

    name:
    name of miner, as per the names of .json in config/miners.

    algo:
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

    platform:
    [NVIDIA1] [NVIDIA2] [NVIDIA3] [AMD1] [CPU]

    type:
    [wattometer] [stat]

    algo:
    all avaiable algorithms in SWARM

paramters
 Used to view SWARM's current parameters/arguments/settings

    USES:

    get parameters [name]/[help]

    OPTIONS:

    name:
    name of parameter you wish to view. If you are unsure,
    specify 'all'

    help:
    views SWARM's argument help file
"
$help
$help | out-file ".\build\txt\get.txt"
    }
"benchmarks"
{
 . .\build\powershell\statcommand.ps1
 . .\build\powershell\childitems.ps1
 . .\build\powershell\hashrates.ps1
 if(Test-path ".\stats")
 {
 switch($argument2)
  {
   "all"
   {
    $StatNames = Get-ChildItem ".\stats" | Where Name -LIKE "*hashrate*"
    $StatNames = $StatNames.Name -replace ".txt",""
    $Stats = [PSCustomObject]@{}
    if(Test-Path "stats"){Get-ChildItemContent "stats" | ForEach {$Stats | Add-Member $_.Name $_.Content}}
   }
   default
   {
    $Stats = [PSCustomObject]@{}
    $StatNames = Get-ChildItem ".\stats" | Where Name -LIKE "*$($argument2)_hashrate.txt*"
    $StatNames = $StatNames.Name -replace ".txt",""
    if(Test-Path "stats"){Get-ChildItemContent "stats" | ForEach {$Stats | Add-Member $_.Name $_.Content}}
   }
  }
 $BenchTable = @()
 $StatNames | Foreach {
  $BenchTable += [PSCustomObject]@{
    Miner = $_ -split "_" | Select -First 1
    Algo = $_ -split "_" | Select -Skip 1 -First 1
    HashRates = $Stats."$($_)".Day | ConvertTo-Hash
  }
 }
 $BenchTable | Sort-Object -Property Algo -Descending | Format-Table (
  @{Label = "Miner"; Expression={$($_.Miner)}},
  @{Label = "Algorithm"; Expression={$($_.Algo)}},
  @{Label = "Speed"; Expression={$($_.HashRates)}}    
)
}
 else{Write-Host "No Stats Found"}
}
"stats"
{
if(Test-Path ".\build\bash\minerstats.sh"){Get-Content ".\build\bash\minerstats.sh"}
else{Write-Host "No Stats History Found"}
}
"active"
{
if(Test-Path ".\build\bash\mineractive.sh"){Get-Content ".\build\bash\mineractive.sh"}
else{Write-Host "No Miner History Found"}    
}
"parameters"
{
if(Test-Path ".\config\parameters\arguments.json")
 {
  $MinerArgs = Get-Content ".\config\parameters\arguments.json" | ConvertFrom-Json
  $MinerArgs | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | Foreach{Write-Host "$($_): $($MinerArgs.$_)"}
 }
 else{Write-Host "No Parameters For SWARM found"}
}

default
{
 $default =
"item not found or specified. use:

get help

to see a list of availble items.
"
$default
$default | out-file ".\build\txt\get.txt"
}
}