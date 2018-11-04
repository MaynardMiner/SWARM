##Miner Path Information
$Path = "$($amd.xmrstak.path1)"
$Uri = "$($amd.xmrstak.uri)"
$MinerName = "$($amd.xmrstak.minername)"
$Build = "Tar"
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$ConfigType = "AMD1"

##Get Configuration File
$GetConfig = "$dir\config\miners\xmr-stak.json"
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
    DeviceCall = "xmrstak"
    Arguments = "--currency $($Config.$ConfigType.naming.$_) -i 60049 --url stratum+tcp://$($AlgoPools.$_.Host):$($AlgoPools.$_.Port) --user $($AlgoPools.$_.User1) --pass $($AlgoPools.$_.Pass1)$($Diff) --rigid SWARM --noCPU --noNVIDIA --use-nicehash $($Config.$ConfigType.commands.$_)"
    HashRates = [PSCustomObject]@{$_ = $($Stats."$($Name)_$($_)_hashrate".Day)}
    Quote = if($($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)){$($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)*($_.Price)}else{0}
    PowerX = [PSCustomObject]@{$_ = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($_)_Power".Day)}elseif($Watts.$($_)."$($ConfigType)_Watts"){$Watts.$($_)."$($ConfigType)_Watts"}elseif($Watts.default."$($ConfigType)_Watts"){$Watts.default."$($ConfigType)_Watts"}else{0}}
    ocdmp = if($Config.$ConfigType.oc.$_.dpm){$Config.$ConfigType.oc.$_.dpm}else{$OC."default_$($ConfigType)".dpm}
    ocv = if($Config.$ConfigType.oc.$_.v){$Config.$ConfigType.oc.$_.v}else{$OC."default_$($ConfigType)".v}
    occore = if($Config.$ConfigType.oc.$_.core){$Config.$ConfigType.oc.$_.dpm}else{$OC."default_$($ConfigType)".core}
    ocmem = if($Config.$ConfigType.oc.$_.mem){$Config.$ConfigType.oc.$_.mem}else{$OC."default_$($ConfigType)".memory}
    ocmdmp = if($Config.$ConfigType.oc.$_.mdpm){$Config.$ConfigType.oc.$_.mdpm}else{$OC."default_$($ConfigType)".mdpm}
    FullName = "$($AlgoPools.$_.Mining)"
    MinerPool = "$($AlgoPools.$_.Name)"
    Port = 60049
    API = "xmrstak"
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
  Where {$($Config.$ConfigType.commands.$($CoinPools.$_.Algorithm)) -NE $null} |
  foreach {
  if($Config.$ConfigType.difficulty.$($CoinPools.$_.Algorithm)){$Diff=",d=$($Difficulty.$($CoinPools.$_.Algorithm))"}
   [PSCustomObject]@{
   Symbol = "$($CoinPools.$_.Symbol)"
   MinerName = $MinerName
   Prestart = $PreStart
   Type = $ConfigType
   Path = $Path
   Devices = $Devices
   DeviceCall = "xmrstak"
   Arguments = "--currency $(Get-AMD($_)) -i 60049 --url stratum+tcp://$($CoinPools.$_.Host):$($CoinPools.$_.Port) --user $($CoinPools.$_.User1) --pass $($CoinPools.$_.Pass1)$($Diff) --rigid SWARM --noCPU --noNVIDIA --use-nicehash $($Config.$ConfigType.commands.$_)"
   HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_HashRate".Day}
   API = "xmrstak"
   PowerX = [PSCustomObject]@{$_ = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($_)_Power".Day)}elseif($Watts.$($_)."$($ConfigType)_Watts"){$Watts.$($_)."$($ConfigType)_Watts"}elseif($Watts.default."$($ConfigType)_Watts"){$Watts.default."$($ConfigType)_Watts"}else{0}}
   ocdmp = if($Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).dpm){$Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).dpm}else{$OC."default_$($ConfigType)".dpm}
   ocv = if($Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).v){$Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).v}else{$OC."default_$($ConfigType)".v}
   occore = if($Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).core){$Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).dpm}else{$OC."default_$($ConfigType)".core}
   ocmem = if($Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).mem){$Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).mem}else{$OC."default_$($ConfigType)".memory}
   ocmdmp = if($Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).mdpm){$Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).mdpm}else{$OC."default_$($ConfigType)".mdpm}
   FullName = "$($CoinPools.$_.Mining)"
   MinerPool = "$($CoinPools.$_.Name)"
   Port = 60049
   URI = $Uri
   BUILD = $Build
	 Algo = "$($CoinPools.$_.Algorithm)"
   }
  }
 }
