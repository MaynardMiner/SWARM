$Path = "$($nvidia.trex.path1)"
$Uri = "$($nvidia.trex.uri)"
$MinerName = "$($nvidia.trex.minername)"

$Build = "Tar"

if($NVIDIADevices1 -ne ''){$Devices = $NVIDIADevices1}

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
      Type = "NVIDIA1"
      Path = $Path
      Devices = $Devices
      DeviceCall = "trex"
      Arguments = "-a $_ -o stratum+tcp://$($AlgoPools.$_.Host):$($AlgoPools.$_.Port) --api-bind-telnet 0.0.0.0:4068 --api-bind-http 0.0.0.0:4071 -u $($AlgoPools.$_.User1) -p $($AlgoPools.$_.Pass1)$($Diff) $($Commands.$_)"
      HashRates = [PSCustomObject]@{$_ = $($Stats."$($Name)_$($_)_hashrate".Day)}
      PowerX = [PSCustomObject]@{$_ = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($_)_Power".Day)}elseif($Watts.$($_).NVIDIA1_Watts){$Watts.$($_).NVIDIA1_Watts}elseif($Watts.default.NVIDIA1_Watts){$Watts.default.NVIDIA1_Watts}else{0}}
      MinerPool = "$($AlgoPools.$_.Name)"
      FullName = "$($AlgoPools.$_.Mining)"
      Port = 4071
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
     Type = "NVIDIA1"
     Path = $Path
     Devices = $Devices
     DeviceCall = "trex"
     Arguments = "-a $($CoinPools.$_.Algorithm) -o stratum+tcp://$($CoinPools.$_.Host):$($CoinPools.$_.Port) --api-bind-telnet 0.0.0.0:4068 --api-bind-http 0.0.0.0:4071 -u $($CoinPools.$_.User1) -p $($CoinPools.$_.Pass1)$($Diff) $($Commands.$($CoinPools.$_.Algorithm))"
     HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_HashRate".Day}
     API = "trex"
     PowerX = [PSCustomObject]@{$CoinPools.$_.Symbol = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($CoinPools.$_.Algorithm)_Power".Day)}elseif($Watts.$($CoinPools.$_.Algorithm).NVIDIA1_Watts){$Watts.$($CoinPools.$_.Algorithm).NVIDIA1_Watts}elseif($Watts.default.NVIDIA1_Watts){$Watts.default.NVIDIA1_Watts}else{0}}
     FullName = "$($CoinPools.$_.Mining)"
	   MinerPool = "$($CoinPools.$_.Name)"
     Port = 4071
     Wrap = $false
     URI = $Uri
     BUILD = $Build
	   Algo = "$($CoinPools.$_.Algorithm)"
    }
   }
  }