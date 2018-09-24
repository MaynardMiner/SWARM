$Path = "$($nvidia.enemy.path1)"
$Uri = "$($nvidia.enemy.uri)"
$MinerName = "$($nvidia.enemy.MinerName)"



$Build = "Tar"

if($CCDevices1 -ne ''){$Devices = $CCDevices1}
if($GPUDevices1 -ne ''){$Devices = $GPUDevices1}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

#Algorithms
#X16R
#X16S
#Aergo

$Commands = [PSCustomObject]@{

  "aergo" = ''
  "hex" = ''
  "timetravel" = ''
  "xevan" = ''
  "sonoa" = ''
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
    Type = "NVIDIA1"
    Path = $Path
    Devices = $Devices
    DeviceCall = "ccminer"
    Arguments = "-a $(Get-Nvidia($_)) -o stratum+tcp://$($AlgoPools.$_.Host):$($AlgoPools.$_.Port) -b 0.0.0.0:4068 -u $($AlgoPools.$_.User1) -p $($AlgoPools.$_.Pass1) $($Commands.$_)"
    HashRates = [PSCustomObject]@{$_ = $Stats."$($Name)_$($_)_HashRate".Day}
    Selected = [PSCustomObject]@{$_ = ""}
    Port = 4068
    MinerPool = "$($AlgoPools.$_.Name)"
    FullName = "$($AlgoPools.$_.Mining)"
    API = "Ccminer"
    Wrap = $false
    URI = $Uri
    BUILD = $Build
    Stats = "ccminer"
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
   Coin = "Yes"
   Symbol = "$($CoinPools.$_.Symbol)"
   MinerName = $MinerName
   Type = "NVIDIA1"
   Path = $Path
   Devices = $Devices
   DeviceCall = "ccminer"
   Arguments = "-a $(Get-Nvidia($CoinPools.$_.Algorithm)) -o stratum+tcp://$($CoinPools.$_.Host):$($CoinPools.$_.Port) -b 0.0.0.0:4068 -u $($CoinPools.$_.User1) -p $($CoinPools.$_.Pass1) $($Commands.$($CoinPools.$_.Algorithm))"
   HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_HashRate".Day}
   API = "Ccminer"
   Selected = [PSCustomObject]@{$($CoinPools.$_.Algorithm) = ""}
   FullName = "$($CoinPools.$_.Mining)"
   MinerPool = "$($CoinPools.$_.Name)"
   Port = 4068
   Wrap = $false
   URI = $Uri
   BUILD = $Build
   Algo = "$($CoinPools.$_.Algorithm)"
   }
  }
 }
