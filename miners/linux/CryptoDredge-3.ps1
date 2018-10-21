$Path = "$($nvidia.cryptodredge.path3)"
$Uri = "$($nvidia.cryptodredge.uri)"
$MinerName = "$($nvidia.cryptodredge.minername)"

$Build = "Tar"

if($NVIDIADevices3 -ne ''){$Devices = $NVIDIADevices3}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands = [PSCustomObject]@{
  "lyra2v2" = ''
  "lyra2rev2" = ''
  "lyra2z" = ''
  "lyra2re" = ''
  "allium" = ''
  "neoscrypt" = ''
  "blake2s" = ''
  "skein" = ''
  "cryptonightv7" = ''
  "cryptonightheavy" = ''
  "aeon" = ''
  "masari" = ''
  "stellite" = ''
  "lbk3" = ''
  "phi2" = ''
  "cnv2" = ''
  }
             
  $Difficulty = [PSCustomObject]@{
  "lyra2v2" = ''
  "lyra2rev2" = ''
  "lyra2z" = ''
  "lyra2re" = ''
  "allium" = ''
  "neoscrypt" = ''
  "blake2s" = ''
  "skein" = ''
  "cryptonightv7" = ''
  "cryptonightheavy" = ''
  "aeon" = ''
  "masari" = ''
  "stellite" = ''
  "lbk3" = ''
  "phi2" = ''
  "cnv2" = ''
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
  PowerX = [PSCustomObject]@{$_ = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($_)_Power".Day)}elseif($Watts.$($_).NVIDIA1_Watts){$Watts.$($_).NVIDIA1_Watts}elseif($Watts.default.NVIDIA1_Watts){$Watts.default.NVIDIA1_Watts}else{0}}
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
 Where {$($Commands.$($CoinPools.$_.Algorithm)) -NE $null} |
 foreach {
  if($Difficulty.$($CoinPools.$_.Algorithm)){$Diff=",d=$($Difficulty.$($CoinPools.$_.Algorithm))"}
  [PSCustomObject]@{
  Platform = $Platform
  Symbol = "$($CoinPools.$_.Symbol)"
  MinerName = $MinerName
  Type = "NVIDIA3"
  Path = $Path
  Devices = $Devices
  DeviceCall = "ccminer"
  Arguments = "-a $(Get-Algorithm($CoinPools.$_.Algorithm)) -o stratum+tcp://$($CoinPools.$_.Host):$($CoinPools.$_.Port) -b 0.0.0.0:4070 -u $($CoinPools.$_.User3) -p $($CoinPools.$_.Pass3)$($Diff) $($Commands.$($Coinpools.$_.Algorithm))"
  HashRates = [PSCustomObject]@{$_ = $($Stats."$($Name)_$($_)_hashrate".Day)}
  PowerX = [PSCustomObject]@{$_ = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($_)_Power".Day)}elseif($Watts.$($_).NVIDIA3_Watts){$Watts.$($_).NVIDIA3_Watts}elseif($Watts.default.NVIDIA3_Watts){$Watts.default.NVIDIA3_Watts}else{0}}
  API = "Ccminer"
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
      
