[string]$Path = $cpu.cryptozeny.path1
[string]$Uri = $cpu.cryptozeny.uri
[string]$MinerName = $cpu.cryptozeny.minername

if($CPUThreads -ne ''){$Devices = $CPUThreads}

$Build =  "Linux"

$Commands = [PSCustomObject]@{

    "balloon" = ''
    "x16r" = ''
    "x16s" = ''
    "lyra2z" = ''
    "lyra2re" = ''
    "bitcore" = ''
    "cryptonight" = ''
    "groestl" = ''
    "lyra2REv2" = ''
    "skein" = ''
    "xevan" = ''
    "x17" = ''
    
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
         DeviceCall = "cryptozeny"
         Arguments = "-a $(Get-AMD($_)) -o stratum+tcp://$($AlgoPools.$_.Host):$($AlgoPools.$_.Port) -b 0.0.0.0:4048 -u $($AlgoPools.$_.User1) -p $($AlgoPools.$_.Pass1) $($Commands.$_)"
         HashRates = [PSCustomObject]@{$_ = $Stats."$($Name)_$($_)_HashRate".Day}
         Selected = [PSCustomObject]@{$_ = ""}
         MinerPool = "$($AlgoPools.$_.Name)"
         FullName = "$($AlgoPools.$_.Mining)"
         Port = 4048
         API = "cpulog"
         Wrap = $false
         URI = $Uri
         BUILD = $Build
         PoolType = "AlgoPools"
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
       DeviceCall = "cryptozeny"
       Arguments = "-a $(Get-AMD($CoinPools.$_.Algorithm)) -o stratum+tcp://$($CoinPools.$_.Host):$($CoinPools.$_.Port) -b 0.0.0.0:4048 -u $($CoinPools.$_.CPUser) -p $($CoinPools.$_.CPUPass) $($Commands.$($CoinPools.$_.Algorithm))"
       HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_HashRate".Day}
       API = "cpulog"
       Selected = [PSCustomObject]@{$($CoinPools.$_.Algorithm) = ""}
       FullName = "$($CoinPools.$_.Mining)"
       MinerPool = "$($CoinPools.$_.Name)"
       Port = 4048
       Wrap = $false
       URI = $Uri
       BUILD = $Build
       PoolType = "CoinPools"
       Algo = "$($CoinPools.$_.Algorithm)"
       }
      }
     }
