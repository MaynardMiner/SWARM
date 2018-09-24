$Path = "$($nvidia.cryptodredge.path1)"
$Uri = "$($nvidia.cryptodredge.uri)"
$MinerName = "$($nvidia.cryptodredge.minername)"

$Build = "Tar"

if($RexDevices1 -ne ''){$Devices = $RexDevices1}
if($GPUDevices1 -ne ''){$Devices = $GPUDevices1}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands = [PSCustomObject]@{

"lyra2v2" = ''
"lyra2rev2" = ''
"lyra2z" = ''
"lyra2re" = ''
"allium" = ''
"neoscrypt" = ''
"blake2s" = ''
"skein" = ''
"cryptonightv7" = ''
"cryptonightheavy" = ''
"aeon" = ''
"masari" = ''
"stellite" = ''
"lbk3" = ''
"phi2" = ''
        
        }
        
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
        Devices = $Devices
        DeviceCall = "ccminer"
        Arguments = "-a $(Get-Nvidia($_)) -o stratum+tcp://$($AlgoPools.$_.Host):$($AlgoPools.$_.Port) -b 0.0.0.0:4068 -u $($AlgoPools.$_.User1) -p $($AlgoPools.$_.Pass1) $($Commands.$_)"
        HashRates = [PSCustomObject]@{$_ = $Stats."$($Name)_$($_)_HashRate".Day}
	Selected = [PSCustomObject]@{$_ = ""}
        MinerPool = "$($AlgoPools.$_.Name)"
        FullName = "$($AlgoPools.$_.Mining)"
	Port = 4068
        API = "Ccminer"
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
         DeviceCall = "ccminer"
         Arguments = "-a $(Get-Algorithm($CoinPools.$_.Algorithm)) -o stratum+tcp://$($CoinPools.$_.Host):$($CoinPools.$_.Port) -b 0.0.0.0:4068 -u $($CoinPools.$_.User1) -p $($CoinPools.$_.Pass1) $($Commands.$($Coinpools.$_.Algorithm))"
         HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_HashRate".Day}
         API = "Ccminer"
         Selected = [PSCustomObject]@{$($CoinPools.$_.Algorithm) = ""}
         FullName = "$($CoinPools.$_.Mining)"
	 MinerPool = "$($CoinPools.$_.Name)"
         Port = 4068
         Wrap = $false
         URI = $Uri
         BUILD = $Build
	 Algo = "$($CoinPools.$_.Algorithm)"
         }
        }
       }
