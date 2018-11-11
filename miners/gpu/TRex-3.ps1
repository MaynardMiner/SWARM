##Miner Path Information
if($nvidia.trex.path3){$Path = "$($nvidia.trex.path3)"}
else{$Path = "None"}
if($nvidia.trex.uri){$Uri = "$($nvidia.trex.uri)"}
else{$Uri = "None"}
if($nvidia.trex.minername){$MinerName = "$($nvidia.trex.minername)"}
else{$MinerName = "None"}
if($Platform -eq "linux"){$Build = "Tar"}
elseif($Platform -eq "windows"){$Build = "Zip"}

$ConfigType = "NVIDIA3"

##Parse -GPUDevices
if($NVIDIADevices3 -ne ''){$Devices = $NVIDIADevices3}

##Get Configuration File
$GetConfig = "$dir\config\miners\t-rex.json"
try{$Config = Get-Content $GetConfig | ConvertFrom-Json}
catch{Write-Warning "Warning: No config found at $GetConfig"}

##Export would be /path/to/[SWARMVERSION]/build/export##
$ExportDir = Join-Path $dir "build\export"

##Prestart actions before miner launch
$Prestart = @()
$PreStart += "export LD_LIBRARY_PATH=$ExportDir"
$Config.$ConfigType.prestart | foreach {$Prestart += "$($_)"}

##Build Miner Settings
if($CoinAlgo -eq $null)
{
  $Config.$ConfigType.commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
  $MinerAlgo = $_
  $AlgoPools | Where Symbol -eq $MinerAlgo | foreach {
  if($Algorithm -eq "$($_.Algorithm)")
  {
  if($Config.$ConfigType.difficulty.$($_.Algorithm)){$Diff=",d=$($Config.$ConfigType.difficulty.$($_.Algorithm))"}
  [PSCustomObject]@{
    Delay = $Config.$ConfigType.delay
    Symbol = "$($_.Algorithm)"
      MinerName = $MinerName
      Prestart = $PreStart
      Type = $ConfigType
      Path = $Path
      Devices = $Devices
      DeviceCall = "trex"
      Arguments = "-a $($Config.$ConfigType.naming.$($_.Algorithm)) -o stratum+tcp://$($_.Host):$($_.Port) --api-bind-telnet 0.0.0.0:4070 --api-bind-http 0.0.0.0:4073 -u $($_.User3) -p $($_.Pass3)$($Diff) $($Config.$ConfigType.commands.$($_.Algorithm))"
      HashRates = [PSCustomObject]@{$($_.Algorithm) = $($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)}
      Quote = if($($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)){$($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)*($_.Price)}else{0}
      PowerX = [PSCustomObject]@{$($_.Algorithm) = if($Watts.$($_.Algorithm)."$($ConfigType)_Watts"){$Watts.$($_.Algorithm)."$($ConfigType)_Watts"}elseif($Watts.default."$($ConfigType)_Watts"){$Watts.default."$($ConfigType)_Watts"}else{0}}
      ocpower = if($Config.$ConfigType.oc.$($_.Algorithm).power){$Config.$ConfigType.oc.$($_.Algorithm).power}else{$OC."default_$($ConfigType)".Power}
      occore = if($Config.$ConfigType.oc.$($_.Algorithm).core){$Config.$ConfigType.oc.$($_.Algorithm).core}else{$OC."default_$($ConfigType)".core}
      ocmem = if($Config.$ConfigType.oc.$($_.Algorithm).memory){$Config.$ConfigType.oc.$($_.Algorithm).memory}else{$OC."default_$($ConfigType)".memory}
      MinerPool = "$($_.Name)"
      FullName = "$($_.Mining)"
      Port = 4073
      API = "trex"
      URI = $Uri
      BUILD = $Build
      Algo = "$($_.Algorithm)"
     }
    }
   }
  }
 }