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
   
   remove miners NVIDIA1 trex x16r difficulty
   remove oc NVIDIA1 aergo power
   remove benchmarks all
   remove power all
   remove profits
   remove ban NVIDIA1 trex x16r
   
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
   
   
   benchmarks
    used to remove a current a benchmark.
   
       USES:
   
       remove benchmark [name] [algo]
   
       OPTIONS:
   
       name:
       name of miner, as per the names of .json in config/miners.
   
       algo:
       the algorithm stat you wish to remove.
      
   power
    Used to remove power benchmarks/table. This allows you to remove/reset 
    power settings depending.
   
       USES:
   
       remove power [platform] [type] [algo]
   
       OPTIONS:
   
       platform:
       [NVIDIA1] [NVIDIA2] [NVIDIA3] [AMD1] [CPU]
   
       type:
       [wattometer] [stat]
   
       algo:
       all avaiable algorithms in SWARM"

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
    else{$BenchTable = "No Stats Found"}
    $BenchTable | Out-File ".\build\txt\get.txt"
    $BenchTable
   }
   "stats"
   {
   if(Test-Path ".\build\txt\minerstats.txt"){$Get = Get-Content ".\build\txt\minerstats.txt"}
   else{$Get = "No Stats History Found"}
   $Get | Out-File ".\build\txt\get.txt"
   $Get 
   }
   "active"
   {
   if(Test-Path ".\build\txt\mineractive.txt"){$Get = Get-Content ".\build\txt\mineractive.txt"}
   else{$Get = "No Miner History Found"}
   $Get | Out-File ".\build\txt\get.txt"
   $Get 
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
    $SwarmParameters | Out-File ".\build\txt\get.txt"
    $SwarmParameters
   }
   
   default
   {
    $default =
   "item not found or specified. use:
   
   remove help
   
   to see a list of availble items.
   "
   $default
   $default | out-file ".\build\txt\get.txt"
   }
   }