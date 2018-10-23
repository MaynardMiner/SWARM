$Path = "$($amd.xmrstak.path1)"
$Uri = "$($amd.xmrstak.uri)"
$MinerName = "$($amd.xmrstak.minername)"

$Build = "Tar"

if($AMDDevices1 -ne ''){$Devices = $AMDDevices1}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands = [PSCustomObject]@{
"cryptonight" = ""
"cryptonightv7" = ''
"cryptonightv8" = ''
"cryptonightheavy" = ''
}

$Difficulty = [PSCustomObject]@{
"cryptonight" = ""
"cryptonightv7" = ''
"cryptonightv8" = ''
"cryptonightheavy" = ''
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
    DeviceCall = "xmrstak"
    Arguments = "--currency $(Get-AMD($_)) -i 60049 --url stratum+tcp://$($AlgoPools.$_.Host):$($AlgoPools.$_.Port) --user $($AlgoPools.$_.User1) --pass $($AlgoPools.$_.Pass1)$($Diff) --rigid SWARM --noCPU --noNVIDIA --use-nicehash $($Commands.$_)"
    HashRates = [PSCustomObject]@{$_ = $($Stats."$($Name)_$($_)_hashrate".Day)}
    PowerX = [PSCustomObject]@{$_ = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($_)_Power".Day)}elseif($Watts.$($_).AMD1_Watts){$Watts.$($_).AMD1_Watts}elseif($Watts.default.AMD1_Watts){$Watts.default.AMD1_Watts}else{0}}
    FullName = "$($AlgoPools.$_.Mining)"
    MinerPool = "$($AlgoPools.$_.Name)"
    Port = 60049
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
  Where {$($Commands.$($CoinPools.$_.Algorithm)) -ne $null} |
  foreach {
    if($Difficulty.$($CoinPools.$_.Algorithm)){$Diff=",d=$($Difficulty.$($CoinPools.$_.Algorithm))"}
   [PSCustomObject]@{
   Platform = $Platform
   Symbol = "$($CoinPools.$_.Symbol)"
   MinerName = $MinerName
   Type = "AMD1"
   Path = $Path
   Devices = $Devices
   DeviceCall = "xmrstak"
   Arguments = "--currency $(Get-AMD($_)) -i 60050 --url stratum+tcp://$($CoinPools.$_.Host):$($CoinPools.$_.Port) --user $($CoinPools.$_.User1) --pass $($CoinPools.$_.Pass1)$($Diff) --rigid SWARM --noCPU --noNVIDIA --use-nicehash $($Commands.$_)"
   HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_HashRate".Day}
   API = "xmrstak"
   PowerX = [PSCustomObject]@{$CoinPools.$_.Symbol = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($CoinPools.$_.Algorithm)_Power".Day)}elseif($Watts.$($CoinPools.$_.Algorithm).AMD1_Watts){$Watts.$($CoinPools.$_.Algorithm).AMD1_Watts}elseif($Watts.default.AMD1_Watts){$Watts.default.AMD1_Watts}else{0}}
   FullName = "$($CoinPools.$_.Mining)"
   MinerPool = "$($CoinPools.$_.Name)"
   Port = 60050
   Wrap = $false
   URI = $Uri
   BUILD = $Build
	 Algo = "$($CoinPools.$_.Algorithm)"
   }
  }
 }
