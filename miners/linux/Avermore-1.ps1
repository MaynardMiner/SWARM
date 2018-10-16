$Path = "$($amd.avermore.path1)"
$Uri = "$($amd.avermore.uri)"
$MinerName = "$($amd.avermore.minername)"

$Build = "Tar"

if($AMDDevices1 -ne ''){$Devices = $AMDDevices1}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands = [PSCustomObject]@{
"myr-gr" = ""
"groestl" = ""
"x16r" = ""
"x16s" = ""
"equihash" = ""
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
    DeviceCall = "sgminer-gm"
    Arguments = "--gpu-platform $AMDPlatform --api-listen --api-port 4028 -k $(Get-AMD($_)) -o stratum+tcp://$($AlgoPools.$_.Host):$($AlgoPools.$_.Port) -u $($AlgoPools.$_.User1) -p $($AlgoPools.$_.Pass1)$($Diff) -T $($Commands.$_)"
    HashRates = [PSCustomObject]@{$_ = $($Stats."$($Name)_$($_)_hashrate".Day)}
    PowerX = [PSCustomObject]@{$_ = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($_)_Power".Day)}elseif($Watts.$($_).AMD1_Watts){$Watts.$($_).AMD1_Watts}elseif($Watts.default.AMD1_Watts){$Watts.default.AMD1_Watts}else{0}}
    MinerPool = "$($AlgoPools.$_.Name)"
    FullName = "$($AlgoPools.$_.Mining)"
    Port = 4028
    API = "sgminer-gm"
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
   DeviceCall = "sgminer-gm"
   Arguments = "--gpu-platform $AMDPlatform --api-listen --api-port 4028 -k $(Get-AMD($CoinPools.$_.Algorithm)) -o stratum+tcp://$($CoinPools.$_.Host):$($CoinPools.$_.Port) -u $($CoinPools.$_.User1) -p $($CoinPools.$_.Pass1) -T $($Commands.$($CoinPools.$_.Algorithm))"
   HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $($Stats."$($Name)_$($CoinPools.$_.Algorithm)_hashrate".Day)}
   PowerX = [PSCustomObject]@{$CoinPools.$_.Symbol = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($CoinPools.$_.Algorithm)_Power".Day)}elseif($Watts.$($CoinPools.$_.Algorithm).AMD1_Watts){$Watts.$($CoinPools.$_.Algorithm).AMD1_Watts}elseif($Watts.default.AMD1_Watts){$Watts.default.AMD1_Watts}else{0}}
   API = "sgminer-gm"
   FullName = "$($CoinPools.$_.Mining)"
   MinerPool = "$($CoinPools.$_.Name)"
   Port = 4028
   Wrap = $false
   URI = $Uri
   BUILD = $Build
	 Algo = "$($CoinPools.$_.Algorithm)"
   }
  }
 }