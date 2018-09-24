$Path = "$($amd.claymored.path1)"
$Uri = "$($amd.claymored.uri)"
$MinerName = "$($amd.claymored.minername)"

$Build = "Tar"

if($ClayDevices1 -ne ''){$Devices = $ClayDevices1}
if($GPUDevices1 -ne '')
 {
  $GPUEDevices1 = $GPUDevices1 -replace ',',''
  $Devices = $GPUEDevices1
 }

 $Commands = [PSCustomObject]@{
    "blake2s" = '-dcoin blake2s'
    "keccak" = '-dcoin keccak'
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
     Type = "AMD1"
     Path = $Path
     Devices = $Devices
     DeviceCall = "claymore"
     Arguments = "-mport 3337 -o $($AlgoPools.$_.Protocol)://$($AlgoPools.$_.Host):$($AlgoPools.$_.Port) -dwal $($AlgoPools.$_.User1) -dpsw $($AlgoPools.$_.Pass1) $($Commands.$_)"
     HashRates = [PSCustomObject]@{$_ = $Stats."$($Name)_$($_)_HashRate".Day}
     Selected = [PSCustomObject]@{$_ = ""}
     FullName = "$($AlgoPools.$_.Mining)"
     API = "claymore"
     Port = 3337
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
    else {
      $CoinPools | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name |
      Where {$($Commands.$($CoinPools.$_.Algorithm)) -NE $null} |
      foreach {
          [PSCustomObject]@{
            Platform = $Platform
            Coin = "Yes"
            Symbol = "$($CoinPools.$_.Symbol)"
            MinerName = $MinerName
            Type = "AMD1"
            Path = $Path
            Devices = $Devices
            DeviceCall = "claymore"
            Arguments = "-mport 3337 -o $($CoinPools.$_.Protocol)://$($CoinPools.$_.Host):$($CoinPools.$_.Port) -dwal $($CoinPools.$_.User1) -dpsw $($CoinPools.$_.Pass1) $($Commands.$($CoinPools.$_.Algorithm))"
            HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_HashRate".Day}
            Selected = [PSCustomObject]@{$($CoinPools.$_.Algorithm) = ""}
            FullName = "$($CoinPools.$_.Mining)"
            MinerPool = "$($CoinPools.$_.Name)"
            API = "claymore"
            Port = 3337
            Wrap = $false
            URI = $Uri
            BUILD = $Build
            Algo = "$($CoinPools.$_.Algorithm)"
           }
          }
         }
