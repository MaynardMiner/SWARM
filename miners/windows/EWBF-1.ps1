$Path = "$($nvidia.ewbf.path1)"
$Uri = "$($nvidia.ewbf.uri)"
$MinerName = "$($nvidia.ewbf.minername)"

$Build = "Zip"

if($NVIDIADevices1 -ne ''){$GPUDevices1 = $NVIDIADevices1}
if($GPUDevices1 -ne '')
 {
  $GPUEDevices1 = $GPUDevices1 -replace ',',' '
  $Devices = $GPUEDevices1
 }

$Commands = [PSCustomObject]@{
"equihash-btg" = '--algo 144_5 --pers BgoldPoW'
"equihash192" = '--algo 192_7 --pers auto'
"equihash144" =  '--algo 144_5 --pers auto'
"equihash96" =  '--algo 96_5 --pers auto'
"equihash210" = '--algo 210_9 --pers auto'
"equihash200" = '--algo 200_9 --pers auto'
}


$Difficulty = [PSCustomObject]@{
"equihash-btg" = '--algo 144_5 --pers BgoldPoW'
"equihash192" = '--algo 192_7 --pers auto'
"equihash144" =  '--algo 144_5 --pers auto'
"equihash96" =  '--algo 96_5 --pers auto'
"equihash210" = '--algo 210_9 --pers auto'
"equihash200" = '--algo 200_9 --pers auto'
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

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
      DeviceCall = "ewbf"
      Arguments = "--api 0.0.0.0:42000 --server $($AlgoPools.$_.Host) --port $($AlgoPools.$_.Port) --user $($AlgoPools.$_.User1) --pass $($AlgoPools.$_.Pass1)$($Diff) $($Commands.$_)"
      HashRates = [PSCustomObject]@{$_ = $($Stats."$($Name)_$($_)_hashrate".Day)}
      PowerX = [PSCustomObject]@{$_ = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($_)_Power".Day)}elseif($Watts.$($_).NVIDIA1_Watts){$Watts.$($_).NVIDIA1_Watts}elseif($Watts.default.NVIDIA1_Watts){$Watts.default.NVIDIA1_Watts}else{0}}
      MinerPool = "$($AlgoPools.$_.Name)"
      FullName = "$($AlgoPools.$_.Mining)"
      API = "EWBF"
      Port = 42000
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
  Symbol = "$($Coinpools.$_.Symbol)"
  MinerName = $MinerName
  Type = "NVIDIA1"
  Path = $Path
  Devices = $Devices
  DeviceCall = "ewbf"
  Arguments = "--api 0.0.0.0:42000 --server $($CoinPools.$_.Host) --port $($CoinPools.$_.Port) --user $($CoinPools.$_.User1) --pass $($CoinPools.$_.Pass1)$($Diff) $($Commands.$($CoinPools.$_.Algorithm))"
  HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_HashRate".Day}
  PowerX = [PSCustomObject]@{$CoinPools.$_.Symbol = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($CoinPools.$_.Algorithm)_Power".Day)}elseif($Watts.$($CoinPools.$_.Algorithm).NVIDIA1_Watts){$Watts.$($CoinPools.$_.Algorithm).NVIDIA1_Watts}elseif($Watts.default.NVIDIA1_Watts){$Watts.default.NVIDIA1_Watts}else{0}}
  FullName = "$($CoinPools.$_.Mining)"
  API = "EWBF"
  MinerPool = "$($CoinPools.$_.Name)"
  Port = 42000
  Wrap = $false
  URI = $Uri
  BUILD = $Build
  Algo = "$($CoinPools.$_.Algorithm)"
    }
   }
  }

        
