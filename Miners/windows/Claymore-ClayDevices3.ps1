[string]$Path = $update.nvidia.claymore.path3
[string]$Uri = $update.nvidia.claymore.uri

$Build = "Zip"

if($ClayDevices3 -ne ''){$Devices = $ClayDevices3}
if($GPUDevices3 -ne '')
 {
  $GPUEDevices3 = $GPUDevices3 -replace ',',''
  $Devices = $GPUEDevices3
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
        MinerName = "clay-NVIDIA3"
        Type = "NVIDIA3"
        Path = $Path
        Devices = $Devices
        DeviceCall = "claymore"
        Arguments = "-mport -3335 -mode 1 -allcoins 1 -allpools 1 -epool $($AlgoPools.(Get-Algorithm($_)).Protocol)://$($AlgoPools.(Get-Algorithm($_)).Host):$($AlgoPools.(Get-Algorithm($_)).Port) -ewal $($AlgoPools.(Get-Algorithm($_)).User3) -epsw $($AlgoPools.(Get-Algorithm($_)).Pass3) -wd 0 -dbg -1 -eres 1 $($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Day}
        Selected = [PSCustomObject]@{(Get-Algorithm($_)) = ""}
        FullName = "$($AlgoPools.(Get-Algorithm($_)).Mining)"
        API = "claymore"
        Port = 3335
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
               MinerName = "clay-NVIDIA3"
               Type = "NVIDIA3"
               Path = $Path
               Devices = $Devices
               DeviceCall = "claymore"
               Arguments = "-mport -3335 -mode 1 -allcoins 1 -allpools 1 -epool $($CoinPools.$_.Protocol)://$($CoinPools.$_.Host):$($CoinPools.$_.Port) -ewal $($CoinPools.$_.User3) -epsw $($CoinPools.$_.Pass3) -wd 0 -dbg -1 -eres 1 $($Commands.$($CoinPools.$_.Algorithm))"
               HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_HashRate".Day}
               Selected = [PSCustomObject]@{$($CoinPools.$_.Algorithm) = ""}
               FullName = "$($CoinPools.$_.Mining)"
               MinerPool = "$($CoinPools.$_.Name)"
               API = "claymore"
               Port = 3335
               Wrap = $false
               URI = $Uri
               BUILD = $Build
               Algo = "$($CoinPools.$_.Algorithm)"
              }
             }
            }