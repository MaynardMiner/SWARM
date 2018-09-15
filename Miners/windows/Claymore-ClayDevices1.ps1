[string]$Path = $update.nvidia.claymore.path1
[string]$Uri = $update.nvidia.claymore.uri

$Build = "Zip"

if($ClayDevices1 -ne ''){$Devices = $ClayDevices1}
if($GPUDevices1 -ne '')
 {
  $GPUEDevices1 = $GPUDevices1 -replace ',',''
  $Devices = $GPUEDevices1
 }

 $Commands = [PSCustomObject]@{
    "ethash" = '-esm 2'
    "daggerhashimoto" = '-esm 3 -estale 0'
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
	   MinerName = "clay-NVIDIA1"
     Type = "NVIDIA1"
     Path = $Path
     Devices = $Devices
     DeviceCall = "claymore"
     Arguments = "-mport -3333 -mode 1 -allcoins 1 -allpools 1 -epool $($AlgoPools.(Get-Algorithm($_)).Protocol)://$($AlgoPools.(Get-Algorithm($_)).Host):$($AlgoPools.(Get-Algorithm($_)).Port) -ewal $($AlgoPools.(Get-Algorithm($_)).User1) -epsw $($AlgoPools.(Get-Algorithm($_)).Pass1) -wd 0 -dbg -1 -eres 1 $($Commands.$_)"
     HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Day}
     Selected = [PSCustomObject]@{(Get-Algorithm($_)) = ""}
     FullName = "$($AlgoPools.(Get-Algorithm($_)).Mining)"
     API = "claymore"
     Port = 3333
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
    else {
      $CoinPools | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name |
      Where {$($Commands.$($CoinPools.$_.Algorithm)) -NE $null} |
      foreach {
          [PSCustomObject]@{
            Platform = $Platform
            Coin = "Yes"
            Symbol = "$($CoinPools.$_.Symbol)"
            MinerName = "clay-NVIDIA1"
            Type = "NVIDIA1"
            Path = $Path
            Devices = $Devices
            DeviceCall = "claymore"
            Arguments = "-mport -3333 -mode 1 -allcoins 1 -allpools 1 -epool $($CoinPools.$_.Protocol)://$($CoinPools.$_.Host):$($CoinPools.$_.Port) -ewal $($CoinPools.$_.User1) -epsw $($CoinPools.$_.Pass1) -wd 0 -dbg -1 -eres 1 $($Commands.$($CoinPools.$_.Algorithm))"
            HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_HashRate".Day}
            Selected = [PSCustomObject]@{$($CoinPools.$_.Algorithm) = ""}
            FullName = "$($CoinPools.$_.Mining)"
            MinerPool = "$($CoinPools.$_.Name)"
            API = "claymore"
            Port = 3333
            Wrap = $false
            URI = $Uri
            BUILD = $Build
            Algo = "$($CoinPools.$_.Algorithm)"
           }
          }
         }