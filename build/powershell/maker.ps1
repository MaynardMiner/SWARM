

function set-nicehash {
  param(
    [Parameter(Position=0,Mandatory=$false)]
    [String]$NHPool,
    [Parameter(Position=1, Mandatory=$false)]
    [String]$NHPort,
    [Parameter(Position=2,Mandatory=$false)]
    [String]$NHUser,
    [Parameter(Position=3,Mandatory=$false)]
    [String]$NHAlgo,
    [Parameter(Position=4,Mandatory=$false)]
    [String]$CommandFile,
    [Parameter(Position=5,Mandatory=$false)]
    [String]$NHDevices
  )
##apt-get install ocl-icd-libopencl1
##sudo dpkg -i excavator_1.5.13a-cuda10_amd64.deb
## run excavator nhmp.usa.nicehash.com:3200
##$NHPool = "nhmp.usa.nicehash.com"
##$NHPort = 3200
##$NHUser = "34HKWdzLxWBduUfJE9JxaFhoXnfC6gmePG.testrig"
##$NHAlgo = "equihash"
##$CommandFile = ".\bin\excavator-1\command.json"
##$NHDevices = "0,2,6,9,10"

$NHMDevices = Get-DeviceString -TypeDevices $NHDevices
$Workers = @()
$Workers += @{time = 0;commands = @(@{id= 1; method= "subscribe"; params= [array]"$($NHPool):$($NHPort)","$($NHUser)"})}
$Workers += @{time=2; commands=@(@{id=1; method = "algorithm.add"; params=@($NHAlgo)})}
$NHMDevices | foreach {$Workers += @{time = 3; commands = @(@{id = 1; method = "worker.add"; params = [array]"$NHAlgo","$($_)";})}}
$NHMDevices | Foreach {$Workers += @{time = 10; loop = 10; commands =@(@{id=1; method="worker.print.speed"; params=@("$($_)")})}}

$Workers | ConvertTo-Json -Depth 4 | Set-Content $CommandFile

}