##Miner Path Information
$Path = "$($nvidia.ewbf.path2)"
$Uri = "$($nvidia.ewbf.uri)"
$MinerName = "$($nvidia.ewbf.minername)"
$Build = "Tar"
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$ConfigType = "NVIDIA2"

##Parse -GPUDevices
if($NVIDIADevices2 -ne ''){$GPUDevices2 = $NVIDIADevices2}
if($GPUDevices2 -ne '')
 {
  $GPUEDevices2 = $GPUDevices2 -replace ',',' '
  $Devices = $GPUEDevices2
 }

##Get Configuration File
$GetConfig = "$dir\config\miners\ewbf.json"
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
      DeviceCall = "ewbf"
      Arguments = "--api 0.0.0.0:42001 --server $($AlgoPools.$_.Host) --port $($AlgoPools.$_.Port) --user $($AlgoPools.$_.User2) --pass $($AlgoPools.$_.Pass2)$($Diff) $($Config.$ConfigType.commands.$_)"
      HashRates = [PSCustomObject]@{$_ = $($Stats."$($Name)_$($_)_hashrate".Day)}
      PowerX = [PSCustomObject]@{$_ = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($_)_Power".Day)}elseif($Watts.$($_)."$($ConfigType)_Watts"){$Watts.$($_)."$($ConfigType)_Watts"}elseif($Watts.default."$($ConfigType)_Watts"){$Watts.default."$($ConfigType)_Watts"}else{0}}
      ocpower = if($Config.$ConfigType.oc.$_.power){$Config.$ConfigType.oc.$_.power}else{$OC."default_$($ConfigType)".Power}
      occore = if($Config.$ConfigType.oc.$_.core){$Config.$ConfigType.oc.$_.core}else{$OC."default_$($ConfigType)".core}
      ocmem = if($Config.$ConfigType.oc.$_.memory){$Config.$ConfigType.oc.$_.memory}else{$OC."default_$($ConfigType)".memory}
      MinerPool = "$($AlgoPools.$_.Name)"
      FullName = "$($AlgoPools.$_.Mining)"
      API = "EWBF"
      Port = 42001
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
  if($Config.$ConfigType.difficulty.$_.$($CoinPools.$_.Algorithm)){$Diff=",d=$($Difficulty.$($CoinPools.$_.Algorithm))"}
  [PSCustomObject]@{
  Platform = $Platform
  Symbol = "$($Coinpools.$_.Symbol)"
  MinerName = $MinerName
  Prestart = $PreStart
  Type = $ConfigType
  Path = $Path
  Devices = $Devices
  DeviceCall = "ewbf"
  Arguments = "--api 0.0.0.0:42001 --server $($CoinPools.$_.Host) --port $($CoinPools.$_.Port) --user $($CoinPools.$_.User2) --pass $($CoinPools.$_.Pass2)$($Diff) $($Config.$ConfigType.commands.$($Coinpools.$_.Algorithm))"
  HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_HashRate".Day}
  PowerX = [PSCustomObject]@{$CoinPools.$_.Symbol = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($CoinPools.$_.Algorithm)_Power".Day)}elseif($Watts.$($CoinPools.$_.Algorithm)."$($ConfigType)_Watts"){$Watts.$($CoinPools.$_.Algorithm)."$($ConfigType)_Watts"}elseif($Watts.default."$($ConfigType)_Watts"){$Watts.default."$($ConfigType)_Watts"}else{0}}
  ocpower = if($Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).power){$Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).power}else{$OC."default_$($ConfigType)".Power}
  occore = if($Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).core){$Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).core}else{$OC."default_$($ConfigType)".core}
  ocmem = if($Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).memory){$Config.$ConfigType.oc.$($CoinPools.$_.Algorithm).memory}else{$OC."default_$($ConfigType)".memory}
  FullName = "$($CoinPools.$_.Mining)"
  API = "EWBF"
  MinerPool = "$($CoinPools.$_.Name)"
  Port = 42001
  URI = $Uri
  BUILD = $Build
  Algo = "$($CoinPools.$_.Algorithm)"
    }
   }
  }