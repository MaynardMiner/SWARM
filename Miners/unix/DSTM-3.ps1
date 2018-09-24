$Path = "$($nvidia.dstm.path3)"
$Uri = "$($nvidia.dstm.uri)"
$MinerName = "$($nvidia.dstm.minername)"

$Build = "Tar"

if($DSTMDevices3 -ne ''){$Devices = $DSTMDevices3}
if($GPUDevices3 -ne '')
 {
  $GPUEDevices3 = $GPUDevices3 -replace ',',' ' 
  $Devices = $GPUEDevices3
 }

 $Commands = [PSCustomObject]@{
    "equihash" = ''
    }


    $Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

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
               Distro =  $Distro
               Devices = $Devices
               DeviceCall = "dstm"
               Arguments = "--server $($AlgoPools.$_.Host) --port $($AlgoPools.$_.Port) --user $($AlgoPools.$_.User3) --pass $($AlgoPools.$_.Pass3) --telemetry=0.0.0.0:43002 $($Commands.$_)"
               HashRates = [PSCustomObject]@{$_ = $Stats."$($Name)_$($_)_HashRate".Day}
               Selected = [PSCustomObject]@{$_ = ""}
               FullName = "$($AlgoPools.$_.Mining)"
               API = "DSTM"
               Port = 43002
               MinerPool = "$($AlgoPools.$_.Name)"
               Wrap = $false
               URI = $Uri
               BUILD = $Build
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
           [PSCustomObject]@{
            Platform = $Platform
            Symbol = "$($CoinPools.$_.Symbol)"
            MinerName = $MinerName
            Type = "NVIDIA3"
            Path = $Path
            Devices = $Devices
            DeviceCall = "dstm"
            Arguments = "--server $($CoinPools.$_.Host) --port $($CoinPools.$_.Port) --user $($CoinPools.$_.User3) --pass $($CoinPools.$_.Pass3) --telemetry=0.0.0.0:43002 $($Commands.$($CoinPools.$_.Algorithm))"
            HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_HashRate".Day}
            API = "DSTM"
            Selected = [PSCustomObject]@{$($CoinPools.$_.Algorithm) = ""}
            FullName = "$($CoinPools.$_.Mining)"
            MinerPool = "$($CoinPools.$_.Name)"
            Port = 43002
            Wrap = $false
            URI = $Uri
            BUILD = $Build
            Algo = "$($CoinPools.$_.Algorithm)"
            }
           }
          }
   
