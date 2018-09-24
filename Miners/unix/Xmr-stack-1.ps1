$Path = "$($amd.xmrstack.path1)"
$Uri = "$($amd.xmrstack.uri)"
$MinerName = "$($amd.xmrstack.minername)"

$Build = "Tar"

if($SGDevices1 -ne ''){$Devices = $SGDevices1}
if($GPUDevices1 -ne ''){$Devices = $GPUDevices1}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

#Algorithms:
#NeoScrypt
#Groestl

$Commands = [PSCustomObject]@{

"cryptonight" = ""
"cryptonightv7" = ""
"cryptonightheavy" = ''

}

if($CoinAlgo -eq $null)
{
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
 if($Algorithm -eq "$($AlgoPools.$_.Algorithm)")
  {
    [PSCustomObject]@{
    Platform = $Platform
    Symbol = "$($_)"
    MinerName = $MinerName
    Type = "AMD1"
    Path = $Path
    Devices = $Devices
    DeviceCall = "xmrstak"
    Arguments = "--currency $(Get-AMD($_)) -i 60045 --url stratum+tcp://$($AlgoPools.$_.Host):$($AlgoPools.$_.Port) --user $($AlgoPools.$_.User1) --pass $($AlgoPools.$_.Pass1) --rigid SWARM --noCPU --use-nicehash $($Commands.$_)"
    HashRates = [PSCustomObject]@{$_ = $Stats."$($Name)_$($_)_HashRate".Day}
    Selected = [PSCustomObject]@{$_ = ""}
    MinerPool = "$($AlgoPools.$_.Name)"
    FullName = "$($AlgoPools.$_.Mining)"
    Port = 60045
    API = "xmrstak"
    Wrap = $false
    URI = $Uri
    BUILD = $Build
    Algo = "$($_)"
    NewAlgo = ''
     }
    }
   }
  }
else{
  $CoinPools | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name |
  Where {$($Commands.$($CoinPools.$_.Algorithm)) -NE $null} |
  foreach {
   [PSCustomObject]@{
   Platform = $Platform
   Symbol = "$($CoinPools.$_.Symbol)"
   MinerName = $MinerName
   Type = "AMD1"
   Path = $Path
   Devices = $Devices
   DeviceCall = "xmrstak"
   Arguments = "--currency $(Get-AMD($_)) -i 60045 --url stratum+tcp://$($CoinPools.$_.Host):$($CoinPools.$_.Port) --user $($CoinPools.$_.User1) --pass $($CoinPools.$_.Pass1) --rigid SWARM --noCPU --use-nicehash $($Commands.$_)"
   HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_HashRate".Day}
   API = "xmrstak"
   Selected = [PSCustomObject]@{$CoinPools.$_.Algorithm = ""}
   FullName = "$($CoinPools.$_.Mining)"
   MinerPool = "$($CoinPools.$_.Name)"
   Port = 60045
   Wrap = $false
   URI = $Uri
   BUILD = $Build
	 Algo = "$($CoinPools.$_.Algorithm)"
   }
  }
 }
