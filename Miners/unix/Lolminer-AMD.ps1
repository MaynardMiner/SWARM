$Path = "$($amd.lolminer.path1)"
$Uri = "$($amd.lolminer.uri)"
$MinerName = "$($amd.lolminer.minername)"

$Build = "Tar"

if($SGDevices1 -ne ''){$Devices = $SGDevices1}
if($GPUDevices1 -ne ''){$Devices = $GPUDevices1}

#Equihash192

$MinerType = "AMD1"

$Commands = [PSCustomObject]@{
  "equihash-btg" = [PSCustomObject]@{
   coin="BTG"
   disable_memcheck=0
   }
  "equihash192" = [PSCustomObject]@{
    coin="ZER"
    disable_memcheck=0
    }
  "equihash96" = [PSCustomObject]@{
    coin="MNX"
    disable_memcheck=0
    }
  }

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

if($CoinAlgo -eq $null)
{
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
 if($Type -eq $MinerType)
  {
  if($Algorithm -eq "$($AlgoPools.$_.Algorithm)")
   {
  $JsonConfig = [PSCustomObject]@{
   miner=[PSCustomObject]@{
   APIPORT=4037
   SHORTSTATS=10
   LONGSTATS=120
   COIN="$($Commands.$_.coin)"
   POOL="$($AlgoPools.$_.Host)"
   PORT="$($AlgoPools.$_.Port)"
   USER="$($AlgoPools.$_.User1)"
   PASS="$($AlgoPools.$_.Pass1)"
   DISABLE_MEMCHECK="$($Commands.$_.disable_memcheck)"
   DIGITS=2
    }
   }
   if(Test-Path (Split-Path $Path))
    {
     $JsonConfig | ConvertTo-Json | Set-Content (Join-Path (Split-Path $Path) "$_.json")
    }
  }
 }
}
}
else{
  $CoinPools | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name |
  Where {$($Commands.$($CoinPools.$_.Algorithm)) -NE $null} |
  foreach {
    if($Type -eq $MinerType)
    {
      $JsonConfig = [PSCustomObject]@{
        miner=[PSCustomObject]@{
        APIPORT=4037
        SHORTSTATS=10
        LONGSTATS=120
        COIN="$($Commands.$($CoinPools.$_.Algorithm).coin)"
        POOL="$($CoinPools.$_.Host)"
        PORT="$($CoinPools.$_.Port)"
        USER="$($CoinPools.$_.User1)"
        PASS="$($CoinPools.$_.Pass1)"
        DISABLE_MEMCHECK="$($Commands.$($CoinPools.$_.Algorithm).disable_memcheck)"
        DIGITS=2
         }
        }
        $JsonConfig | ConvertTo-Json | Set-Content (Join-Path (Split-Path $Path) "$($CoinPools.$_.Symbol).json")
       }
      }
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
      Type = $MinerType
      Path = $Path
      Devices = $Devices
      DeviceCall = "lolamd"
      Config = "$_.json"
      Arguments = "-APIPORT=4068 -pool=$($AlgoPools.$_.Host) -port=$($AlgoPools.$_.Port) -user=$($AlgoPools.$_.User1) -pass=$($AlgoPools.$_.Pass1)"
      HashRates = [PSCustomObject]@{$_ = $Stats."$($Name)_$($_)_HashRate".Day}
      Selected = [PSCustomObject]@{$_ = ""}
      MinerPool = "$($AlgoPools.$_.Name)"
      FullName = "$($AlgoPools.$_.Mining)"
      API = "lolminer"
      Port = 4037
      Wrap = $false
      URI = $Uri
      BUILD = $Build
      Algo = "$($_)"
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
          Symbol = "$($Coinpools.$_.Symbol)"
          MinerName = $MinerName
          Type = $MinerType
           Path = $Path
           Devices = $Devices
           DeviceCall = "lolamd"
           Config = "$($CoinPools.$_.Symbol).json"
           Arguments = "-APIPORT=4068 -pool=$($CoinPools.$_.Host) -port=$($CoinPools.$_.Port) -user=$($CoinPools.$_.User1) -pass=$($CoinPools.$_.Pass1)"
           HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_HashRate".Day}
           Selected = [PSCustomObject]@{$CoinPools.$_.Algorithm = ""}
           FullName = "$($CoinPools.$_.Mining)"
           API = "lolminer"
           MinerPool = "$($CoinPools.$_.Name)"
           Port = 4037
           Wrap = $false
           URI = $Uri
           BUILD = $Build
           Algo = "$($CoinPools.$_.Algorithm)"
           }
          }
         }
