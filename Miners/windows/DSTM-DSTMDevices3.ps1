[string]$Path = $update.nvidia.dstm.path3
[string]$Uri = $update.nvidia.dstm.uri

$Build = "Zip"


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
     if($Algorithm -eq "$($AlgoPools.(Get-Algorithm($_)).Algorithm)")
      {
       [PSCustomObject]@{
        Platform = $Platform
       Symbol = "$(Get-Algorithm($_))"
       MinerName = "zm-NVIDIA3"
               Type = "NVIDIA3"
               Path = $Path
               Distro =  $Distro
               Devices = $Devices
               DeviceCall = "dstm"
               Arguments = "--server $($AlgoPools.(Get-Algorithm($_)).Host) --port $($AlgoPools.(Get-Algorithm($_)).Port) --user $($AlgoPools.(Get-Algorithm($_)).User3) --pass $($AlgoPools.(Get-Algorithm($_)).Pass3) --telemetry=0.0.0.0:43002 $($Commands.$_)"
               HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Day}
               Selected = [PSCustomObject]@{(Get-Algorithm($_)) = ""}
               FullName = "$($AlgoPools.(Get-Algorithm($_)).Mining)"
               API = "DSTM"
               Port = 43002
               MinerPool = "$($AlgoPools.(Get-Algorithm($_)).Name)"
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
            MinerName = "zm-NVIDIA3"
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
   
