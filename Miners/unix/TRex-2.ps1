[string]$Path = $nvidia.trex.path2
[string]$Uri = $nvidia.trex.uri
[string]$MinerName = $nvidia.trex.minername


$Build = "Zip"

if($RexDevices2 -ne ''){$Devices = $RexDevices2}
if($GPUDevices2 -ne ''){$Devices = $GPUDevices2}

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
      Type = "NVIDIA2"
      Path = $Path
      Devices = $Devices
      DeviceCall = "trex"
      Arguments = "-a $_ -o stratum+tcp://$($AlgoPools.$_.Host):$($AlgoPools.$_.Port) -b 0.0.0.0:4069 -u $($AlgoPools.$_.User2) -p $($AlgoPools.$_.Pass2) $($Commands.$_)"
      HashRates = [PSCustomObject]@{$_ = $Stats."$($Name)_$($_)_HashRate".Day}
      Selected = [PSCustomObject]@{$_ = ""}
      MinerPool = "$($AlgoPools.$_.Name)"
      FullName = "$($AlgoPools.$_.Mining)"
      Port = 4069
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
     Type = "NVIDIA2"
     Path = $Path
     Devices = $Devices
     DeviceCall = "trex"
     Arguments = "-a $($CoinPools.$_.Algorithm) -o stratum+tcp://$($CoinPools.$_.Host):$($CoinPools.$_.Port) -b 0.0.0.0:4069 -u $($CoinPools.$_.User2) -p $($CoinPools.$_.Pass2) $($Commands.$($CoinPools.$_.Algorithm))"
     HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_HashRate".Day}
     API = "ccminer"
     Selected = [PSCustomObject]@{$($CoinPools.$_.Algorithm) = ""}
     FullName = "$($CoinPools.$_.Mining)"
	   MinerPool = "$($CoinPools.$_.Name)"
     Port = 4069
     Wrap = $false
     URI = $Uri
     BUILD = $Build
	   Algo = "$($CoinPools.$_.Algorithm)"
    }
   }
  }