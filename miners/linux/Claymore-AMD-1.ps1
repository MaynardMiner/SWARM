##Miner Path Information
$Path = "$($amd.claymore_amd.path1)"
$Uri = "$($amd.claymore_amd.uri)"
$MinerName = "$($amd.claymore_amd.minername)"
$Build = "Tar"
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$ConfigType = "AMD1"

##Parse -GPUDevices
if($AMDDevices1 -ne ''){
$ClayDevices1  = $AMDDevices1 -split ","
$ClayDevices1  = Switch($ClayDevices1){"10"{"a"};"11"{"b"};"12"{"c"};"13"{"d"};"14"{"e"};"15"{"f"};"16"{"g"};"17"{"h"};"18"{"i"};"19"{"j"};"20"{"k"};default{"$_"};}
$ClayDevices1  = $ClayDevices1 | foreach {$_ -replace ("$($_)",",$($_)")}
$ClayDevices1  = $ClayDevices1 -join ""
$ClayDevices1  = $ClayDevices1.TrimStart(" ",",")  
$ClayDevices1 = $ClayDevices1 -replace(",","")
$Devices = $ClayDevices1}

##Get Configuration File
$GetConfig = "$dir\config\miners\claymore_amd.json"
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
  DeviceCall = "claymore"
  Arguments = "-platform 1 -mport 3336 -mode 1 -allcoins 1 -allpools 1 -epool $($AlgoPools.$_.Protocol)://$($AlgoPools.$_.Host):$($AlgoPools.$_.Port) -ewal $($AlgoPools.$_.User1) -epsw $($AlgoPools.$_.Pass1)$($Diff) -wd 0 -dbg -1 -eres 2 $($Config.$ConfigType.commands.$_)"
  HashRates = [PSCustomObject]@{$_ = $($Stats."$($Name)_$($_)_hashrate".Day)}
  PowerX = [PSCustomObject]@{$_ = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($_)_Power".Day)}elseif($Watts.$($_)."$($ConfigType)_Watts"){$Watts.$($_)."$($ConfigType)_Watts"}elseif($Watts.default."$($ConfigType)_Watts"){$Watts.default."$($ConfigType)_Watts"}else{0}}
  ocpl = if($Config.$ConfigType.oc.$_.pl){$Config.$ConfigType.oc.$_.pl}else{$OC."default_$($ConfigType)".pl}
  ocdmp = if($Config.$ConfigType.oc.$_.dpm){$Config.$ConfigType.oc.$_.dpm}else{$OC."default_$($ConfigType)".dpm}
  ocv = if($Config.$ConfigType.oc.$_.v){$Config.$ConfigType.oc.$_.v}else{$OC."default_$($ConfigType)".v}
  occore = if($Config.$ConfigType.oc.$_.core){$Config.$ConfigType.oc.$_.dpm}else{$OC."default_$($ConfigType)".core}
  ocmem = if($Config.$ConfigType.oc.$_.mem){$Config.$ConfigType.oc.$_.mem}else{$OC."default_$($ConfigType)".memory}
  ocmdmp = if($Config.$ConfigType.oc.$_.mdpm){$Config.$ConfigType.oc.$_.mdpm}else{$OC."default_$($ConfigType)".mdpm}
FullName = "$($AlgoPools.$_.Mining)"
  API = "claymore"
  Port = 3336
  MinerPool = "$($AlgoPools.$_.Name)"
  Wrap = $false
  URI = $Uri
  BUILD = $Build
  Algo = "$($_)"
      }
    }
  }
}
else {
$CoinPools | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name |
  Where {$($Config.$ConfigType.commands.$($CoinPools.$_.Algorithm)) -NE $null} |
  foreach {
  if($Config.$ConfigType.difficulty.$($CoinPools.$_.Algorithm)){$Diff=",d=$($Difficulty.$($CoinPools.$_.Algorithm))"}
  [PSCustomObject]@{
  Coin = "Yes"
  Symbol = "$($CoinPools.$_.Symbol)"
  MinerName = $MinerName
  Prestart = $PreStart
  Type = $ConfigType
  Path = $Path
  Devices = $Devices
  DeviceCall = "claymore"
  Arguments = "-platform 1 -mport 3336 -mode 1 -allcoins 1 -allpools 1 -epool $($CoinPools.$_.Protocol)://$($CoinPools.$_.Host):$($CoinPools.$_.Port) -ewal $($CoinPools.$_.User1) -epsw $($CoinPools.$_.Pass1)$($Diff) -wd 0 -dbg -1 -eres 2 $($Config.$ConfigType.commands.$($CoinPools.$_.Algorithm))"
  HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $($Stats."$($Name)_$($CoinPools.$_.Algorithm)_hashrate".Day)}
  PowerX = [PSCustomObject]@{$_ = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($_)_Power".Day)}elseif($Watts.$($_)."$($ConfigType)_Watts"){$Watts.$($_)."$($ConfigType)_Watts"}elseif($Watts.default."$($ConfigType)_Watts"){$Watts.default."$($ConfigType)_Watts"}else{0}}
  ocpl = if($Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).pl){$Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).pl}else{$OC."default_$($ConfigType)".pl}
  ocdmp = if($Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).dpm){$Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).dpm}else{$OC."default_$($ConfigType)".dpm}
  ocv = if($Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).v){$Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).v}else{$OC."default_$($ConfigType)".v}
  occore = if($Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).core){$Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).dpm}else{$OC."default_$($ConfigType)".core}
  ocmem = if($Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).mem){$Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).mem}else{$OC."default_$($ConfigType)".memory}
  ocmdmp = if($Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).mdpm){$Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).mdpm}else{$OC."default_$($ConfigType)".mdpm}
  FullName = "$($CoinPools.$_.Mining)"
  MinerPool = "$($CoinPools.$_.Name)"
  API = "claymore"
  Port = 3336
  Wrap = $false
  URI = $Uri
  BUILD = $Build
  Algo = "$($CoinPools.$_.Algorithm)"
   }
  }
 }
        