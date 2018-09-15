[string]$Path = $nvidia.trex.path1
[string]$Uri = $nvidia.trex.uri
[string]$MinerName = $nvidia.trex.minername


$Build = "Zip"

if($RexDevices1 -ne ''){$Devices = $RexDevices1}
if($GPUDevices1 -ne ''){$Devices = $GPUDevices1}

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
      DeviceCall = "trex"
      Arguments = "-a $_ -o stratum+tcp://$($AlgoPools.$_.Host):$($AlgoPools.$_.Port) -b 0.0.0.0:4068 -u $($AlgoPools.$_.User1) -p $($AlgoPools.$_.Pass1) $($Commands.$_)"
      HashRates = [PSCustomObject]@{$_ = $Stats."$($Name)_$($_)_HashRate".Day}
      Selected = [PSCustomObject]@{$_ = ""}
      MinerPool = "$($AlgoPools.$_.Name)"
      FullName = "$($AlgoPools.$_.Mining)"
      Port = 4068
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
     Type = "NVIDIA1"
     Path = $Path
     Devices = $Devices
     DeviceCall = "trex"
     Arguments = "-a $($CoinPools.$_.Algorithm) -o stratum+tcp://$($CoinPools.$_.Host):$($CoinPools.$_.Port) -b 0.0.0.0:4068 -u $($CoinPools.$_.User1) -p $($CoinPools.$_.Pass1) $($Commands.$($CoinPools.$_.Algorithm))"
     HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_HashRate".Day}
     API = "ccminer"
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