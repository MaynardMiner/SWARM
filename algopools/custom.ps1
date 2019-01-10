##This file is for users that want to add their own custom pool to SWARM.
##This will allow only for 1 coin to be mined per each pool.
##Requiremnets:
##1.) Pool must be have an api to gather the coin's stats.
##2.) User must have a wallet for the particular coin.
##3.) There must currently be a miner in SWARM to mine algorithm.
##4.) User must be familar with how API on their pool work.
##5.) Currently only works for yiimp pools. Will add more.
##6.) Currently only 1 extra coin per file.
##7.) I do not reccommend using the same pool at this moment twice.
##    Pools such as bsod.pw or icemining.ca can be used.
##    This is sample, I am working on better system.

## You can use this file more than once.
## To do so- copy file, and then change the name.
## No .ps1's can have the same name, or you
## will generate errors.


##Below is the Custom Config Script- Do not change.
$Pool = {

##Your denoted name/nickname for the pool.
##
Name = BsoD
##
##Where to direct miner. Do not include stratum+tcp here
##
Miner_Url = us.bsod.pw
##
##Port for mining
##
Miner_Port = 2514
##
##This is the link for api
##Examples:
##
##  https://icemining.ca/api/currencies
##  http://api.bsod.pw/api/currencies
##
Pool_Url = http://api.bsod.pw/api/currencies
##
##This is the coin you wish to mine. Must use symbol from pool.
##
Coin = RYO
##
##This is the algorithm of that coin.
##lower case characters only!
##This is miner specific! Consult miner!
##
Algo = lyra2vc0ban
##
##This is miner you wish to use.
##miner name much match name of .json
##Located in config < miners folder
##
Miner = cryptodredge
##
##Use your custom address here.
##Use Do Do_Not_Use if you
##You are not using NVIDIA2 or NVIDIA3.
##
Wallet1 = RYoKsx2xkXw2x9dDwXxENWaqzraRX7vT1A1arQH2sbU953fRadkg9VG
Wallet2 = RYoKsx2xkXw2x9dDwXxENWaqzraRX7vT1A1arQH2sbU953fRadkg9VG
Wallet3 = RYoKsx2xkXw2x9dDwXxENWaqzraRX7vT1A1arQH2sbU953fRadkg9VG
##
##This is your rig pass setting for pool.
##Must be in ' '
Pass = ID=SWARM
##
##
}
##
##
##
##
##
##
##
##
##
##
##
##The rest is SWARM code. Leave alone
$Pool = $Pool | ConvertFrom-StringData

$Name = $Pool.Name 
if($Poolname -eq $Name)
{
$Custom_Request = [PSCustomObject]@{} 
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" 

##First lets make sure miner has algorithm. If not, add it.
try{$MinerFile = Get-Content ".\config\miners\$($Pool.Miner).json" | ConvertFrom-Json -ErrorAction Stop}
catch{Write-Warning "could not find miner for $name custom pool file"; break}
$Changed = $false
$MinerFile | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
$Algo = $Pool.Algo

if($_ -ne "name")
{
    if($MinerFile.$_.commands -notmatch $Algo){$MinerFile.$_.commands| Add-Member $Algo "" -Force; $Changed = $true}
    if($MinerFile.$_.difficulty -notmatch $Algo){$MinerFile.$_.difficulty | Add-Member $Algo "" -Force; $Changed = $true}
    if($MinerFile.$_.naming -notmatch $Algo){$MinerFile.$_.naming | Add-Member $Algo "$Algo" -Force; $Changed = $true}
}

if($Changed -eq $true){$MinerFile | Set-Content ".\config\miners\$($Pool.Miner).json"}
}

## Next we need to add algorithm to naming file:
$Changed = $false
try{$PoolFile = Get-Content ".\config\pools\pool-algos.json" | ConvertFrom-Json -ErrorAction Stop}
catch{Write-Warning "could not find pool algorithms file"; break}
if($PoolFile -notmatch $Pool.Algo){$PoolFile | Add-Member "$($Pool.Algo)" "$($Pool.Algo)" -Force; $Changed = $true}
if($Changed -eq $true){$PoolFile | Set-Content ".\config\miners\pool-algos.json"}

try{$Custom_Request = Invoke-RestMethod "$($Pool.Pool_Url)" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop} 
catch{Write-Warning "SWARM contacted ($Name) for a failed API."; return}

if (($Custom_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) 
{ 
   Write-Warning "SWARM contacted ($Name) but ($Name) Pool API had issues. " 
   return 
}

    $Custom_Algo = $Pool.Algo
    $Coin = $Pool.Coin

    if($Algorithm -eq $Custom_Algo)
    {
    $Custom_Host = "$($Pool.Miner_Url)"
    $Custom_Port = "$($Pool.Miner_Port)"
    $Fees = $Custom_Request.$Coin.fees
    $DayStat = "24h_btc"
    $Workers = $Custom_Request.$Coin.Workers
    $Estimate = if($Stat_Algo -eq "Day"){[Double]$Custom_Request.$Coin.$DayStat*.001}else{[Double]$Custom_Request.$Coin.estimate*.001}
    $Cut = ConvertFrom-Fees $Fees $Workers $Estimate
 
    $SmallestValue = 1E-20
    $Stat = Set-Stat -Name "$($Name)_$($Custom_Algo)_profit" -Value ([Math]::Max([Double]($Estimate-$Cut),$SmallestValue))
    if($Stat_Algo -eq "Day"){$Stats = $Stat.Live}else{$Stats = $Stat.$Stat_Algo}

    [PSCustomObject]@{
        Priority = $Priorities.Pool_Priorities.$Name
        Symbol = $Custom_Algo
        Mining = $Custom_Algo
        Algorithm = $Custom_Algo
        Price = $Stats
        StablePrice = $Stat.Week
        MarginOfError = $Stat.Fluctuation
        Protocol = "stratum+tcp"
        Host = $Custom_Host
        Port = $Custom_Port
        User1 = $Pool.Wallet1
        User2 = $Pool.Wallet2
        User3 = $Pool.Wallet3
        CPUser = $Pool.Wallet1
        CPUPass = $Pool.Pass
        Pass1 = $Pool.Pass
        Pass2 = $Pool.Pass
        Pass3 = $Pool.Pass
        Location = $Location
        SSL = $false
        }
      }    
    }