$Path = "$($amd.lyclminer.path1)"
$Uri = "$($amd.lyclminer.uri)"
$MinerName = "$($amd.lyclminer.minername)"


$Build = "Tar"

if($AMDDevices1 -ne ''){$Devices = $AMDDevices1}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands = [PSCustomObject]@{
"lyra2v2" = ''
}

$Difficulty = [PSCustomObject]@{
"lyra2v2" = ''
}

if($CoinAlgo -eq $null)
{
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
  if($Algorithm -eq "$($AlgoPools.$_.Algorithm)")
  {
    if($Difficulty.$_){$Diff=",d=$($Difficulty.$_)"}
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
    Password = "$($AlgoPools.$_.Pass1)$($Diff)"
    Arguments = "stratum+tcp://$($AlgoPools.$_.Host):$($AlgoPools.$_.Port) $($AlgoPools.$_.User1) $($AlgoPools.$_.Pass1)$($Diff)"
    HashRates = [PSCustomObject]@{$_ = $($Stats."$($Name)_$($_)_hashrate".Day)}
    PowerX = [PSCustomObject]@{$_ = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($_)_Power".Day)}elseif($Watts.$($_).AMD1_Watts){$Watts.$($_).AMD1_Watts}elseif($Watts.default.AMD1_Watts){$Watts.default.AMD1_Watts}else{0}}
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
    if($Difficulty.$($CoinPools.$_.Algorithm)){$Diff=",d=$($Difficulty.$($CoinPools.$_.Algorithm))"}
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
   Password = "$($CoinPools.$_.Pass1)$($Diff)"
   Arguments = "stratum+tcp://$($CoinPools.$_.Host):$($CoinPools.$_.Port) $($CoinPools.$_.User1) $($CoinPools.$_.Pass1)$($Diff)"
   HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_HashRate".Day}
   API = "lyclminer"
   PowerX = [PSCustomObject]@{$CoinPools.$_.Symbol = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($CoinPools.$_.Algorithm)_Power".Day)}elseif($Watts.$($CoinPools.$_.Algorithm).AMD1_Watts){$Watts.$($CoinPools.$_.Algorithm).AMD1_Watts}elseif($Watts.default.AMD1_Watts){$Watts.default.AMD1_Watts}else{0}}
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
