if($amd.lolminer.path1){$Path = "$($amd.lolminer.path1)"}
else{$Path = "None"}
if($amd.lolminer.uri){$Uri = "$($amd.lolminer.uri)"}
else{$Uri = "None"}
if($amd.lolminer.minername){$MinerName = "$($amd.lolminer.minername)"}
else{$MinerName = "None"}
if($Platform -eq "linux"){$Build = "Tar"}
elseif($Platform -eq "windows"){$Build = "Zip"}

$Build = "Tar"

if($AMDDevices1 -ne ''){$Devices = $AMDDevices1}

$MinerType = "AMD1"

##Export would be /path/to/[SWARMVERSION]/build/export##
$ExportDir = Join-Path $dir "build\export"

##Prestart actions before miner launch
$PreStart = @(
"export LD_LIBRARY_PATH=`$LD_LIBRARY_PATH:$ExportDir"
"export GPU_MAX_HEAP_SIZE=100",
"export GPU_USE_SYNC_OBJECTS=1",
"export GPU_SINGLE_ALLOC_PERCENT=100",
"export GPU_MAX_ALLOC_PERCENT=100"
)

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

$Difficulty = [PSCustomObject]@{
"equihash-btg" =''
"equihash192" = ''
"equihash96" = ''
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
        DISABLE_MEMCHECK="$($Commands.$_.disable_memcheck)"
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
    if($Difficulty.$_){$Diff=",d=$($Difficulty.$_)"}
      [PSCustomObject]@{
      Delay = $Config.$ConfigType.delay
      Symbol = "$($_.Algorithm)"
      MinerName = $MinerName
      Prestart = $PreStart  
      Type = $MinerType
      Path = $Path
      Devices = $Devices
      DeviceCall = "lolamd"
      Config = "$_.json"
      Arguments = "-APIPORT=4068 -pool=$($_.Host) -port=$($_.Port) -user=$($_.User1)$($Diff) -pass=$($_.Pass1)"
      HashRates = [PSCustomObject]@{$($_.Algorithm) = $($Stats."$($Name)_$($_)_hashrate".Day)}
      PowerX = [PSCustomObject]@{$_ = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($_)_Power".Day)}elseif($Watts.$($_).AMD1_Watts){$Watts.$($_).AMD1_Watts}elseif($Watts.default.AMD1_Watts){$Watts.default.AMD1_Watts}else{0}}
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
          if($Difficulty.$($CoinPools.$_.Algorithm)){$Diff=",d=$($Difficulty.$($CoinPools.$_.Algorithm))"}
          [PSCustomObject]@{
          Platform = $Platform
          Symbol = "$($Coinpools.$_.Symbol)"
          MinerName = $MinerName
          Prestart = $PreStart
          Type = $MinerType
           Path = $Path
           Devices = $Devices
           DeviceCall = "lolamd"
           Config = "$($CoinPools.$_.Symbol).json"
           Arguments = "-APIPORT=4068 -pool=$($CoinPools.$_.Host) -port=$($CoinPools.$_.Port) -user=$($CoinPools.$_.User1)$($Diff) -pass=$($CoinPools.$_.Pass1)"
           HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_HashRate".Day}
           PowerX = [PSCustomObject]@{$CoinPools.$_.Symbol = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($CoinPools.$_.Algorithm)_Power".Day)}elseif($Watts.$($CoinPools.$_.Algorithm).AMD1_Watts){$Watts.$($CoinPools.$_.Algorithm).AMD1_Watts}elseif($Watts.default.AMD1_Watts){$Watts.default.AMD1_Watts}else{0}}
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