##Miner Path Information
$Path = "$($nvidia.dstm.path2)"
$Uri = "$($nvidia.dstm.uri)"
$MinerName = "$($nvidia.dstm.minername)"
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
$GetConfig = "$dir\config\miners\dstm.json"
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
 DeviceCall = "dstm"
 Arguments = "--server $($AlgoPools.$_.Host) --port $($AlgoPools.$_.Port) --user $($AlgoPools.$_.User2) --pass $($AlgoPools.$_.Pass2)$($Diff) --telemetry=0.0.0.0:43001 $($Config.$ConfigType.commands.$_)"
 HashRates = [PSCustomObject]@{$_ = $($Stats."$($Name)_$($_)_hashrate".Day)}
 PowerX = [PSCustomObject]@{$_ = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($_)_Power".Day)}elseif($Watts.$($_)."$($ConfigType)_Watts"){$Watts.$($_)."$($ConfigType)_Watts"}elseif($Watts.default."$($ConfigType)_Watts"){$Watts.default."$($ConfigType)_Watts"}else{0}}
 ocpower = if($Config.$ConfigType.oc.power.$_){$Config.$ConfigType.oc.power.$_}else{$OC."default_$($ConfigType)".Power}
 occore = if($Config.$ConfigType.oc.core.$_){$Config.$ConfigType.oc.power.$_}else{$OC."default_$($ConfigType)".core}
 ocmem = if($Config.$ConfigType.oc.memory.$_){$Config.$ConfigType.oc.power.$_}else{$OC."default_$($ConfigType)".memory}
FullName = "$($AlgoPools.$_.Mining)"
 API = "dstm"
 Port = 43001
 MinerPool = "$($AlgoPools.$_.Name)"
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
 Symbol = "$($CoinPools.$_.Symbol)"
 MinerName = $MinerName
 Prestart = $PreStart
 Type = $ConfigType
 Path = $Path
 Devices = $Devices
 DeviceCall = "dstm"
 Arguments = "--server $($CoinPools.$_.Host) --port $($CoinPools.$_.Port) --user $($CoinPools.$_.User2) --pass $($CoinPools.$_.Pass2)$($Diff) --telemetry=0.0.0.0:43001 $($Config.$ConfigType.commands.$($Coinpools.$_.Algorithm))"
 HashRates = [PSCustomObject]@{$CoinPools.$_.Symbol= $Stats."$($Name)_$($CoinPools.$_.Algorithm)_HashRate".Day}
 API = "dstm"
 PowerX = [PSCustomObject]@{$CoinPools.$_.Symbol = if($WattOMeter -eq "Yes"){$($Stats."$($Name)_$($CoinPools.$_.Algorithm)_Power".Day)}elseif($Watts.$($CoinPools.$_.Algorithm)."$($ConfigType)_Watts"){$Watts.$($CoinPools.$_.Algorithm)."$($ConfigType)_Watts"}elseif($Watts.default."$($ConfigType)_Watts"){$Watts.default."$($ConfigType)_Watts"}else{0}}
 ocpower = if($Config.$ConfigType.oc.power.$($CoinPools.$_.Algorithm)){$Config.$ConfigType.oc.power.$($CoinPools.$_.Algorithm)}else{$OC."default_$($ConfigType)".Power}
 occore = if($Config.$ConfigType.oc.core.$($CoinPools.$_.Algorithm)){$Config.$ConfigType.oc.power.$($CoinPools.$_.Algorithm)}else{$OC."default_$($ConfigType)".core}
 ocmem = if($Config.$ConfigType.oc.memory.$($CoinPools.$_.Algorithm)){$Config.$ConfigType.oc.power.$($CoinPools.$_.Algorithm)}else{$OC."default_$($ConfigType)".memory}
 FullName = "$($CoinPools.$_.Mining)"
 MinerPool = "$($CoinPools.$_.Name)"
 Port = 43001
 URI = $Uri
 BUILD = $Build
 Algo = "$($CoinPools.$_.Algorithm)"
      }
    }
  }
        
  