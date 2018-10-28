##Miner Path Information
$Path = "$($amd.wildrig.path1)"
$Uri = "$($amd.wildrig.uri)"
$MinerName = "$($amd.wildrig.minername)"
$Build = "Tar"
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$ConfigType = "AMD1"

##Get Configuration File
$GetConfig = "$dir\config\miners\wildrig.json"
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
    DeviceCall = "wildrig"
    Arguments = "--opencl-platform=$AMDPlatform --api-port 60050 --algo $(Get-AMD($_)) --url stratum+tcp://$($AlgoPools.$_.Host):$($AlgoPools.$_.Port) --user $($AlgoPools.$_.User1) --pass $($AlgoPools.$_.Pass1)$($Diff) $($Config.$ConfigType.commands.$_)"
    HashRates = [PSCustomObject]@{$_ = $($Stats."$($Name)_$($_)_hashrate".Day)}
    PowerX = [PSCustomObject]@{$_ = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($_)_Power".Day)}elseif($Watts.$($_)."$($ConfigType)_Watts"){$Watts.$($_)."$($ConfigType)_Watts"}elseif($Watts.default."$($ConfigType)_Watts"){$Watts.default."$($ConfigType)_Watts"}else{0}}
    ocpl = if($Config.$ConfigType.oc.pl.$_){$Config.$ConfigType.oc.pl.$_}else{"$OC.default_$($ConfigType)".pl}
    ocdmp = if($Config.$ConfigType.oc.dpm.$_){$Config.$ConfigType.oc.dpm.$_}else{"$OC.default_$($ConfigType)".dpm}
    ocv = if($Config.$ConfigType.oc.v.$_){$Config.$ConfigType.oc.v.$_}else{"$OC.default_$($ConfigType)".v}
    occore = if($Config.$ConfigType.oc.core.$_){$Config.$ConfigType.oc.dpm.$_}else{"$OC.default_$($ConfigType)".core}
    ocmem = if($Config.$ConfigType.oc.mem.$_){$Config.$ConfigType.oc.mem.$_}else{"$OC.default_$($ConfigType)".memory}
    ocmdmp = if($Config.$ConfigType.oc.mdpm.$_){$Config.$ConfigType.oc.mdpm.$_}else{"$OC.default_$($ConfigType)".mdpm}
    MinerPool = "$($AlgoPools.$_.Name)"
    FullName = "$($AlgoPools.$_.Mining)"
    Port = 60050
    API = "wildrig"
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
   DeviceCall = "wildrig"
   Arguments = "--opencl-platform=$AMDPlatform --api-port 60050 --algo $(Get-AMD($CoinPools.$_.Algorithm)) --url stratum+tcp://$($CoinPools.$_.Host):$($CoinPools.$_.Port) --user $($CoinPools.$_.User1) --pass $($CoinPools.$_.Pass1)$($Diff) $($Config.$ConfigType.commands.$($CoinPools.$_.Algorithm))"
   HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_HashRate".Day}
   API = "wildrig"
   PowerX = [PSCustomObject]@{$_ = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($_)_Power".Day)}elseif($Watts.$($_)."$($ConfigType)_Watts"){$Watts.$($_)."$($ConfigType)_Watts"}elseif($Watts.default."$($ConfigType)_Watts"){$Watts.default."$($ConfigType)_Watts"}else{0}}
   ocpl = if($Config.$ConfigType.oc.pl.$($CoinPools.$_.Algorithm)){$Config.$ConfigType.oc.pl.$($CoinPools.$_.Algorithm)}else{"$OC.default_$($ConfigType)".pl}
   ocdmp = if($Config.$ConfigType.oc.dpm.$($CoinPools.$_.Algorithm)){$Config.$ConfigType.oc.dpm.$($CoinPools.$_.Algorithm)}else{"$OC.default_$($ConfigType)".dpm}
   ocv = if($Config.$ConfigType.oc.v.$($CoinPools.$_.Algorithm)){$Config.$ConfigType.oc.v.$($CoinPools.$_.Algorithm)}else{"$OC.default_$($ConfigType)".v}
   occore = if($Config.$ConfigType.oc.core.$($CoinPools.$_.Algorithm)){$Config.$ConfigType.oc.dpm.$($CoinPools.$_.Algorithm)}else{"$OC.default_$($ConfigType)".core}
   ocmem = if($Config.$ConfigType.oc.mem.$($CoinPools.$_.Algorithm)){$Config.$ConfigType.oc.mem.$($CoinPools.$_.Algorithm)}else{"$OC.default_$($ConfigType)".memory}
   ocmdmp = if($Config.$ConfigType.oc.mdpm.$($CoinPools.$_.Algorithm)){$Config.$ConfigType.oc.mdpm.$($CoinPools.$_.Algorithm)}else{"$OC.default_$($ConfigType)".mdpm}
   FullName = "$($CoinPools.$_.Mining)"
   MinerPool = "$($CoinPools.$_.Name)"
   Port = 60050
   URI = $Uri
   BUILD = $Build
   Algo = "$($CoinPools.$_.Algorithm)"
   }
  }
 }