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
$Get = @()

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
    if you are unsure of miner name, running-

    get miners [platform]
    
    to see all miners for that platform

    param:
    [prestart] [commands] [difficulty] [naming]   [oc]

    sub-param1   [algo]     [algo]      [algo]   [algo]

    sub-param2                                   [power]
                                                 [core]
                                                 [mem]
                                                 [dpm]
                                                  [v]
                                                 [mdpm]

   example uses of sub-params:

   get miners NVIDIA1 enemy naming 
   (Will list all naming items)

   get miners NVIDIA1 enemy oc hex core 
   (Will list core for hex algorithm)

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

    get parameters [name]

    OPTIONS:

    name:
    name of parameter you wish to view. If you are unsure,
    specify 'all'

to see all available SWARM commands, go to:

https://github.com/MaynardMiner/SWARM/wiki/HiveOS-management

current windows commands:

get help
get benchmarks
get oc
get active
get stats
get screen
reboot
version
benchmark 

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
 function Get-BenchTable {
  $BenchTable | Sort-Object -Property Algo -Descending | Format-Table (
  @{Label = "Miner"; Expression={$($_.Miner)}},
  @{Label = "Algorithm"; Expression={$($_.Algo)}},
  @{Label = "Speed"; Expression={$($_.HashRates)}}    
)
 }
Get-BenchTable | Out-File ".\build\txt\get.txt"
}
 else{$Get = "No Stats Found"}
}
"stats"
{
if(Test-Path ".\build\bash\minerstats.sh"){$Get = Get-Content ".\build\bash\minerstats.sh"}
else{$Get = "No Stats History Found"}

}
"active"
{
if(Test-Path ".\build\bash\mineractive.sh"){$Get = Get-Content ".\build\bash\mineractive.sh"}
else{$Get = "No Miner History Found"}
}
"parameters"
{
if(Test-Path ".\config\parameters\arguments.json")
 {
  $SwarmParameters =@()
  $MinerArgs = Get-Content ".\config\parameters\arguments.json" | ConvertFrom-Json
  $MinerArgs | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | Foreach{$SwarmParameters += "$($_): $($MinerArgs.$_)"}
 }
 else{$SwarmParameters += "No Parameters For SWARM found"}
 $Get = $SwarmParameters
}
"screen"
{
 if(Test-Path ".\logs\$($argument2).log"){$Get = Get-Content ".\logs\$($argument2).log"}
 if($argument2 -eq "miner"){if(Test-Path ".\logs\*active*"){$Get = Get-Content ".\logs\*active.log*"}}
 $Get = $Get | Select -Last 300
}
"oc"
{
 if(Test-Path ".\build\txt\oc-settings.txt"){$Get = Get-Content ".\build\txt\oc-settings.txt"}
 else{$Get = "No oc settings found"}
}
"miners"
{
 $GetJsons = Get-ChildItem ".\config\miners"
 $ConvertJsons = [PSCustomObject]@{}
 $GetJsons | foreach{$Getfile = Get-Content $_ | ConvertFrom-Json; $ConvertJsons | Add-Member $Getfile.Name $(Get-Content $_ | ConvertFrom-Json)}
if($argument2)
 {
 $Get += "Current $Argument2 Miner List:"
 $Get += " "   
 $ConvertJsons.PSObject.Properties.Name | Where {$ConvertJsons.$_.$Argument2} | foreach{$Get += "$($_)"}
 $Selected = $ConvertJsons.PSObject.Properties.Name | Where {$_ -eq $Argument3} | %{$ConvertJsons.$_}
 if($Selected)
 {
    $Cuda = Get-Content ".\build\txt\cuda.txt"
    $Platform = Get-Content ".\build\txt\os.txt"
     if($argument2 -like "*NVIDIA*")
      {
       $Number = $argument2 -Replace "NVIDIA",""
       if($Platform -eq "linux")
       {
        switch($Cuda)
        {
         "9.2"{$UpdateJson = Get-Content ".\config\update\nvidia9.2-linux.json" | ConvertFrom-Json}
         "10"{$UpdateJson = Get-Content ".\config\update\nvidia10-linux.json" | ConvertFrom-Json}
        }
       }
       else{$UpdateJson = Get-Content ".\config\update\nvidia-win.json" | ConvertFrom-JSon}
      }
     if($argument2 -like "*AMD*")
     {
      $Number = $argument2 -Replace "AMD",""
      switch($Platform)
      {
        "linux"{$UpdateJson = Get-Content ".\config\update\amd-linux.json" | ConvertFrom-Json}
        "windows"{$UpdateJson = Get-Content ".\config\update\amd-windows.json" | ConvertFrom-Json}
      }
     }
     if($argument3 -like "*CPU*")
      {
        $Number = 1
        switch($Platform)
        {  
        "linux"{$UpdateJson = Get-Content ".\config\update\cpu-linux.json" | ConvertFrom-Json}
        "windows"{$UpdateJson = Get-Content ".\config\update\cpu-windows.json" | ConvertFrom-Json}
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
    if($Argument4)
     {
      if($argument5)
      {
        $Get += " "
        $Get += "Getting: $Argument1 $Argument2 $Argument3 $Argument4 $Argument5"
        $Get += " "
        $Get += if($selected.$argument2.$argument4.$argument5){$selected.$argument2.$argument4.$argument5}else{"none"}
      }
      elseif($argument6)
      {
          $Get += " "
          $Get += "Getting: $Argument1 $Argument2 $Argument3 $Argument4 $Argument5 $Argument6"
          $Get += " "
          $Get += if($selected.$argument2.$argument4.$argument5.$Arguement6){$selected.$argument2.$argument4.$argument5.$Arguement6}else{"none"}
      }
     else
      {
          $Get += " "
          $Get += "Getting: $Argument1 $Argument2 $Argument3 $Argument4"
          $Get += " "
          $Get += if($selected.$argument2.$argument4){$selected.$argument2.$argument4}else{"none"}
      }
     }  
    }
   }
   else{$Get += "No Platforms Selected: Please choose a platform NVIDIA1,NVIDIA2,NVIDIA3,AMD1,CPU"}
  }

default
{
 $Get =
"item not found or specified. use:

get help

to see a list of availble items.
"
}
}

if($get -ne $null)
{
$Get
$Get | Out-File ".\build\txt\get.txt"
}
