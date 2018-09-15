[string]$Path = $nvidia.dstm.path1
[string]$Uri = $nvidia.dstm.uri
[string]$MinerName = $nvidia.dstm.minername

$Build = "Zip"

if($DSTMDevices1 -ne ''){$Devices = $DSTMDevices1}
if($GPUDevices1 -ne '')
 {
  $GPUEDevices1 = $GPUDevices1 -replace ',',' '
  $Devices = $GPUEDevices1
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
            Type = "NVIDIA1"
            Path = $Path
            Distro =  $Distro
            Devices = $Devices
            DeviceCall = "dstm"
            Arguments = "--server $($AlgoPools.$_.Host) --port $($AlgoPools.$_.Port) --user $($AlgoPools.$_.User1) --pass $($AlgoPools.$_.Pass1) --telemetry=0.0.0.0:43000 $($Commands.$_)"
            HashRates = [PSCustomObject]@{$_ = $Stats."$($Name)_$($_)_HashRate".Day}
            Selected = [PSCustomObject]@{$_ = ""}
            FullName = "$($AlgoPools.$_.Mining)"
            API = "DSTM"
            Port = 43000
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
         Type = "NVIDIA1"
         Path = $Path
         Devices = $Devices
         DeviceCall = "dstm"
         Arguments = "--server $($CoinPools.$_.Host) --port $($CoinPools.$_.Port) --user $($CoinPools.$_.User1) --pass $($CoinPools.$_.Pass1) --telemetry=0.0.0.0:43000 $($Commands.$($CoinPools.$_.Algorithm))"
         HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_HashRate".Day}
         API = "DSTM"
         Selected = [PSCustomObject]@{$($CoinPools.$_.Algorithm) = ""}
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
