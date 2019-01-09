##This file is for users that want to add their own custom pool to SWARM.
##This will allow only for 1 coin to be mined per each pool.
##Requiremnets:
##1.) Pool must be have an api to gather the coin's stats.
##2.) User must have a wallet for the particular coin.
##3.) There must currently be a miner in SWARM to mine algorithm.
##4.) User must be familar with how API on their pool work.
##5.) Currently only works for yiimp pools. Will add more.
##    Pools such as bsod.pw or icemining.ca can be used.

## You can use this file more than once.
## To do so- copy file, and then change the name.
## No .ps1's can have the same name, or you
## will generate errors.


##Below is the Custom Config Script- Do not change.
$Pool = {

##Your denoted name/nickname for the pool.
##
Name = LamboPool
##
##Where to direct miner. Do not include stratum+tcp:/ here
##
Miner_Url = us.get.lambopool.com
##
##Port for mining
##
Miner_Port = 3333
##
##This is the link for api
##Examples:
##
##  https://icemining.ca/api/currencies
##  http://api.bsod.pw/api/currencies
##
Pool_Uri = "http://api.lambopool.com/api/currencies"
##
##This is the coin you wish to mine. Must use symbol from pool.
##
Coin = RVN
##
##This is the algorithm of that coin.
##lower case characters only!
##This is miner specific! Consult miner!
##
Algo = x16r
##
##This is miner you wish to use.
##miner name much match name of .json
##Located in config < miners folder
##
Miner = enemy
##
##Use your custom address here.
##Use Do Do_Not_Use if you
##You are not using NVIDIA2 or NVIDIA3.
##
Wallet1 = 123lkjsdh12322089sd01092800
Wallet2 = Do_Not_Use
Wallet3 = Do_Not_Use
##
##This is your rig pass setting for pool.
##Must be in ' '
Pass = c=BTC,ID=SWARM
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
$Custom_Request = [PSCustomObject]@{} 
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" 

##First lets make sure miner has algorithm. If not, add it.
try{$MinerFile = Get-Content ".\config\miners\$($Pool.Miner).json" | ConvertFrom-Json}
catch{Write-Warning "could not find miner"; break}
$MinerData | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {}
