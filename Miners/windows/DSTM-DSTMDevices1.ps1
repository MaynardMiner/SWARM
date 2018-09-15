[string]$Path = $update.nvidia.dstm.path1
[string]$Uri = $update.nvidia.dstm.uri

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
  if($Algorithm -eq "$($AlgoPools.(Get-Algorithm($_)).Algorithm)")
   {
    [PSCustomObject]@{
      Platform = $Platform
    Symbol = "$(Get-Algorithm($_))"
    MinerName = "zm-NVIDIA1"
            Type = "NVIDIA1"
            Path = $Path
            Distro =  $Distro
            Devices = $Devices
            DeviceCall = "dstm"
            Arguments = "--server $($AlgoPools.(Get-Algorithm($_)).Host) --port $($AlgoPools.(Get-Algorithm($_)).Port) --user $($AlgoPools.(Get-Algorithm($_)).User1) --pass $($AlgoPools.(Get-Algorithm($_)).Pass1) --telemetry=0.0.0.0:43000 $($Commands.$_)"
            HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Day}
            Selected = [PSCustomObject]@{(Get-Algorithm($_)) = ""}
            FullName = "$($AlgoPools.(Get-Algorithm($_)).Mining)"
            API = "DSTM"
            Port = 43000
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
         MinerName = "zm-NVIDIA1"
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
