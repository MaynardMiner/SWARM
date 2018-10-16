$Path = "$($nvidia.dstm.path1)"
$Uri = "$($nvidia.dstm.uri)"
$MinerName = "$($nvidia.dstm.minername)"

$Build = "Tar"

if($NVIDIADevices1 -ne ''){$GPUDevices1 = $NVIDIADevices1}
if($GPUDevices1 -ne '')
 {
  $GPUEDevices1 = $GPUDevices1 -replace ',',' '
  $Devices = $GPUEDevices1
 }

$Commands = [PSCustomObject]@{
"equihash" = ''
}

$Difficulty = [PSCustomObject]@{
"equihash" = ''
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
 DeviceCall = "dstm"
 Arguments = "--server $($AlgoPools.$_.Host) --port $($AlgoPools.$_.Port) --user $($AlgoPools.$_.User1) --pass $($AlgoPools.$_.Pass1)$($Diff) --telemetry=0.0.0.0:43000 $($Commands.$_)"
 HashRates = [PSCustomObject]@{$_ = $($Stats."$($Name)_$($_)_hashrate".Day)}
 PowerX = [PSCustomObject]@{$_ = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($_)_Power".Day)}elseif($Watts.$($_).NVIDIA1_Watts){$Watts.$($_).NVIDIA1_Watts}elseif($Watts.default.NVIDIA1_Watts){$Watts.default.NVIDIA1_Watts}else{0}}
 FullName = "$($AlgoPools.$_.Mining)"
 API = "dstm"
 Port = 43000
 MinerPool = "$($AlgoPools.$_.Name)"
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
 Type = "NVIDIA1"
 Path = $Path
 Devices = $Devices
 DeviceCall = "dstm"
 Arguments = "--server $($CoinPools.$_.Host) --port $($CoinPools.$_.Port) --user $($CoinPools.$_.User1) --pass $($CoinPools.$_.Pass1)$($Diff) --telemetry=0.0.0.0:43000 $($Commands.$($CoinPools.$_.Algorithm))"
 HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_HashRate".Day}
 API = "dstm"
 PowerX = [PSCustomObject]@{$CoinPools.$_.Symbol = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($CoinPools.$_.Algorithm)_Power".Day)}elseif($Watts.$($CoinPools.$_.Algorithm).NVIDIA1_Watts){$Watts.$($CoinPools.$_.Algorithm).NVIDIA1_Watts}elseif($Watts.default.NVIDIA1_Watts){$Watts.default.NVIDIA1_Watts}else{0}}
 FullName = "$($CoinPools.$_.Mining)"
 MinerPool = "$($CoinPools.$_.Name)"
 Port = 43000
 Wrap = $false
 URI = $Uri
 BUILD = $Build
 Algo = "$($CoinPools.$_.Algorithm)"
      }
    }
  }
      
