##Miner Path Information
$Path = "$($nvidia.cryptodredge.path1)"
$Uri = "$($nvidia.cryptodredge.uri)"
$MinerName = "$($nvidia.cryptodredge.minername)"
$Build = "Tar"
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$ConfigType = "NVIDIA1"

##Parse -GPUDevices
if($NVIDIADevices1 -ne ''){$Devices = $NVIDIADevices1}

##Get Configuration File
$GetConfig = "$dir\config\miners\cryptodredge.json"
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
  Platform = $Platform
  Symbol = "$($_)"
  MinerName = $MinerName
  Prestart = $PreStart
  Type = $ConfigType
  Path = $Path
  Devices = $Devices
  DeviceCall = "ccminer"
  Arguments = "-a $(Get-Nvidia($_)) -o stratum+tcp://$($AlgoPools.$_.Host):$($AlgoPools.$_.Port) -b 0.0.0.0:4068 -u $($AlgoPools.$_.User1) -p $($AlgoPools.$_.Pass1)$($Diff) $($Config.$ConfigType.commands.$_)"
  HashRates = [PSCustomObject]@{$_ = $($Stats."$($Name)_$($_)_hashrate".Day)}
  PowerX = [PSCustomObject]@{$_ = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($_)_Power".Day)}elseif($Watts.$($_)."$($ConfigType)_Watts"){$Watts.$($_)."$($ConfigType)_Watts"}elseif($Watts.default."$($ConfigType)_Watts"){$Watts.default."$($ConfigType)_Watts"}else{0}}
  ocpower = if($Config.$ConfigType.oc.$_.power){$Config.$ConfigType.oc.$_.power}else{$OC."default_$($ConfigType)".Power}
  occore = if($Config.$ConfigType.oc.$_.core){$Config.$ConfigType.oc.$_.core}else{$OC."default_$($ConfigType)".core}
  ocmem = if($Config.$ConfigType.oc.$_.memory){$Config.$ConfigType.oc.$_.memory}else{$OC."default_$($ConfigType)".memory}
  MinerPool = "$($AlgoPools.$_.Name)"
  FullName = "$($AlgoPools.$_.Mining)"
  Port = 4068
  API = "Ccminer"
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
Where {$($Config.$ConfigType.commands.$($CoinPools.$_.Algorithm)) -NE $null} |
 foreach {
 if($Config.$ConfigType.difficulty.$_.$($CoinPools.$_.Algorithm)){$Diff=",d=$($Difficulty.$($CoinPools.$_.Algorithm))"}
 [PSCustomObject]@{
 Platform = $Platform
 Symbol = "$($CoinPools.$_.Symbol)"
 MinerName = $MinerName
 Prestart = $PreStart
 Type = $ConfigType
 Path = $Path
 Devices = $Devices
 DeviceCall = "ccminer"
 Arguments = "-a $(Get-Algorithm($CoinPools.$_.Algorithm)) -o stratum+tcp://$($CoinPools.$_.Host):$($CoinPools.$_.Port) -b 0.0.0.0:4068 -u $($CoinPools.$_.User1) -p $($CoinPools.$_.Pass1)$($Diff) $($Config.$ConfigType.commands.$($Coinpools.$_.Algorithm))"
 HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol = $($Stats."$($Name)_$($CoinPools.$_.Algorithm)_hashrate".Day)}
 PowerX = [PSCustomObject]@{$CoinPools.$_.Symbol = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($CoinPools.$_.Algorithm)_Power".Day)}elseif($Watts.$($CoinPools.$_.Algorithm)."$($ConfigType)_Watts"){$Watts.$($CoinPools.$_.Algorithm)."$($ConfigType)_Watts"}elseif($Watts.default."$($ConfigType)_Watts"){$Watts.default."$($ConfigType)_Watts"}else{0}}
 ocpower = if($Config.$ConfigType.oc.power.$($CoinPools.$_.Algorithm)){$Config.$ConfigType.oc.power.$($CoinPools.$_.Algorithm)}else{$OC."default_$($ConfigType)".Power}
 occore = if($Config.$ConfigType.oc.core.$($CoinPools.$_.Algorithm)){$Config.$ConfigType.oc.power.$($CoinPools.$_.Algorithm)}else{$OC."default_$($ConfigType)".core}
 ocmem = if($Config.$ConfigType.oc.memory.$($CoinPools.$_.Algorithm)){$Config.$ConfigType.oc.power.$($CoinPools.$_.Algorithm)}else{$OC."default_$($ConfigType)".memory}
 API = "Ccminer"
 FullName = "$($CoinPools.$_.Mining)"
 MinerPool = "$($CoinPools.$_.Name)"
 Port = 4068
 Wrap = $false
 URI = $Uri
 BUILD = $Build
 Algo = "$($CoinPools.$_.Algorithm)"
  }
 }
}
