##Miner Path Information
$Path = "$($nvidia.phoenix.path1)"
$Uri = "$($nvidia.phoenix.uri)"
$MinerName = "$($nvidia.phoenix.minername)"
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName
$Build = "Tar"

$ConfigType = "NVIDIA1"

##Parse -GPUDevices
if($NVIDIADevices1 -ne ''){
$ClayDevices1  = $NVIDIADevices1 -split ","
$ClayDevices1  = Switch($ClayDevices1){"10"{"a"};"11"{"b"};"12"{"c"};"13"{"d"};"14"{"e"};"15"{"f"};"16"{"g"};"17"{"h"};"18"{"i"};"19"{"j"};"20"{"k"};default{"$_"};}
$ClayDevices1  = $ClayDevices1 | foreach {$_ -replace ("$($_)",",$($_)")}
$ClayDevices1  = $ClayDevices1 -join ""
$ClayDevices1  = $ClayDevices1.TrimStart(" ",",")  
$ClayDevices1 = $ClayDevices1 -replace(",","")
$Devices = $ClayDevices1}

##Get Configuration File
$GetConfig = "$dir\config\miners\phoenix.json"
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
  Symbol = "$($_.Algorithm)"
  MinerName = $MinerName
  Prestart = $PreStart
  Type = $ConfigType
  Path = $Path
  Devices = $Devices
  DeviceCall = "claymore"
  Arguments = "-platform 2 -mport 3333 -mode 1 -allcoins 1 -allpools 1 -epool $($_.Protocol)://$($_.Host):$($_.Port) -ewal $($_.User1) -epsw $($_.Pass1)$($Diff) -wd 0 -dbg -1 -eres 1 $($Config.$ConfigType.commands.$($_.Algorithm))"
  HashRates = [PSCustomObject]@{$($_.Algorithm) = $($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)}
  Quote = if($($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)){$($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)*($_.Price)}else{0}
  PowerX = [PSCustomObject]@{$($_.Algorithm) = if($Watts.$($_.Algorithm)."$($ConfigType)_Watts"){$Watts.$($_.Algorithm)."$($ConfigType)_Watts"}elseif($Watts.default."$($ConfigType)_Watts"){$Watts.default."$($ConfigType)_Watts"}else{0}}
  ocpower = if($Config.$ConfigType.oc.$($_.Algorithm).power){$Config.$ConfigType.oc.$($_.Algorithm).power}else{$OC."default_$($ConfigType)".Power}
  occore = if($Config.$ConfigType.oc.$($_.Algorithm).core){$Config.$ConfigType.oc.$($_.Algorithm).core}else{$OC."default_$($ConfigType)".core}
  ocmem = if($Config.$ConfigType.oc.$($_.Algorithm).memory){$Config.$ConfigType.oc.$($_.Algorithm).memory}else{$OC."default_$($ConfigType)".memory}
  ethpill = $Config.$ConfigType.oc.$($_.Algorithm).ethpill
  pilldelay = $Config.$ConfigType.oc.$($_.Algorithm).pilldelay
  FullName = "$($_.Mining)"
  API = "ethminer"
  Port = 3333
  MinerPool = "$($_.Name)"
  URI = $Uri
  BUILD = $Build
  Algo = "$($_.Algorithm)"
      }
    }
  }
 }
}