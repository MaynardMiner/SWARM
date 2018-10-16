$Path = "$($nvidia.ewbf.path2)"
$Uri = "$($nvidia.ewbf.uri)"
$MinerName = "$($nvidia.ewbf.minername)"

$Build = "Zip"

if($NVIDIADevices2 -ne ''){$GPUDevices2 = $NVIDIADevices2}
if($GPUDevices2 -ne '')
 {
  $GPUEDevices2 = $GPUDevices2 -replace ',',' '
  $Devices = $GPUEDevices2
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
  Type = "NVIDIA2"
  Path = $Path
  Devices = $Devices
  DeviceCall = "ewbf"
  Arguments = "--api 0.0.0.0:42001 --server $($AlgoPools.$_.Host) --port $($AlgoPools.$_.Port) --user $($AlgoPools.$_.User2) --pass $($AlgoPools.$_.Pass2)$($Diff) $($Commands.$_)"
  HashRates = [PSCustomObject]@{$_ = $($Stats."$($Name)_$($_)_hashrate".Day)}
  PowerX = [PSCustomObject]@{$_ = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($_)_Power".Day)}elseif($Watts.$($_).NVIDIA2_Watts){$Watts.$($_).NVIDIA2_Watts}elseif($Watts.default.NVIDIA2_Watts){$Watts.default.NVIDIA2_Watts}else{0}}
  MinerPool = "$($AlgoPools.$_.Name)"
  FullName = "$($AlgoPools.$_.Mining)"
  API = "EWBF"
  Port = 42001
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
  Type = "NVIDIA2"
  Path = $Path
  Devices = $Devices
  DeviceCall = "ewbf"
  Arguments = "--api 0.0.0.0:42001 --server $($CoinPools.$_.Host) --port $($CoinPools.$_.Port) --user $($CoinPools.$_.User2) --pass $($CoinPools.$_.Pass2)$($Diff) $($Commands.$($CoinPools.$_.Algorithm))"
  HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_HashRate".Day}
  PowerX = [PSCustomObject]@{$CoinPools.$_.Symbol = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($CoinPools.$_.Algorithm)_Power".Day)}elseif($Watts.$($CoinPools.$_.Algorithm).NVIDIA2_Watts){$Watts.$($CoinPools.$_.Algorithm).NVIDIA2_Watts}elseif($Watts.default.NVIDIA2_Watts){$Watts.default.NVIDIA2_Watts}else{0}}
  FullName = "$($CoinPools.$_.Mining)"
  API = "EWBF"
  MinerPool = "$($CoinPools.$_.Name)"
  Port = 42001
  Wrap = $false
  URI = $Uri
  BUILD = $Build
  Algo = "$($CoinPools.$_.Algorithm)"
    }
   }
  }

