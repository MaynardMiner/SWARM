##Miner Path Information
$Path = "$($cpu.jayddee.path1)"
$Uri = "$($cpu.jayddee.uri)"
$MinerName = "$($cpu.jayddee.minername)"
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName
$Build = "Linux"

$ConfigType = "CPU"

##Parse -CPUDevices
if($CPUThreads -ne ''){$Devices = $CPUThreads}

##Get Configuration File
$GetConfig = "$dir\config\miners\jayddee.json"
try{$Config = Get-Content $GetConfig | ConvertFrom-Json}
catch{Write-Warning "Warning: No config found at $GetConfig"}

##Export would be /path/to/[SWARMVERSION]/build/export##
$ExportDir = Join-Path $dir "build\export"

##Prestart actions before miner launch
$Prestart = @()
$PreStart += "export LD_LIBRARY_PATH=`$LD_LIBRARY_PATH:$ExportDir"
$Config.$ConfigType.prestart | foreach {$Prestart += "$($_)"}

if($CoinAlgo -eq $null)
{
$Config.$ConfigType.commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
if($Algorithm -eq "$($AlgoPools.$_.Algorithm)")
 {
 if($Config.$ConfigType.difficulty.$_){$Diff=",d=$($Difficulty.$_)"}
 [PSCustomObject]@{
 Symbol = "$($_)"
 MinerName = $MinerName
 Prestart = $PreStart
 Type = $ConfigType
 Path = $Path
 Devices = $Devices
 DeviceCall = "cpuminer-opt"
 Arguments = "-a $_ -o stratum+tcp://$($AlgoPools.$_.Host):$($AlgoPools.$_.Port) -b 0.0.0.0:4048 -u $($AlgoPools.$_.User1) -p $($AlgoPools.$_.Pass1)$($Diff) $($Config.$ConfigType.commands.$_)"
 HashRates = [PSCustomObject]@{$_ = $($Stats."$($Name)_$($_)_hashrate".Day)}
 PowerX = [PSCustomObject]@{$_ = if($($Watts.$($_)."$($ConfigType)_Watts")){$($Watts.$($_)."$($ConfigType)_Watts")}elseif($($Watts.default."$($ConfigType)_Watts")){$($Watts.default."$($ConfigType)_Watts")}else{0}}
 MinerPool = "$($AlgoPools.$_.Name)"
 FullName = "$($AlgoPools.$_.Mining)"
 Port = 4048
 API = "cpuminer"
 URI = $Uri
 BUILD = $Build
 Algo = "$($_)"
   }
  }
 }
}
else{
$CoinPools | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name |
Where {$($Config.$ConfigType.commands.$($CoinPools.$_.Algorithm)) -NE $null} |
foreach {
if($Config.$ConfigType.difficulty.$($CoinPools.$_.Algorithm)){$Diff=",d=$($Difficulty.$($CoinPools.$_.Algorithm))"}
 [PSCustomObject]@{
 Platform = $Platform
 Symbol = "$($CoinPools.$_.Symbol)"
 MinerName = $MinerName
 Prestart = $PreStart
 Type = $ConfigType
 Path = $Path
 Devices = $Devices
 DeviceCall = "cpuminer-opt"
 Arguments = "-a $($CoinPools.$_.Algorithm) -o stratum+tcp://$($CoinPools.$_.Host):$($CoinPools.$_.Port) -b 0.0.0.0:4048 -u $($CoinPools.$_.User1) -p $($CoinPools.$_.Pass1)$($Diff) $($Config.$ConfigType.commands.$($CoinPools.$_.Algorithm))"
 HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_hashrate".Day}
 API = "cpuminer"
 PowerX = [PSCustomObject]@{$CoinPools.$_.Symbol = if($Watts.$($CoinPools.$_.Algorithm)."$($ConfigType)_Watts"){$Watts.$($CoinPools.$_.Algorithm)."$($ConfigType)_Watts"}elseif($Watts.default."$($ConfigType)_Watts"){$Watts.default."$($ConfigType)_Watts"}else{0}}
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