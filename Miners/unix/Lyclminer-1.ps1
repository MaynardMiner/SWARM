$Path = "$($amd.lyclminer.path1)"
$Uri = "$($amd.lyclminer.uri)"
$MinerName = "$($amd.lyclminer.minername)"


$Build = "Tar"

if($SGDevices1 -ne ''){$Devices = $SGDevices1}
if($GPUDevices1 -ne ''){$Devices = $GPUDevices1}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

#Algorithms:
#NeoScrypt
#Groestl

$Commands = [PSCustomObject]@{

  "lyra2v2" = ''

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
    DeviceCall = "lyclminer"
    Connection = "$($AlgoPools.$_.Host):$($AlgoPools.$_.Port)"
    Username =  "$($AlgoPools.$_.User1)"
    Password = "$($AlgoPools.$_.Pass1)"
    Arguments = "stratum+tcp://$($AlgoPools.$_.Host):$($AlgoPools.$_.Port) $($AlgoPools.$_.User1) $($AlgoPools.$_.Pass1)"
    HashRates = [PSCustomObject]@{$_ = $Stats."$($Name)_$($_)_HashRate".Day}
    Selected = [PSCustomObject]@{$_ = ""}
    MinerPool = "$($AlgoPools.$_.Name)"
    FullName = "$($AlgoPools.$_.Mining)"
    Port = 0
    API = "lyclminer"
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
   DeviceCall = "lyclminer"
   Connection = "$($CoinPools.$_.Host):$($CoinPools.$_.Port)"
   Username = "$($CoinPools.$_.User1)"
   Password = "$($CoinPools.$_.Pass1)"
   Arguments = "stratum+tcp://$($CoinPools.$_.Host):$($CoinPools.$_.Port) $($CoinPools.$_.User1) $($CoinPools.$_.Pass1)"
   HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_HashRate".Day}
   API = "lyclminer"
   Selected = [PSCustomObject]@{$CoinPools.$_.Algorithm = ""}
   FullName = "$($CoinPools.$_.Mining)"
   MinerPool = "$($CoinPools.$_.Name)"
   Port = 0
   Wrap = $false
   URI = $Uri
   BUILD = $Build
	 Algo = "$($CoinPools.$_.Algorithm)"
   }
  }
 }
