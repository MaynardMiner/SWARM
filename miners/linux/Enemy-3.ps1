$Path = "$($nvidia.enemy.path3)"
$Uri = "$($nvidia.enemy.uri)"
$MinerName = "$($nvidia.enemy.MinerName)"

$Build = "Tar"

if($NVIDIADevices3 -ne ''){$Devices = $NVIDIADevices3}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands = [PSCustomObject]@{
  "aergo" = ''
  "hex" = ''
  "timetravel" = ''
  "xevan" = ''
  "sonoa" = ''
}

$Difficulty = [PSCustomObject]@{
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
      if($Difficulty.$_){$Diff=",d=$($Difficulty.$_)"}
      [PSCustomObject]@{
      Platform = $Platform
      Symbol = "$($_)"
      MinerName = $MinerName
      Type = "NVIDIA3"
      Path = $Path
      Devices = $Devices
      DeviceCall = "ccminer"
      Arguments = "-a $(Get-Nvidia($_)) -o stratum+tcp://$($AlgoPools.$_.Host):$($AlgoPools.$_.Port) -b 0.0.0.0:4070 -u $($AlgoPools.$_.User3) -p $($AlgoPools.$_.Pass3)$($Diff) $($Commands.$_)"
      HashRates = [PSCustomObject]@{$_ = $($Stats."$($Name)_$($_)_hashrate".Day)}
      PowerX = [PSCustomObject]@{$_ = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($_)_Power".Day)}elseif($Watts.$($_).NVIDIA3_Watts){$Watts.$($_).NVIDIA3_Watts}elseif($Watts.default.NVIDIA3_Watts){$Watts.default.NVIDIA3_Watts}else{0}}
      Port = 4070
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
    if($Difficulty.$($CoinPools.$_.Algorithm)){$Diff=",d=$($Difficulty.$($CoinPools.$_.Algorithm))"}
    [PSCustomObject]@{
   Platform = $Platform
   Coin = "Yes"
   Symbol = "$($CoinPools.$_.Symbol)"
   MinerName = $MinerName
   Type = "NVIDIA3"
   Path = $Path
   Devices = $Devices
   DeviceCall = "ccminer"
   Arguments = "-a $(Get-Nvidia($CoinPools.$_.Algorithm)) -o stratum+tcp://$($CoinPools.$_.Host):$($CoinPools.$_.Port) -b 0.0.0.0:4070 -u $($CoinPools.$_.User3) -p $($CoinPools.$_.Pass3)$($Diff) $($Commands.$($CoinPools.$_.Algorithm))"
   HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_HashRate".Day}
   API = "Ccminer"
   PowerX = [PSCustomObject]@{$_ = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($_)_Power".Day)}elseif($Watts.$($_).NVIDIA3_Watts){$Watts.$($_).NVIDIA3_Watts}elseif($Watts.default.NVIDIA3_Watts){$Watts.default.NVIDIA3_Watts}else{0}}
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
