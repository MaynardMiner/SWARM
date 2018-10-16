$Path = "$($cpu.bubasik.path1)"
$Uri = "$($cpu.bubasik.uri)"
$MinerName = "$($cpu.bubasik.minername)"

if($CPUThreads -ne ''){$Devices = $CPUThreads}

$Build = "Zip"

$Commands = [PSCustomObject]@{
"yespower" = ''
"argon2d-dyn" = ""
#"hodl" = ''
}
        
$Difficulty = [PSCustomObject]@{
"yespower" = ''
"argon2d-dyn" = ""
#"hodl" = ''
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

if($CoinAlgo -eq $null)
{
 $Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
 if($Algorithm -eq "$($AlgoPools.$_.Algorithm)")
 {
  if($Difficulty.$_){$Diff=",d=$($Difficulty.$_)"}
  [PSCustomObject]@{
  platform = $platform
  Symbol = "$($_)"
  MinerName = $MinerName
  Type = "CPU"
  Path = $Path
  Devices = $Devices
  DeviceCall = "cpuminer-opt"
  Arguments = "-a $_ $($MinerIntensity)-o stratum+tcp://$($AlgoPools.$_.Host):$($AlgoPools.$_.Port) -b 0.0.0.0:4048 -u $($AlgoPools.$_.CPUser) -p $($AlgoPools.$_.CPUPass)$($Diff) $($Commands.$_)"
  HashRates = [PSCustomObject]@{$_ = $($Stats."$($Name)_$($_)_hashrate".Day)}
  PowerX = [PSCustomObject]@{$_ = if($Watts.$($_).CPU_Watts){$Watts.$($_).CPU_Watts}elseif($Watts.default.CPU_Watts){$Watts.default.CPU_Watts}else{0}}
  MinerPool = "$($AlgoPools.$_.Name)"
  FullName = "$($AlgoPools.$_.Mining)"
  Port = 4048
  API = "Ccminer"
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
        if($Difficulty.$($CoinPools.$_.Algorithm)){$Diff=",d=$($Difficulty.$($CoinPools.$_.Algorithm))"}
        [PSCustomObject]@{
    platform = $platform
    Symbol = "$($CoinPools.$_.Symbol)"
    MinerName = $MinerName
    Type = "CPU"
    Path = $Path
    Devices = $Devices
    DeviceCall = "cpuminer-opt"
    Arguments = "-a $($CoinPools.$_.Algorithm) -o stratum+tcp://$($CoinPools.$_.Host):$($CoinPools.$_.Port) -b 0.0.0.0:4048 -u $($CoinPools.$_.CPUser) -p $($CoinPools.$_.CPUPass)$($Diff) $($Commands.$($CoinPools.$_.Algorithm))"
    HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $($Stats."$($Name)_$($CoinPools.$_.Algorithm)_hashrate".Day)}
    PowerX = [PSCustomObject]@{$CoinPools.$_.Symbol = if($Watts.$($CoinPools.$_.Algorithm).CPU_Watts){$Watts.$($CoinPools.$_.Algorithm).CPU_Watts}elseif($Watts.default.CPU_Watts){$Watts.default.CPU_Watts}else{0}}
    API = "Ccminer"
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