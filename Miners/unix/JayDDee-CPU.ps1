$Path = "$($cpu.jayddee.path1)"
$Uri = "$($cpu.jayddee.uri)"
$MinerName = "$($cpu.jayddee.minername)"

if($CPUThreads -ne ''){$Devices = $CPUThreads}

if($Platform -eq "linux"){$Build = "Linux"}
else{$Build = "Zip"}

#Algorithms
#Yescrypt
#YescryptR16
#Lyra2z
#M7M

$Commands = [PSCustomObject]@{
    "yescrypt" = ''
    "yescryptr16" = ''
    "lyra2z" = ''
    "lyra2re" = ''
    "m7m" = ''
    "cryptonightv7" = ''
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
         Type = "CPU"
         Path = $Path
         Devices = $Devices
         DeviceCall = "cpuminer-opt"
         Arguments = "-a $_ -o stratum+tcp://$($AlgoPools.$_.Host):$($AlgoPools.$_.Port) -b 0.0.0.0:4048 -u $($AlgoPools.$_.User1) -p $($AlgoPools.$_.Pass1) $($Commands.$_)"
         HashRates = [PSCustomObject]@{$_ = $Stats."$($Name)_$($_)_HashRate".Day}
         Selected = [PSCustomObject]@{$_ = ""}
         MinerPool = "$($AlgoPools.$_.Name)"
         FullName = "$($AlgoPools.$_.Mining)"
         Port = 4048
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
       Type = "CPU"
       Path = $Path
       Devices = $Devices
       DeviceCall = "cpuminer-opt"
       Arguments = "-a $($CoinPools.$_.Algorithm) -o stratum+tcp://$($CoinPools.$_.Host):$($CoinPools.$_.Port) -b 0.0.0.0:4048 -u $($CoinPools.$_.User1) -p $($CoinPools.$_.Pass1) $($Commands.$($CoinPools.$_.Algorithm))"
       HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_HashRate".Day}
       API = "Ccminer"
       Selected = [PSCustomObject]@{$($CoinPools.$_.Algorithm) = ""}
       FullName = "$($CoinPools.$_.Mining)"
       MinerPool = "$($CoinPools.$_.Name)"
       Port = 4048
       Wrap = $false
       URI = $Uri
       BUILD = $Build
       Algo = "$($CoinPools.$_.Algorithm)"
       }
      }
     }
