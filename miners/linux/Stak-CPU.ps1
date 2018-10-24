$Path = "$($cpu.xmrstak.path1)"
$Uri = "$($cpu.xmrstak.uri)"
$MinerName = "$($cpu.xmrstak.minername)"

#Max threads must be specified- XMR-STAK has no -t option

$Build = "Tar"

if($AMDDevices1 -ne ''){$Devices = $AMDDevices1}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands = [PSCustomObject]@{
"cryptonight" = ""
"cryptonightv7" = ''
"cryptonightv8" = ''
"cryptonightheavy" = ''
}

$Difficulty = [PSCustomObject]@{
"cryptonight" = ""
"cryptonightv7" = ''
"cryptonightv8" = ''
"cryptonightheavy" = ''
}
  

if($CoinAlgo -eq $null)
{
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
  if($Algorithm -eq "$($AlgoPools.$_.Algorithm)")
  {
    if($Difficulty.$_){$Diff=",d=$($Difficulty.$_)"}
    [PSCustomObject]@{
    Platform = $Platform
    Symbol = "$($_)"
    MinerName = $MinerName
    Type = "CPU"
    Path = $Path
    Devices = $Devices
    DeviceCall = "xmrstak-opt"
    Arguments = "--currency $(Get-AMD($_)) -i 60045 --url stratum+tcp://$($AlgoPools.$_.Host):$($AlgoPools.$_.Port) --user $($AlgoPools.$_.User1) --pass $($AlgoPools.$_.Pass1)$($Diff) --rigid SWARM --noAMD --noNVIDIA --use-nicehash $($Commands.$_)"
    HashRates = [PSCustomObject]@{$_ = $($Stats."$($Name)_$($_)_hashrate".Day)}
    PowerX = [PSCustomObject]@{$_ = if($($Watts.$($_).CPU_Watts)){$($Watts.$($_).CPU_Watts)}elseif($($Watts.default.CPU_Watts)){$($Watts.default.CPU_Watts)}else{0}}
    MinerPool = "$($AlgoPools.$_.Name)"
    FullName = "$($AlgoPools.$_.Mining)"
    Port = 60045
    API = "xmrstak-opt"
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
  Where {$($Commands.$($CoinPools.$_.Algorithm)) -ne $null} |
  foreach {
    if($Difficulty.$($CoinPools.$_.Algorithm)){$Diff=",d=$($Difficulty.$($CoinPools.$_.Algorithm))"}
   [PSCustomObject]@{
   Platform = $Platform
   Symbol = "$($CoinPools.$_.Symbol)"
   MinerName = $MinerName
   Type = "CPU"
   Path = $Path
   Devices = $Devices
   DeviceCall = "xmrstak-opt"
   Arguments = "--currency $(Get-AMD($_)) -i 60045 --url stratum+tcp://$($CoinPools.$_.Host):$($CoinPools.$_.Port) --user $($CoinPools.$_.User1) --pass $($CoinPools.$_.Pass1)$($Diff) --rigid SWARM --noAMD --noNVIDIA --use-nicehash $($Commands.$_)"
   HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_HashRate".Day}
   API = "xmrstak-opt"
   PowerX = [PSCustomObject]@{$CoinPools.$_.Symbol = if($Watts.$($CoinPools.$_.Algorithm).CPU_Watts){$Watts.$($CoinPools.$_.Algorithm).CPU_Watts}elseif($Watts.default.CPU_Watts){$Watts.default.CPU_Watts}else{0}}
   FullName = "$($CoinPools.$_.Mining)"
   MinerPool = "$($CoinPools.$_.Name)"
   Port = 60045
   Wrap = $false
   URI = $Uri
   BUILD = $Build
	 Algo = "$($CoinPools.$_.Algorithm)"
   }
  }
 }
