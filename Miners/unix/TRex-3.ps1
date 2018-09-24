$Path = "$($nvidia.trex.path3)"
$Uri = "$($nvidia.trex.uri)"
$MinerName = "$($nvidia.trex.minername)"


$Build = "Tar"

if($RexDevices3 -ne ''){$Devices = $RexDevices3}
if($GPUDevices3 -ne ''){$Devices = $GPUDevices3}

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
        
if($CoinAlgo -eq $null)
 {
  $Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
  if($Algorithm -eq "$($AlgoPools.$_.Algorithm)")
   {
    [PSCustomObject]@{
      Platform = $Platform
      Symbol = "$($_)"
      MinerName = $MinerName
      Type = "NVIDIA3"
      Path = $Path
      Devices = $Devices
      DeviceCall = "trex"
      Arguments = "-a $_ -o stratum+tcp://$($AlgoPools.$_.Host):$($AlgoPools.$_.Port) -b 0.0.0.0:4070 -u $($AlgoPools.$_.User3) -p $($AlgoPools.$_.Pass3) $($Commands.$_)"
      HashRates = [PSCustomObject]@{$_ = $Stats."$($Name)_$($_)_HashRate".Day}
      Selected = [PSCustomObject]@{$_ = ""}
      MinerPool = "$($AlgoPools.$_.Name)"
      FullName = "$($AlgoPools.$_.Mining)"
      Port = 4070
      API = "Ccminer"
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
        
    [PSCustomObject]@{   
     Platform = $Platform
     Symbol = "$($CoinPools.$_.Symbol)"
     MinerName = $MinerName
     Type = "NVIDIA3"
     Path = $Path
     Devices = $Devices
     DeviceCall = "trex"
     Arguments = "-a $($CoinPools.$_.Algorithm) -o stratum+tcp://$($CoinPools.$_.Host):$($CoinPools.$_.Port) -b 0.0.0.0:4069 -u $($CoinPools.$_.User3) -p $($CoinPools.$_.Pass3) $($Commands.$($CoinPools.$_.Algorithm))"
     HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_HashRate".Day}
     API = "ccminer"
     Selected = [PSCustomObject]@{$($CoinPools.$_.Algorithm) = ""}
     FullName = "$($CoinPools.$_.Mining)"
	   MinerPool = "$($CoinPools.$_.Name)"
     Port = 4070
     Wrap = $false
     URI = $Uri
     BUILD = $Build
	   Algo = "$($CoinPools.$_.Algorithm)"
    }
   }
  }