$Path = "$($nvidia.trex.path3)"
$Uri = "$($nvidia.trex.uri)"
$MinerName = "$($nvidia.trex.minername)"

$Build = "Zip"

if($NVIDIADevices3 -ne ''){$Devices = $NVIDIADevices3}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands = [PSCustomObject]@{
  "tribus" = ''
  "phi" = ''
  "c11" = ''
  "hsr" = ''
  "x17" = ''
  "renesis" = ''
  "balloon" = ''
  "bitcore" = ''
  "polytimos" = ''
  "skunk" = ''
  "x16r" = ''
  "x16s" = ''
  "hmq1725" = ''
  "bcd" = ''
  "sha256t" = ''
  "timetravel" = ''
  }
  
  $Difficulty = [PSCustomObject]@{
  "tribus" = ''
  "phi" = ''
  "c11" = ''
  "hsr" = ''
  "x17" = ''
  "renesis" = ''
  "balloon" = ''
  "bitcore" = ''
  "polytimos" = ''
  "skunk" = ''
  "x16r" = ''
  "x16s" = ''
  "hmq1725" = ''
  "bcd" = ''
  "sha256t" = ''
  "timetravel" = ''
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
     Type = "NVIDIA3"
     Path = $Path
     Devices = $Devices
     DeviceCall = "trex"
     Arguments = "-a $_ -o  $($AlgoPools.$_.Protocol)://$($AlgoPools.$_.Host):$($AlgoPools.$_.Port) --api-bind-telnet 0.0.0.0:4070 --api-bind-http 0.0.0.0:4073 -u $($AlgoPools.$_.User3) -p $($AlgoPools.$_.Pass3)$($Diff) $($Commands.$_)"
     HashRates = [PSCustomObject]@{$_ = $($Stats."$($Name)_$($_)_hashrate".Day)}
     PowerX = [PSCustomObject]@{$_ = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($_)_Power".Day)}elseif($Watts.$($_).NVIDIA3_Watts){$Watts.$($_).NVIDIA3_Watts}elseif($Watts.default.NVIDIA3_Watts){$Watts.default.NVIDIA3_Watts}else{0}}
     MinerPool = "$($AlgoPools.$_.Name)"
     FullName = "$($AlgoPools.$_.Mining)"
     Port = 4073
     API = "trex"
     Wrap = $false
     URI = $Uri
     BUILD = $Build
     Algo = "$($_)"
    }
   }
  }
 }             
else{
 $CoinPools | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name |
 Where {$($Commands.$($CoinPools.$_.Algorithm)) -NE $null} | foreach {
  if($Difficulty.$($CoinPools.$_.Algorithm)){$Diff=",d=$($Difficulty.$($CoinPools.$_.Algorithm))"}
  [PSCustomObject]@{   
    Platform = $Platform
    Symbol = "$($CoinPools.$_.Symbol)"
    MinerName = $MinerName
    Type = "NVIDIA3"
    Path = $Path
    Devices = $Devices
    DeviceCall = "trex"
    Arguments = "-a $($CoinPools.$_.Algorithm) -o stratum+tcp://$($CoinPools.$_.Host):$($CoinPools.$_.Port) --api-bind-telnet 0.0.0.0:4070 --api-bind-http 0.0.0.0:4073 -u $($CoinPools.$_.User2) -p $($CoinPools.$_.Pass2)$($Diff) $($Commands.$($CoinPools.$_.Algorithm))"
    HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_HashRate".Day}
    API = "trex"
    PowerX = [PSCustomObject]@{$CoinPools.$_.Symbol = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($CoinPools.$_.Algorithm)_Power".Day)}elseif($Watts.$($CoinPools.$_.Algorithm).NVIDIA3_Watts){$Watts.$($CoinPools.$_.Algorithm).NVIDIA3_Watts}elseif($Watts.default.NVIDIA3_Watts){$Watts.default.NVIDIA3_Watts}else{0}}
    FullName = "$($CoinPools.$_.Mining)"
    MinerPool = "$($CoinPools.$_.Name)"
    Port = 4073
    Wrap = $false
    URI = $Uri
    BUILD = $Build
    Algo = "$($CoinPools.$_.Algorithm)"
   }
  }
 }