##Miner Path Information
$Path = "$($amd.lyclminer.path1)"
$Uri = "$($amd.lyclminer.uri)"
$MinerName = "$($amd.lyclminer.minername)"
$Build = "Tar"
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$ConfigType = "AMD1"

##Parse -GPUDevices
if($AMDDevices1 -ne ''){$Devices = $AMDDevices1}

##Get Configuration File
$GetConfig = "$dir\config\miners\lyclminer.json"
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
    DeviceCall = "lyclminer"
    Connection = "$($AlgoPools.$_.Host):$($AlgoPools.$_.Port)"
    Username =  "$($AlgoPools.$_.User1)"
    Password = "$($AlgoPools.$_.Pass1)$($Diff)"
    Arguments = "stratum+tcp://$($AlgoPools.$_.Host):$($AlgoPools.$_.Port) $($AlgoPools.$_.User1) $($AlgoPools.$_.Pass1)$($Diff)"
    HashRates = [PSCustomObject]@{$_ = $($Stats."$($Name)_$($_)_hashrate".Day)}
    PowerX = [PSCustomObject]@{$_ = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($_)_Power".Day)}elseif($Watts.$($_)."$($ConfigType)_Watts"){$Watts.$($_)."$($ConfigType)_Watts"}elseif($Watts.default."$($ConfigType)_Watts"){$Watts.default."$($ConfigType)_Watts"}else{0}}
    ocdmp = if($Config.$ConfigType.oc.$_.dpm){$Config.$ConfigType.oc.$_.dpm}else{$OC."default_$($ConfigType)".dpm}
    ocv = if($Config.$ConfigType.oc.$_.v){$Config.$ConfigType.oc.$_.v}else{$OC."default_$($ConfigType)".v}
    occore = if($Config.$ConfigType.oc.$_.core){$Config.$ConfigType.oc.$_.dpm}else{$OC."default_$($ConfigType)".core}
    ocmem = if($Config.$ConfigType.oc.$_.mem){$Config.$ConfigType.oc.$_.mem}else{$OC."default_$($ConfigType)".memory}
    ocmdmp = if($Config.$ConfigType.oc.$_.mdpm){$Config.$ConfigType.oc.$_.mdpm}else{$OC."default_$($ConfigType)".mdpm}
    MinerPool = "$($AlgoPools.$_.Name)"
    FullName = "$($AlgoPools.$_.Mining)"
    Port = 0
    API = "lyclminer"
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
   Type = "AMD1"
   Path = $Path
   Devices = $Devices
   DeviceCall = "lyclminer"
   Connection = "$($CoinPools.$_.Host):$($CoinPools.$_.Port)"
   Username = "$($CoinPools.$_.User1)"
   Password = "$($CoinPools.$_.Pass1)$($Diff)"
   Arguments = "stratum+tcp://$($CoinPools.$_.Host):$($CoinPools.$_.Port) $($CoinPools.$_.User1) $($CoinPools.$_.Pass1)$($Diff)"
   HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_HashRate".Day}
   API = "lyclminer"
   PowerX = [PSCustomObject]@{$_ = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($_)_Power".Day)}elseif($Watts.$($_)."$($ConfigType)_Watts"){$Watts.$($_)."$($ConfigType)_Watts"}elseif($Watts.default."$($ConfigType)_Watts"){$Watts.default."$($ConfigType)_Watts"}else{0}}
   ocdmp = if($Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).dpm){$Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).dpm}else{$OC."default_$($ConfigType)".dpm}
   ocv = if($Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).v){$Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).v}else{$OC."default_$($ConfigType)".v}
   occore = if($Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).core){$Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).dpm}else{$OC."default_$($ConfigType)".core}
   ocmem = if($Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).mem){$Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).mem}else{$OC."default_$($ConfigType)".memory}
   ocmdmp = if($Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).mdpm){$Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).mdpm}else{$OC."default_$($ConfigType)".mdpm}
   FullName = "$($CoinPools.$_.Mining)"
   MinerPool = "$($CoinPools.$_.Name)"
   Port = 0
   Wrap = $false
   URI = $Uri
   BUILD = $Build
	 Algo = "$($CoinPools.$_.Algorithm)"
   }
  }
 }
